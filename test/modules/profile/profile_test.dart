import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/profile/application/profile_controller.dart';
import 'package:sabi_pipu_tms/modules/profile/data/profile_repository.dart';
import 'package:sabi_pipu_tms/modules/profile/domain/profile.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/workspace_preview.dart';

void main() {
  test('mock profile shows the reference person and keeps status', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(c.read(profileRepositoryProvider), isA<MockProfileRepository>());
    final sub = c.listen(profileProvider, (_, _) {});
    addTearDown(sub.close);
    final p = await c.read(profileProvider.future);
    expect(p.reportsTo?.name, 'Ibrahim Musa');
    expect(p.earned.length, 3);
    expect(p.streakHistory, isTrue);
    await c.read(profileProvider.notifier).setPresence(Presence.focusing);
    expect(c.read(profileProvider).requireValue.presence, Presence.focusing);
    expect(c.read(workspacePreviewProvider).status, 'profile.focusing');
  });

  test('badge keys map to the badges this app draws', () {
    expect(badgeFromKey('first_time_right_5'), Badge.firstTime);
    expect(badgeFromKey('streak_7'), Badge.weekStreak);
    expect(badgeFromKey('early_bird'), Badge.early);
    expect(badgeFromKey('zero_overdue_month'), Badge.zeroOverdue);
    expect(badgeFromKey('tasks_100'), Badge.century);
    expect(badgeFromKey('unknown'), isNull);
  });

  group('live profile', () {
    late _Transport transport;
    late ProviderContainer c;

    setUp(() {
      transport = _Transport();
      c = ProviderContainer.test(
        overrides: [
          environmentProvider.overrideWithValue(
            const AppEnvironment(source: DataSource.live),
          ),
          networkCallsRepositoryProvider.overrideWithValue(transport),
          activeLiveWorkspaceProvider.overrideWithValue(
            AccountWorkspace.fromJson({
              'id': 'ws',
              'name': 'Acme',
              'kind': 'business',
              'approval_status': 'approved',
            }),
          ),
        ],
      );
      c
          .read(accountSessionProvider.notifier)
          .update(
            const Account(
              id: 'me',
              email: 'me@example.test',
              firstName: 'Ari',
              lastName: 'Lee',
              verified: true,
            ),
          );
    });

    test('combines person, roles, gamification and my status', () async {
      final p = await c.read(profileRepositoryProvider).summary();
      expect(transport.reads, {
        '/people/get-person/ws/me/',
        '/people/my-context/ws/',
        '/gamification/get-profile/ws/me/',
        '/people/list-statuses/ws/',
      });
      expect(p.department, 'Engineering');
      expect(p.presence, Presence.focusing);
      expect(
        (p.lineManager, p.projectManager, p.teamLead),
        (true, false, true),
      );
      expect(p.reportsTo?.name, 'Bola Ade');
      expect(p.directReports.map((r) => r.name), ['Amaka Eze']);
      expect((p.directReportCount, p.team), (2, 'Tech Team'));
      expect((p.points, p.level, p.streak), (1240, 3, 12));
      expect(p.earned, {Badge.firstTime});
      expect((p.bestStreak, p.streakHistory), (null, false));
    });

    test('my status alone needs one request', () async {
      final presence = await c.read(profileRepositoryProvider).presence();
      expect(transport.reads, {'/people/list-statuses/ws/'});
      expect(presence, Presence.focusing);
    });

    test('setting a status sends the server value', () async {
      final stored = await c
          .read(profileRepositoryProvider)
          .setPresence(Presence.meeting);
      expect(transport.write?.$1, '/people/set-status/ws/');
      expect(transport.write?.$2, {'presence': 'meeting'});
      expect(stored, Presence.meeting);
    });
  });
}

class _Transport implements NetworkCallsRepository {
  final reads = <String>{};
  (String, Object?)? write;

  static const _bodies = <String, Object>{
    '/people/get-person/ws/me/': {
      'first_name': 'Ari',
      'last_name': 'Lee',
      'job_title': 'Engineer',
      'department': 'Engineering',
      'reports_to': {'id': 'u9', 'first_name': 'Bola', 'last_name': 'Ade'},
      'direct_report_count': 2,
      'teams': [
        {'id': 't', 'name': 'Tech Team'},
      ],
      'direct_reports': [
        {'id': 'u2', 'first_name': 'Amaka', 'last_name': 'Eze'},
      ],
    },
    '/people/my-context/ws/': {
      'role': 'member',
      'is_line_manager': true,
      'is_project_manager': false,
      'is_team_lead': true,
    },
    '/gamification/get-profile/ws/me/': {
      'points': 1240,
      'streak': 12,
      'level': 3,
      'badges': [
        {'key': 'first_time_right_5', 'earned': true},
        {'key': 'streak_7', 'earned': false},
      ],
    },
    '/people/list-statuses/ws/': [
      {'user_id': 'other', 'presence': 'available'},
      {'user_id': 'me', 'presence': 'dnd'},
    ],
  };

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    void Function(int, int)? onReceiveProgress,
  }) async {
    reads.add(path);
    return ApiResponse<T>.success(_bodies[path] as T);
  }

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    write = (path, data);
    return ApiResponse<T>.success(
      <String, dynamic>{'user_id': 'me', 'presence': 'meeting'} as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
