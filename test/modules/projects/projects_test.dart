import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/projects/application/projects_controller.dart';
import 'package:sabi_pipu_tms/modules/projects/data/projects_repository.dart';
import 'package:sabi_pipu_tms/modules/projects/domain/project.dart';

void main() {
  test('working days late skip weekends', () {
    // Friday 20 Nov 2026 to Monday 23 Nov 2026 is one working day.
    final m = ProjectMilestone('Beta', DateTime(2026, 11, 20));
    expect(m.workingDaysLate(DateTime(2026, 11, 23)), 1);
    expect(m.workingDaysLate(DateTime(2026, 11, 20)), 0);
    expect(m.workingDaysLate(DateTime(2026, 11, 1)), 0);
  });

  test('mock projects list and create without the network', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(c.read(projectsRepositoryProvider), isA<MockProjectsRepository>());
    final sub = c.listen(projectsProvider, (_, _) {});
    addTearDown(sub.close);
    final projects = await c.read(projectsProvider.future);
    expect(projects.map((p) => p.name), contains('Customer Portal Revamp'));
    await c.read(projectsProvider.notifier).create(' Rebrand ');
    expect(c.read(projectsProvider).requireValue.last.name, 'Rebrand');
  });

  group('live projects', () {
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
              'name': 'Fixture',
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

    test('one list request fills every card', () async {
      final sub = c.listen(projectsProvider, (_, _) {});
      addTearDown(sub.close);
      final p = (await c.read(projectsProvider.future)).single;
      expect(transport.reads, ['/project/list-projects/ws/']);
      expect(transport.query, {'page_size': 100});
      expect(
        (p.name, p.health, p.owner),
        ('Customer Portal Revamp', ProjectHealth.atRisk, 'Chioma Okafor'),
      );
      expect((p.progress, p.accepted), (37, 80));
      expect(
        (p.milestone?.name, p.milestone?.due),
        ('Discovery', DateTime(2026, 10, 28)),
      );
      expect(p.mode, isNull);
    });

    test('a new project joins the list without reloading it', () async {
      final sub = c.listen(projectsProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(projectsProvider.future);
      transport.reads.clear();
      await c.read(projectsProvider.notifier).create(' Rebrand ');
      expect(transport.write?.$1, '/project/create-project/ws/');
      expect(transport.write?.$2, {'name': 'Rebrand'});
      expect(c.read(projectsProvider).requireValue.length, 2);
      expect(transport.reads, isEmpty);
    });

    test('a broken list is an error, never mock data', () async {
      transport.broken = true;
      final sub = c.listen(projectsProvider, (_, _) {});
      addTearDown(sub.close);
      await expectLater(
        c.read(projectsProvider.future),
        throwsA(isA<AccountFailure>()),
      );
    });
  });
}

Map<String, dynamic> _project(String id, String name) => {
  'id': id,
  'name': name,
  'health': 'at_risk',
  'owner': {'id': 'chioma', 'first_name': 'Chioma', 'last_name': 'Okafor'},
  'next_milestone': {'id': 'm1', 'name': 'Discovery', 'due_date': '2026-10-28'},
  'stats': {'progress': 36.6, 'first_time_right_rate': 80.0},
};

class _Transport implements NetworkCallsRepository {
  final reads = <String>[];
  Map<String, dynamic>? query;
  (String, Object?)? write;
  var broken = false;

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
    expect(withToken, isTrue);
    reads.add(path);
    query = queryParameters;
    return ApiResponse<T>.success(
      <String, dynamic>{
            'items': broken
                ? 'oops'
                : [_project('p1', 'Customer Portal Revamp')],
          }
          as T,
    );
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    ResponseType? responseType,
  }) async {
    write = (path, data);
    return ApiResponse<T>.success(_project('p2', 'Rebrand') as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
