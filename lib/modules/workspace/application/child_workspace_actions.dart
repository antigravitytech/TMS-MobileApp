import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/media_service.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import 'local_workspaces.dart';

final childActionsProvider = Provider(
  (ref) => ChildWorkspaceActions(ref.read(localWorkspacesProvider.notifier)),
);

class ChildWorkspaceActions {
  const ChildWorkspaceActions(this.directory);
  final LocalWorkspaces directory;
  Future<void> arrive(String space, String member) => directory.updateRecord(
    space,
    member,
    (old) => old.copyWith(
      fields: {
        ...old.fields,
        'schoolArrival': DateTime.now().toIso8601String(),
      },
    ),
  );
  Future<void> chore(String space, WorkspaceRecord chore) =>
      directory.updateRecord(space, chore.id, (old) {
        if (old.status == WorkspaceStatus.submitted ||
            old.requiresReview && old.status == WorkspaceStatus.done) {
          return old;
        }
        return old.copyWith(
          status: old.status == WorkspaceStatus.done
              ? WorkspaceStatus.todo
              : old.requiresReview
              ? WorkspaceStatus.submitted
              : WorkspaceStatus.done,
        );
      });
  Future<void> homework(String space, WorkspaceRecord homework) async {
    final path = homework.fields['photo'] == 'false'
        ? null
        : await MediaService.pickPrivateImage();
    if (path == null && homework.fields['photo'] != 'false') return;
    await directory.updateRecord(
      space,
      homework.id,
      (old) => old.copyWith(
        fields: {...old.fields, 'workPhoto': ?path},
        status: old.requiresReview
            ? WorkspaceStatus.submitted
            : WorkspaceStatus.done,
      ),
    );
  }
}
