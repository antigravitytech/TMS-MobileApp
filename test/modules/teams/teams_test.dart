import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/teams/application/teams_controller.dart';
import 'package:sabi_pipu_tms/modules/teams/data/teams_repository.dart';

void main() {
  test('mock teams load without the network', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(c.read(teamsRepositoryProvider), isA<MockTeamsRepository>());
    final d = await c.read(teamsProvider.future);
    expect(d.teams.map((t) => t.name), ['Tech Team', 'Compliance']);
    final members = await c.read(teamMembersProvider(d.teams.first).future);
    expect(members.first.lead, isTrue);
    expect(members.length, d.teams.first.memberCount);
  });

  test('live teams list once; members load per opened team', () async {
    final transport = _Transport();
    final c = ProviderContainer.test(
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
    final sub = c.listen(teamsProvider, (_, _) {});
    addTearDown(sub.close);
    final d = await c.read(teamsProvider.future);
    expect(transport.reads, ['/team/list-teams/ws/']);
    expect(d.workspace, 'Acme');
    final team = d.teams.single;
    expect(
      (team.name, team.lead, team.memberCount, team.progress, team.color),
      ('Tech Team', 'Chioma Okafor', 2, 43, '#6658c0'),
    );

    final members = await c.read(teamMembersProvider(team).future);
    expect(transport.reads.last, '/team/list-members/t1/');
    expect(members.map((m) => (m.name, m.lead, m.open)), [
      ('Chioma Okafor', true, 1),
      ('Tunde Bakare', false, 3),
    ]);
  });
}

Map<String, dynamic> _user(String id, String first, String last) => {
  'id': id,
  'first_name': first,
  'last_name': last,
};

class _Transport implements NetworkCallsRepository {
  final reads = <String>[];

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
    final Object body = switch (path) {
      '/team/list-teams/ws/' => {
        'items': [
          {
            'id': 't1',
            'name': 'Tech Team',
            'color': '#6658c0',
            'lead': _user('chioma', 'Chioma', 'Okafor'),
            'member_count': 2,
            'stats': {'weekly_progress': 42.6},
          },
        ],
      },
      '/team/list-members/t1/' => {
        'items': [
          {
            'user': _user('tunde', 'Tunde', 'Bakare'),
            'role': 'member',
            'in_progress_tasks': 3,
          },
          {
            'user': _user('chioma', 'Chioma', 'Okafor'),
            'role': 'lead',
            'in_progress_tasks': 1,
          },
        ],
      },
      _ => fail('Unexpected read $path'),
    };
    return ApiResponse<T>.success(body as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
