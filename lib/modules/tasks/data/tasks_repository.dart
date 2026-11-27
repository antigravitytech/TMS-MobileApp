import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../../workspace/application/workspace_preview.dart';
import '../domain/task.dart';

part 'live_tasks_repository.dart';
part 'mock_tasks_repository.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) {
    // Home and chat open a task by selecting it in the preview.
    ref.watch(workspacePreviewProvider.select((p) => p.selectedTask?.id));
    return MockTasksRepository(ref.read(workspacePreviewProvider));
  }
  return LiveTasksRepository(
    ref.watch(networkCallsRepositoryProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
    me: ref.watch(accountSessionProvider),
  );
});

abstract class TasksRepository {
  /// The task another screen asked to open, when it isn't known by id.
  TaskItem? get opened;

  Future<TaskList> list(TaskScope scope);

  /// One task by id, for screens that only know its id.
  Future<TaskItem> byId(String id);

  /// A task's tabs, each loaded only when its tab is shown.
  Future<List<TaskActivity>> activity(TaskItem task);
  Future<List<TaskComment>> comments(TaskItem task);
  Future<List<TaskFile>> files(TaskItem task);

  Future<TaskItem> start(TaskItem task);
  Future<TaskItem> submit(TaskItem task, String note);
  Future<TaskItem> complete(TaskItem task);
  Future<TaskComment> comment(TaskItem task, String body);

  /// Submitted tasks I approve, and how reviews are going.
  Future<ReviewQueue> approvals();

  /// The assignee's note on their latest submission.
  Future<String> submissionNote(TaskItem task);
  Future<void> approve(TaskItem task);

  /// Sends the task back; [note] says what needs to change.
  Future<void> returnTask(TaskItem task, String note);

  Future<TaskOptions> options();
  Future<TaskItem> create(TaskDraft draft);
}
