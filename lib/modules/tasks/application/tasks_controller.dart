import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../data/tasks_repository.dart';
import '../domain/task.dart';

/// One list tab's tasks and every tab's count. Network requests already
/// retry, so failures show at once.
final tasksListProvider = FutureProvider.autoDispose
    .family<TaskList, TaskScope>(
      (ref, scope) => guardSession(
        ref,
        () => ref.watch(tasksRepositoryProvider).list(scope),
      ),
      retry: (_, _) => null,
    );

/// The task on the detail screen: the tapped task, passed along so opening
/// it needs no request. Actions replace it with the server's copy.
final openedTaskProvider = NotifierProvider<OpenedTask, TaskItem?>(
  OpenedTask.new,
);

class OpenedTask extends Notifier<TaskItem?> {
  @override
  TaskItem? build() => ref.watch(tasksRepositoryProvider).opened;

  TasksRepository get _repository => ref.read(tasksRepositoryProvider);

  void open(TaskItem task) => state = task;

  Future<void> start() => _act((task) => _repository.start(task));
  Future<void> submit(String note) =>
      _act((task) => _repository.submit(task, note));
  Future<void> complete() => _act((task) => _repository.complete(task));

  Future<void> _act(Future<TaskItem> Function(TaskItem) action) async {
    final task = state;
    if (task == null) return;
    final updated = await guardSession(ref, () => action(task));
    if (!ref.mounted) return;
    state = updated;
    ref.invalidate(tasksListProvider);
  }
}

/// The Activity and Files tabs, loaded the first time each is shown.
final taskActivityProvider = FutureProvider.autoDispose
    .family<List<TaskActivity>, TaskItem>(
      (ref, task) => guardSession(
        ref,
        () => ref.read(tasksRepositoryProvider).activity(task),
      ),
      retry: (_, _) => null,
    );

final taskFilesProvider = FutureProvider.autoDispose
    .family<List<TaskFile>, TaskItem>(
      (ref, task) => guardSession(
        ref,
        () => ref.read(tasksRepositoryProvider).files(task),
      ),
      retry: (_, _) => null,
    );

/// The Comments tab, with adding a comment.
final taskCommentsProvider = AsyncNotifierProvider.autoDispose
    .family<TaskComments, List<TaskComment>, TaskItem>(
      TaskComments.new,
      retry: (_, _) => null,
    );

class TaskComments extends AsyncNotifier<List<TaskComment>> {
  TaskComments(this.task);
  final TaskItem task;

  @override
  Future<List<TaskComment>> build() =>
      guardSession(ref, () => ref.read(tasksRepositoryProvider).comments(task));

  Future<void> add(String body) async {
    if (body.trim().isEmpty) return;
    final saved = await guardSession(
      ref,
      () => ref.read(tasksRepositoryProvider).comment(task, body),
    );
    if (ref.mounted) state = AsyncData([...?state.value, saved]);
  }
}

/// People, projects and teams for New task, kept for the session.
final taskOptionsProvider = FutureProvider<TaskOptions>(
  (ref) =>
      guardSession(ref, () => ref.watch(tasksRepositoryProvider).options()),
  retry: (_, _) => null,
);

/// Creates a task and opens it without another request.
final createTaskProvider = Provider<Future<TaskItem> Function(TaskDraft)>(
  (ref) => (draft) async {
    final created = await guardSession(
      ref,
      () => ref.read(tasksRepositoryProvider).create(draft),
    );
    ref.read(openedTaskProvider.notifier).open(created);
    ref.invalidate(tasksListProvider);
    return created;
  },
);
