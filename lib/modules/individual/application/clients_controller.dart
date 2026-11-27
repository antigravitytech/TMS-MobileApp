import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Client stages and proposal stages, kept as codes and translated in the UI.
const clientStages = ['active', 'lead', 'past', 'invited'];
const proposalStages = ['todo', 'sent', 'accepted'];

extension ClientStage on WorkspaceRecord {
  String get stage =>
      fields['stage'] ??
      (section == WorkspaceSection.proposals
          ? switch (status) {
              WorkspaceStatus.done => 'accepted',
              WorkspaceStatus.inProgress => 'sent',
              _ => 'todo',
            }
          : 'active');
}

class ClientsState {
  const ClientsState({required this.proposals, this.filter = 'all'});
  final bool proposals;
  final String filter;
  ClientsState copyWith({bool? proposals, String? filter}) => ClientsState(
    proposals: proposals ?? this.proposals,
    filter: filter ?? this.filter,
  );
}

/// Records for one tab of the Clients screen.
final clientRecordsProvider = Provider.autoDispose
    .family<List<WorkspaceRecord>, (String, WorkspaceSection)>((ref, args) {
      final space = ref
          .watch(localWorkspacesProvider)
          .value
          ?.workspaces
          .where((w) => w.id == args.$1)
          .firstOrNull;
      return space?.items(args.$2).toList() ?? const [];
    });

final clientsControllerProvider = NotifierProvider.autoDispose
    .family<ClientsController, ClientsState, (String, bool)>(
      ClientsController.new,
    );

class ClientsController extends Notifier<ClientsState> {
  ClientsController(this.args);

  /// Workspace id and whether the screen opened on Proposals.
  final (String, bool) args;

  @override
  ClientsState build() => ClientsState(proposals: args.$2);

  LocalWorkspaces get _directory => ref.read(localWorkspacesProvider.notifier);

  void tab(bool proposals) =>
      state = ClientsState(proposals: proposals, filter: 'all');
  void filter(String value) => state = state.copyWith(filter: value);

  /// Moves a client or proposal to [stage]. Returns false when it failed.
  Future<bool> setStage(WorkspaceRecord record, String stage) async {
    try {
      await _directory.updateRecord(
        args.$1,
        record.id,
        (r) => r.copyWith(
          fields: {...r.fields, 'stage': stage},
          status: r.section == WorkspaceSection.proposals
              ? switch (stage) {
                  'accepted' => WorkspaceStatus.done,
                  'sent' => WorkspaceStatus.inProgress,
                  _ => WorkspaceStatus.todo,
                }
              : r.status,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Saves a record from the shared form. Returns false when it failed.
  Future<bool> save(WorkspaceRecord record, Iterable<String> others) async {
    try {
      await _directory.saveRecord(args.$1, record, alsoAssignTo: others);
      return true;
    } catch (_) {
      return false;
    }
  }
}
