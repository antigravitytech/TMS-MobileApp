import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/approvals/application/approvals_controller.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/workspace_preview.dart';

void main() {
  T keep<T>(ProviderContainer c, ProviderListenable<T> p) {
    final sub = c.listen(p, (_, _) {});
    addTearDown(sub.close);
    return sub.read();
  }

  test('mock reviews come from the preview and decisions update it', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    keep(c, approvalsProvider);
    final queue = await c.read(approvalsProvider.future);
    final preview = c.read(workspacePreviewProvider);
    expect(queue.tasks.length, preview.reviewQueue.length);
    expect((queue.approved, queue.returned), (2, 5));
    final first = queue.tasks.first;
    expect(await c.read(reviewNoteProvider(first).future), isNotEmpty);

    await c.read(approvalsProvider.notifier).approve(first);
    final after = c.read(approvalsProvider).requireValue;
    expect(after.tasks.map((t) => t.id), isNot(contains(first.id)));
    expect(after.approved, 3);
    expect(preview.approved, contains(first.id));
  });

  group('live reviews', () {
    late _ReviewTransport transport;
    late ProviderContainer c;

    setUp(() {
      transport = _ReviewTransport();
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

    test('the queue, its stats and one card note', () async {
      keep(c, approvalsProvider);
      final queue = await c.read(approvalsProvider.future);
      expect(transport.queries['/task/list-approvals/ws/'], {
        'sort': 'oldest',
        'page_size': 100,
      });
      expect(queue.tasks.map((t) => (t.reference, t.round, t.fileCount)), [
        ('TK-1', 2, 3),
        ('TK-2', 1, 0),
      ]);
      expect((queue.avgHours, queue.approved, queue.returned), (6.4, 5, 1));

      transport.reads.clear();
      keep(c, reviewNoteProvider(queue.tasks.first));
      expect(
        await c.read(reviewNoteProvider(queue.tasks.first).future),
        'Ready for review',
      );
      expect(transport.reads, ['/task/get-task/t1/']);
    });

    test('approve and return leave the queue without refetching', () async {
      keep(c, approvalsProvider);
      final queue = await c.read(approvalsProvider.future);
      transport.reads.clear();
      final controller = c.read(approvalsProvider.notifier);

      await controller.approve(queue.tasks.first);
      expect(transport.writes.last.$1, '/task/approve-task/t1/');
      await controller.returnTask(queue.tasks.last, ' Needs tests ');
      expect(transport.writes.last.$1, '/task/return-task/t2/');
      expect(transport.writes.last.$2, {'note': 'Needs tests'});

      final after = c.read(approvalsProvider).requireValue;
      expect(after.tasks, isEmpty);
      expect((after.approved, after.returned), (6, 2));
      expect(transport.reads, isEmpty);
    });

    test('a failed decision keeps the card', () async {
      keep(c, approvalsProvider);
      final queue = await c.read(approvalsProvider.future);
      transport.failWrites = true;
      await expectLater(
        c.read(approvalsProvider.notifier).approve(queue.tasks.first),
        throwsA(isA<AccountFailure>()),
      );
      expect(c.read(approvalsProvider).requireValue.tasks.length, 2);
    });
  });
}

Map<String, dynamic> _task(String id, String ref, int round, int files) => {
  'id': id,
  'reference': ref,
  'title': 'Review $ref',
  'type': 'standalone',
  'status': 'submitted',
  'priority': 'high',
  'visibility': 'public',
  'assignee': {'id': 'tunde', 'first_name': 'Tunde', 'last_name': 'Bakare'},
  'assigner': {'id': 'me', 'first_name': 'Ari', 'last_name': 'Lee'},
  'due_date': '2026-11-30',
  'submitted_at': '2026-11-27T08:00:00Z',
  'submission_round': round,
  'attachment_count': files,
  'permissions': <String, dynamic>{},
};

class _ReviewTransport implements NetworkCallsRepository {
  final reads = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  final writes = <(String, Object?)>[];
  var failWrites = false;

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
    queries[path] = queryParameters;
    final Object body = switch (path) {
      '/task/list-approvals/ws/' => {
        'items': [_task('t1', 'TK-1', 2, 3), _task('t2', 'TK-2', 1, 0)],
      },
      '/task/get-summary/ws/' => {
        'review': {
          'waiting': 2,
          'avg_review_hours': 6.4,
          'approved_this_week': 5,
          'returned_this_week': 1,
        },
      },
      '/task/get-task/t1/' => {'latest_submission_note': 'Ready for review'},
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
    expect(withToken, isTrue);
    writes.add((path, data));
    if (failWrites) {
      return ApiResponse<T>.error(
        'Server error',
        statusCode: 500,
        failureType: NetworkFailureType.server,
      );
    }
    return ApiResponse<T>.success(<String, dynamic>{'id': 'ok'} as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
