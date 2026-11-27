import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

enum ChoreFilter {
  all(null),
  todo(WorkspaceStatus.todo),
  ip(WorkspaceStatus.inProgress),
  done(WorkspaceStatus.done);

  const ChoreFilter(this.status);
  final WorkspaceStatus? status;
  bool matches(WorkspaceRecord r) => status == null || r.status == status;
}

/// Due choices in the add sheet, kept as codes and translated in the UI.
const choreDues = ['today', 'tomorrow', 'week'];

/// People a chore can go to; children earn points by default.
const choreAssignees = ['Tobi', 'Ada', 'Bisi', 'Kwame', 'Sule'];
const _children = {'Tobi', 'Ada'};

class ChoreDraft {
  const ChoreDraft({this.who = 'Tobi', this.due = 'today', this.points = 10});
  final String who, due;
  final int points;
  ChoreDraft copyWith({String? who, String? due, int? points}) => ChoreDraft(
    who: who ?? this.who,
    due: due ?? this.due,
    points: points ?? this.points,
  );
}

class ChoresState {
  const ChoresState({
    this.filter = ChoreFilter.all,
    this.draft = const ChoreDraft(),
  });
  final ChoreFilter filter;
  final ChoreDraft draft;
  ChoresState copyWith({ChoreFilter? filter, ChoreDraft? draft}) =>
      ChoresState(filter: filter ?? this.filter, draft: draft ?? this.draft);
}

/// Chores for a workspace, newest additions first, without the points ledger.
final choreItemsProvider = Provider.autoDispose
    .family<List<WorkspaceRecord>, String>((ref, id) {
      final space = ref
          .watch(localWorkspacesProvider)
          .value
          ?.workspaces
          .where((w) => w.id == id)
          .firstOrNull;
      final records =
          space
              ?.items(WorkspaceSection.chores)
              .where((r) => r.fields['ledger'] != 'true')
              .toList() ??
          const <WorkspaceRecord>[];
      final added = records.where((r) => !r.id.startsWith('family-ref-'));
      return [
        ...added.toList().reversed,
        ...records.where((r) => r.id.startsWith('family-ref-')),
      ];
    });

/// Points a person can spend, live from the workspace.
final familyPointsProvider = Provider.autoDispose.family<int, (String, String)>(
  (ref, args) {
    final space = ref
        .watch(localWorkspacesProvider)
        .value
        ?.workspaces
        .where((w) => w.id == args.$1)
        .firstOrNull;
    return space?.availablePoints(args.$2) ?? 0;
  },
);

final choresControllerProvider = NotifierProvider.autoDispose
    .family<ChoresController, ChoresState, String>(ChoresController.new);

class ChoresController extends Notifier<ChoresState> {
  ChoresController(this.workspaceId);
  final String workspaceId;

  @override
  ChoresState build() => const ChoresState();

  LocalWorkspaces get _directory => ref.read(localWorkspacesProvider.notifier);

  void filter(ChoreFilter value) => state = state.copyWith(filter: value);

  void pickWho(String who) => state = state.copyWith(
    draft: state.draft.copyWith(
      who: who,
      points: _children.contains(who)
          ? (state.draft.points == 0 ? 10 : state.draft.points)
          : 0,
    ),
  );

  void pickDue(String due) =>
      state = state.copyWith(draft: state.draft.copyWith(due: due));

  void stepPoints(int delta) => state = state.copyWith(
    draft: state.draft.copyWith(
      points: (state.draft.points + delta).clamp(0, 995),
    ),
  );

  /// Saves the draft; an empty name uses the prototype's example chore.
  Future<String?> add(String name, String fallback) async {
    final d = state.draft;
    try {
      await _directory.saveRecord(
        workspaceId,
        WorkspaceRecord(
          id: '',
          section: WorkspaceSection.chores,
          title: name.trim().isEmpty ? fallback : name.trim(),
          person: d.who,
          points: d.points,
          fields: {'dueKey': d.due},
        ),
      );
      state = const ChoresState();
      return d.who;
    } catch (_) {
      return null;
    }
  }

  /// Returns the new done state, or null when saving failed.
  Future<bool?> toggle(WorkspaceRecord chore) async {
    final done = chore.status != WorkspaceStatus.done;
    try {
      await _directory.updateRecord(
        workspaceId,
        chore.id,
        (r) => r.copyWith(
          status: done ? WorkspaceStatus.done : WorkspaceStatus.todo,
        ),
      );
      return done;
    } catch (_) {
      return null;
    }
  }
}
