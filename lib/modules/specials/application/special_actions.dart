import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_entry.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Actions every Specials home shares: notices and recorded payments.
final specialActionsProvider = Provider.autoDispose
    .family<SpecialActions, String>((ref, id) => SpecialActions(ref, id));

class SpecialActions {
  SpecialActions(this._ref, this.workspaceId);
  final Ref _ref;
  final String workspaceId;
  LocalWorkspaces get _directory => _ref.read(localWorkspacesProvider.notifier);

  Future<bool> _try(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Saves my reply ("coming", "maybe"…) to a meeting or session.
  Future<bool> reply(WorkspaceRecord item, String reply) =>
      update(item, (r) => r.copyWith(fields: {...r.fields, 'myReply': reply}));

  /// Posts a notice to everyone. Returns false when nothing was saved.
  Future<bool> postNotice(String text) {
    final body = text.trim();
    if (body.isEmpty) return Future.value(false);
    return _try(
      () => _directory.saveRecord(
        workspaceId,
        WorkspaceRecord(
          id: '',
          section: WorkspaceSection.notices,
          title: body,
          date: DateTime.now(),
          points: 0,
          fields: const {'read': '0'},
        ),
      ),
    );
  }

  /// Records money against a fund, due or levy, by [giver] if named.
  Future<bool> recordPayment(
    WorkspaceRecord record, {
    required int kobo,
    required String method,
    String giver = '',
  }) => _try(
    () => _directory.addEntry(
      workspaceId,
      record.id,
      WorkspaceEntry(
        kind: EntryKind.payment,
        date: DateTime.now(),
        name: giver,
        method: method,
        amount: kobo,
      ),
    ),
  );

  /// Applies [change] to a record. Returns false when saving failed.
  Future<bool> update(
    WorkspaceRecord record,
    WorkspaceRecord Function(WorkspaceRecord) change,
  ) => _try(() => _directory.updateRecord(workspaceId, record.id, change));

  /// Moves a staged item to [stage]; the [last] stage marks it done.
  Future<bool> setStage(WorkspaceRecord item, int stage, {int last = 2}) =>
      update(
        item,
        (r) => r.copyWith(
          status: stage == last ? WorkspaceStatus.done : WorkspaceStatus.todo,
          fields: {...r.fields, 'stage': '$stage'},
        ),
      );

  /// Adds a staged item at the first stage, noting who added it.
  Future<bool> addStaged(WorkspaceSection section, String title, String by) {
    final text = title.trim();
    if (text.isEmpty) return Future.value(false);
    return add(
      WorkspaceRecord(
        id: '',
        section: section,
        title: text,
        notes: by,
        points: 0,
        fields: const {'stage': '0'},
      ),
    );
  }

  /// Casts or moves my vote on a poll.
  Future<bool> vote(WorkspaceRecord poll, int option) =>
      update(poll, (r) => r.copyWith(vote: option));

  /// Saves a new record. Returns false when saving failed.
  Future<bool> add(WorkspaceRecord record) =>
      _try(() => _directory.saveRecord(workspaceId, record));
}
