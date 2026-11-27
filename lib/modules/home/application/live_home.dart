import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../approvals/application/approvals_controller.dart';
import '../../birthdays/data/birthdays_repository.dart';
import '../../birthdays/domain/birthday.dart';
import '../../tasks/application/tasks_controller.dart';
import '../../tasks/data/tasks_repository.dart';
import '../../tasks/domain/task.dart';
import '../data/live_home_repository.dart';
import '../data/live_space_projection.dart';

final liveWorkspaceSelectionProvider =
    NotifierProvider<LiveWorkspaceSelection, String?>(
      LiveWorkspaceSelection.new,
    );

class LiveWorkspaceSelection extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(accountSessionProvider.select((account) => account?.id));
    return null;
  }

  void select(AccountWorkspace workspace) {
    if (workspace.approval == 'approved') state = workspace.id;
  }
}

final activeLiveWorkspaceProvider = Provider<AccountWorkspace?>((ref) {
  final approved = ref
      .watch(accountWorkspacesProvider)
      .value
      ?.where((workspace) => workspace.approval == 'approved');
  if (approved == null) return null;
  final selected = ref.watch(liveWorkspaceSelectionProvider);
  return approved.where((workspace) => workspace.id == selected).firstOrNull ??
      approved.firstOrNull;
});

typedef LiveDashboard = ({LiveHomeData data, LocalWorkspace? space});

final liveHomeProvider = FutureProvider.autoDispose
    .family<LiveDashboard, AccountWorkspace>((ref, workspace) async {
      final repository = ref.watch(liveHomeRepositoryProvider);
      final session = ref.read(accountSessionProvider.notifier);
      final accountId = ref.watch(
        accountSessionProvider.select((account) => account?.id),
      );
      try {
        final data = await repository.load(workspace);
        return (
          data: data,
          space: workspace.kind == 'business'
              ? null
              : projectLiveWorkspace(data),
        );
      } on AccountFailure catch (error) {
        if (ref.mounted && accountId != null) {
          await session.expire(error, accountId: accountId);
        }
        rethrow;
      }
    });

final liveHomeActionsProvider = NotifierProvider.autoDispose
    .family<LiveHomeActions, bool, AccountWorkspace>(LiveHomeActions.new);

class LiveHomeActions extends Notifier<bool> {
  LiveHomeActions(this.workspace);

  final AccountWorkspace workspace;

  @override
  bool build() => false;

  Future<DashboardJson> routine(String id) async {
    final session = ref.read(accountSessionProvider.notifier);
    final accountId = ref.read(accountSessionProvider)?.id;
    try {
      return await ref.read(liveHomeRepositoryProvider).routine(id);
    } on AccountFailure catch (error) {
      if (ref.mounted && accountId != null) {
        await session.expire(error, accountId: accountId);
      }
      rethrow;
    }
  }

  Future<bool> submitReport(
    String id,
    String date,
    Map<String, Object> answers,
  ) => _run((repository) => repository.submitReport(id, date, answers));

  /// Review decisions and birthday cards go through the Tasks and Birthdays
  /// repositories, so they behave the same as on those screens.
  Future<bool> approve(TaskItem task) => _shared(() async {
    await ref.read(tasksRepositoryProvider).approve(task);
    ref.invalidate(approvalsProvider);
    ref.invalidate(tasksListProvider);
  });

  Future<bool> returnTask(TaskItem task, String note) => _shared(() async {
    await ref.read(tasksRepositoryProvider).returnTask(task, note);
    ref.invalidate(approvalsProvider);
    ref.invalidate(tasksListProvider);
  });

  /// Sends the API's default card: no message, confetti theme, cake sticker.
  Future<bool> wish(BirthdayPerson person) => _shared(
    () => ref
        .read(birthdaysRepositoryProvider)
        .sendWish(person, message: '', theme: 'confetti', sticker: 'cake'),
  );

  Future<bool> _shared(Future<void> Function() action) => _run((_) => action());

  Future<bool> _run(Future<void> Function(LiveHomeRepository) action) async {
    if (state) return false;
    final session = ref.read(accountSessionProvider.notifier);
    final accountId = ref.read(accountSessionProvider)?.id;
    if (accountId == null) return false;
    state = true;
    try {
      await action(ref.read(liveHomeRepositoryProvider));
      if (ref.mounted) ref.invalidate(liveHomeProvider(workspace));
      return true;
    } on AccountFailure catch (error) {
      if (ref.mounted) await session.expire(error, accountId: accountId);
      rethrow;
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
