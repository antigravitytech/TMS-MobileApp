import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/reports/application/reports_controller.dart';
import 'package:sabi_pipu_tms/modules/reports/data/reports_repository.dart';
import 'package:sabi_pipu_tms/modules/reports/domain/report.dart';

void main() {
  test('report fields find their role from the label', () {
    ReportRole role(String label) =>
        ReportField(id: '', label: label, type: 'long').role;
    expect(role('What did you finish today?'), ReportRole.done);
    expect(role("What's next?"), ReportRole.plan);
    expect(role('Any blockers?'), ReportRole.blockers);
    expect(role('Mood'), ReportRole.other);
  });

  test('mock reports load and send without the network', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(c.read(reportsRepositoryProvider), isA<MockReportsRepository>());
    final sub = c.listen(dailyReportProvider, (_, _) {});
    addTearDown(sub.close);
    final report = (await c.read(dailyReportProvider.future))!;
    expect(report.sent, isFalse);
    await c.read(dailyReportProvider.notifier).send({'done': 'Shipped'});
    expect(c.read(dailyReportProvider).requireValue!.sent, isTrue);
    expect((await c.read(teamReportsProvider.future))!.sent, 2);
    final perf = await c.read(
      performanceProvider((true, ReportPeriod.thisMonth)).future,
    );
    expect(perf.metric('saved_days')?.value, 2.2);
  });

  group('live reports', () {
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

    test('today\'s routine and its fields, then submit-log', () async {
      final sub = c.listen(dailyReportProvider, (_, _) {});
      addTearDown(sub.close);
      final report = (await c.read(dailyReportProvider.future))!;
      expect(transport.reads, [
        '/routine/list-my-routines/ws/',
        '/routine/get-routine/r1/',
      ]);
      expect(
        (report.title, report.dueTime, report.date, report.canLog),
        ('Daily Status Update', '17:00', '2026-11-27', true),
      );
      expect(report.fields.map((f) => f.role), [
        ReportRole.done,
        ReportRole.blockers,
      ]);

      await c.read(dailyReportProvider.notifier).send({'f1': 'Shipped it'});
      expect(transport.write?.$1, '/routine/submit-log/r1/');
      expect(transport.write?.$2, {
        'occurrence_date': '2026-11-27',
        'answers': {'f1': 'Shipped it'},
      });
      expect(c.read(dailyReportProvider).requireValue!.sent, isTrue);
    });

    test('the team joins status with summaries', () async {
      final team = (await c.read(reportsRepositoryProvider).team())!;
      expect(team.title, 'Daily Status Update');
      expect(team.people.map((p) => (p.name, p.sent, p.done, p.blockers)), [
        ('Tunde Bakare', true, 'Wrote tests', 'Sandbox keys'),
        ('Amaka Eze', false, '', ''),
      ]);
      expect((team.sent, team.blockers), (1, 1));
    });

    test('performance reads the overview for a scope and period', () async {
      final p = await c
          .read(reportsRepositoryProvider)
          .performance(team: true, period: ReportPeriod.lastMonth);
      expect(transport.queries['/report/get-overview/ws/'], {
        'scope': 'team',
        'preset': 'Last Month',
      });
      expect(p.metric('on_time_rate')?.value, 88.9);
      expect(p.weekly.single, ('01 Sep', 4, 1));
      expect(p.attention.single, ('TK-142 · Webhook', '2 returns'));
    });
  });
}

final _today = DateFormat('yyyy-MM-dd').format(DateTime.now());

class _Transport implements NetworkCallsRepository {
  final reads = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  (String, Object?)? write;

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
    queries[path] = queryParameters;
    final Object body = switch (path) {
      '/routine/list-my-routines/ws/' => [
        {
          'routine': {
            'id': 'r1',
            'title': 'Daily Status Update',
            'kind': 'report',
            'due_time': '17:00',
          },
          'current_occurrence': {
            'date': '2026-11-27',
            'can_log': true,
            'log': null,
          },
        },
      ],
      '/routine/get-routine/r1/' => {
        'fields': [
          {
            'id': 'f1',
            'label': 'What did you finish today?',
            'field_type': 'long',
            'required': true,
          },
          {'id': 'f2', 'label': 'Blockers', 'field_type': 'short'},
        ],
      },
      '/routine/team-status/ws/' => [
        {
          'routine': {'id': 'r1', 'title': 'Daily Status Update'},
          'members': [
            {
              'user': {
                'id': 'tunde',
                'first_name': 'Tunde',
                'last_name': 'Bakare',
              },
              'logged': true,
              'late': false,
            },
            {
              'user': {
                'id': 'amaka',
                'first_name': 'Amaka',
                'last_name': 'Eze',
              },
              'logged': false,
              'late': false,
            },
          ],
        },
      ],
      '/routine/list-summaries/ws/' => [
        {
          'user_id': 'tunde',
          'date': _today,
          'submitted': true,
          'done': 'Wrote tests',
          'blockers': 'Sandbox keys',
        },
      ],
      '/report/get-overview/ws/' => {
        'period': {'date_from': '2026-10-01', 'date_to': '2026-10-31'},
        'metrics': [
          {'key': 'on_time_rate', 'value': 88.9, 'delta': 2.1, 'unit': '%'},
        ],
        'weekly': [
          {'label': '01 Sep', 'completed': 4, 'returned': 1},
        ],
        'attention': [
          {'reference': 'TK-142', 'title': 'Webhook', 'meta': '2 returns'},
        ],
      },
      _ => fail('Unexpected read $path'),
    };
    return ApiResponse<T>.success(body as T);
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
    return ApiResponse<T>.success(<String, dynamic>{'status': 'logged'} as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
