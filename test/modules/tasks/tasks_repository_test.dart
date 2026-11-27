import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/tasks/application/tasks_controller.dart';
import 'package:sabi_pipu_tms/modules/tasks/data/tasks_repository.dart';
import 'package:sabi_pipu_tms/modules/tasks/domain/task.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/workspace_preview.dart';

void main() {
  T keep<T>(ProviderContainer c, ProviderListenable<T> p) {
    final sub = c.listen(p, (_, _) {});
    addTearDown(sub.close);
    return sub.read();
  }

  test('mock tasks adapt the preview and write back to it', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(c.read(tasksRepositoryProvider), isA<MockTasksRepository>());
    keep(c, tasksListProvider(TaskScope.mine));
    final mine = await c.read(tasksListProvider(TaskScope.mine).future);
    expect(
      mine.tasks.map((t) => t.reference),
      containsAll(['TK-190', 'TK-192']),
    );
    expect(
      mine.counts[TaskScope.all],
      c.read(workspacePreviewProvider).tasks.length,
    );
    final hiring = mine.tasks.firstWhere((t) => t.reference == 'TK-190');
    expect(hiring.status, TaskStatus.inProgress);
    expect(hiring.priority, TaskPriority.high);
    expect(hiring.permissions.canSubmit, isTrue);

    keep(c, openedTaskProvider);
    c.read(openedTaskProvider.notifier).open(hiring);
    await c.read(openedTaskProvider.notifier).submit('Plan attached');
    expect(c.read(openedTaskProvider)?.status, TaskStatus.submitted);
    expect(
      c
          .read(workspacePreviewProvider)
          .tasks
          .firstWhere((t) => t.id == 'TK-190')
          .status,
      'Submitted',
    );
  });

  group('live tasks', () {
    late _TaskTransport transport;
    late ProviderContainer c;

    setUp(() {
      transport = _TaskTransport();
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

    test('a tab lists its scope with every tab count', () async {
      keep(c, tasksListProvider(TaskScope.mine));
      final list = await c.read(tasksListProvider(TaskScope.mine).future);
      expect(transport.queries['/task/list-tasks/ws/'], {
        'scope': 'mine',
        'sort_by': 'due',
        'sort_dir': 'asc',
        'page_size': 100,
      });
      expect(list.counts, {
        TaskScope.mine: 1,
        TaskScope.requests: 2,
        TaskScope.team: 3,
        TaskScope.all: 6,
      });
      final task = list.tasks.single;
      expect(
        (task.reference, task.project, task.status),
        ('TK-142', 'Tech Team', TaskStatus.inProgress),
      );
      expect(task.assignee?.name, 'Ari Lee');
      expect(task.permissions.canSubmit, isTrue);
    });

    test('opening a task needs no request; tabs load on their own', () async {
      keep(c, tasksListProvider(TaskScope.mine));
      final task = (await c.read(
        tasksListProvider(TaskScope.mine).future,
      )).tasks.single;
      transport.reads.clear();
      c.read(openedTaskProvider.notifier).open(task);
      expect(c.read(openedTaskProvider), same(task));
      expect(transport.reads, isEmpty);

      keep(c, taskActivityProvider(task));
      final activity = await c.read(taskActivityProvider(task).future);
      expect(transport.reads, ['/task/list-activity/t1/']);
      expect(activity.single.kind, 'started');

      keep(c, taskCommentsProvider(task));
      await c.read(taskCommentsProvider(task).future);
      await c.read(taskCommentsProvider(task).notifier).add('  On it  ');
      expect(transport.writes.last.$1, '/task/add-comment/t1/');
      expect(transport.writes.last.$2, {'kind': 'general', 'body': 'On it'});
      expect(c.read(taskCommentsProvider(task)).value!.last.mine, isTrue);
    });

    test('submit replaces the opened task with the server copy', () async {
      keep(c, tasksListProvider(TaskScope.mine));
      keep(c, openedTaskProvider);
      final task = (await c.read(
        tasksListProvider(TaskScope.mine).future,
      )).tasks.single;
      c.read(openedTaskProvider.notifier).open(task);
      await c.read(openedTaskProvider.notifier).submit(' Done ');
      expect(transport.writes.last.$1, '/task/submit-task/t1/');
      expect(transport.writes.last.$2, {'note': 'Done'});
      final opened = c.read(openedTaskProvider)!;
      expect((opened.status, opened.round), (TaskStatus.submitted, 1));
    });

    test('new task options and creation', () async {
      final repo = c.read(tasksRepositoryProvider);
      final options = await repo.options();
      expect(options.me.id, 'me');
      expect(options.people.map((p) => p.name), ['Tunde Bakare']);
      expect(options.projects, [('p1', 'Customer Portal')]);
      expect(options.teams, [('team1', 'Tech Team')]);

      keep(c, openedTaskProvider);
      final created = await c.read(createTaskProvider)(
        TaskDraft(
          title: ' Ship it ',
          description: '',
          type: TaskType.project,
          assignee: options.people.single,
          due: DateTime(2026, 12, 4),
          priority: TaskPriority.critical,
          confidential: true,
          projectId: 'p1',
        ),
      );
      expect(transport.writes.last.$1, '/task/create-task/ws/');
      expect(transport.writes.last.$2, {
        'title': 'Ship it',
        'type': 'project',
        'assignee_ids': ['tunde'],
        'priority': 'critical',
        'visibility': 'confidential',
        'due_date': '2026-12-04',
        'project_id': 'p1',
      });
      expect(c.read(openedTaskProvider), same(created));
      expect(created.scopes, contains(TaskScope.requests));
    });

    test('a broken list is an error, never mock data', () async {
      transport.broken = true;
      keep(c, tasksListProvider(TaskScope.mine));
      await expectLater(
        c.read(tasksListProvider(TaskScope.mine).future),
        throwsA(isA<AccountFailure>()),
      );
    });
  });
}

Map<String, dynamic> _user(String id, String first, String last) => {
  'id': id,
  'email': '$id@example.test',
  'first_name': first,
  'last_name': last,
  'photo': null,
};

Map<String, dynamic> _task({String status = 'in_progress', int round = 0}) => {
  'id': 't1',
  'reference': 'TK-142',
  'title': 'Payment webhook retry handler',
  'type': 'team',
  'status': status,
  'priority': 'high',
  'visibility': 'public',
  'project': null,
  'team': {'id': 'team1', 'name': 'Tech Team', 'color': '#6658c0'},
  'assignee': _user('me', 'Ari', 'Lee'),
  'assigner': _user('chioma', 'Chioma', 'Okafor'),
  'due_date': '2026-11-30',
  'original_due_date': '2026-11-30',
  'completed_at': null,
  'submission_round': round,
  'permissions': {
    'can_start': false,
    'can_submit': status == 'in_progress',
    'can_complete': false,
    'can_comment': true,
  },
  'created_at': '2026-11-20T09:00:00Z',
};

class _TaskTransport implements NetworkCallsRepository {
  final reads = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  final writes = <(String, Object?)>[];
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
    queries[path] = queryParameters;
    final Object body = switch (path) {
      '/task/list-tasks/ws/' => {
        'items': broken ? 'oops' : [_task()],
      },
      '/task/get-summary/ws/' => {
        'tabs': {'mine': 1, 'requests': 2, 'team': 3, 'all': 6},
      },
      '/task/list-activity/t1/' => {
        'items': [
          {
            'actor': _user('me', 'Ari', 'Lee'),
            'kind': 'started',
            'note': null,
            'created_at': '2026-11-21T10:00:00Z',
          },
        ],
      },
      '/task/list-comments/t1/' => {'items': <Object>[]},
      '/workspace/list-members/ws/' => {
        'items': [
          {'user': _user('me', 'Ari', 'Lee')},
          {'user': _user('tunde', 'Tunde', 'Bakare')},
        ],
      },
      '/project/list-projects/ws/' => {
        'items': [
          {'id': 'p1', 'name': 'Customer Portal'},
        ],
      },
      '/team/list-teams/ws/' => {
        'items': [
          {'id': 'team1', 'name': 'Tech Team'},
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
    expect(withToken, isTrue);
    writes.add((path, data));
    final Object body = switch (path) {
      '/task/submit-task/t1/' => _task(status: 'submitted', round: 1),
      '/task/add-comment/t1/' => {
        'author': _user('me', 'Ari', 'Lee'),
        'body': 'On it',
        'created_at': '2026-11-27T10:00:00Z',
      },
      '/task/create-task/ws/' => [_task(status: 'not_started')],
      _ => fail('Unexpected write $path'),
    };
    return ApiResponse<T>.success(body as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
