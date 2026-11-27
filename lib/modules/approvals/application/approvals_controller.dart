import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../../tasks/application/tasks_controller.dart';
import '../../tasks/data/tasks_repository.dart';
import '../../tasks/domain/task.dart';

/// The review queue. A decision removes the card and updates the counters
/// here, so the queue isn't fetched again.
final approvalsProvider =
    AsyncNotifierProvider.autoDispose<ApprovalsController, ReviewQueue>(
      ApprovalsController.new,
      retry: (_, _) => null,
    );

class ApprovalsController extends AsyncNotifier<ReviewQueue> {
  TasksRepository get _repository => ref.read(tasksRepositoryProvider);

  @override
  Future<ReviewQueue> build() =>
      guardSession(ref, () => ref.watch(tasksRepositoryProvider).approvals());

  Future<void> approve(TaskItem task) =>
      _decide(task, approved: true, () => _repository.approve(task));

  /// Sends [task] back with what needs to change.
  Future<void> returnTask(TaskItem task, String note) =>
      _decide(task, approved: false, () => _repository.returnTask(task, note));

  Future<void> _decide(
    TaskItem task,
    Future<void> Function() action, {
    required bool approved,
  }) async {
    await guardSession(ref, action);
    final queue = state.value;
    if (!ref.mounted || queue == null) return;
    state = AsyncData(queue.decided(task, approved: approved));
    ref.invalidate(tasksListProvider);
  }
}

/// The note on the card being reviewed, loaded for that card only.
final reviewNoteProvider = FutureProvider.autoDispose.family<String, TaskItem>(
  (ref, task) => guardSession(
    ref,
    () => ref.read(tasksRepositoryProvider).submissionNote(task),
  ),
  retry: (_, _) => null,
);
