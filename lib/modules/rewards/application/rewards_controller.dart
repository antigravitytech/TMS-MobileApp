import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

enum RewardsTab { board, shop }

/// The child whose points the Rewards tab spends, as in the prototype.
const rewardsChild = 'Tobi';

class BoardPerson {
  const BoardPerson({
    required this.name,
    required this.role,
    required this.points,
    required this.choresDone,
    required this.choresTotal,
    required this.schoolDone,
    required this.schoolTotal,
  });
  final String name, role;
  final int points, choresDone, choresTotal, schoolDone, schoolTotal;
}

class BoardStats {
  const BoardStats(this.chores, this.school, this.overdue, this.streak);
  final int chores, school, overdue, streak;
}

class RewardsView {
  const RewardsView(this.people, this.stats, this.rewards, this.childPoints);
  final List<BoardPerson> people;
  final BoardStats stats;
  final List<WorkspaceRecord> rewards;
  final int childPoints;
}

final rewardsViewProvider = Provider.autoDispose.family<RewardsView, String>((
  ref,
  id,
) {
  final space = ref
      .watch(localWorkspacesProvider)
      .value
      ?.workspaces
      .where((w) => w.id == id)
      .firstOrNull;
  if (space == null) {
    return const RewardsView([], BoardStats(0, 0, 0, 0), [], 0);
  }
  final chores = space
      .items(WorkspaceSection.chores)
      .where((r) => r.fields['ledger'] != 'true')
      .toList();
  final school = space.items(WorkspaceSection.school).toList();
  bool done(WorkspaceRecord r) => r.status == WorkspaceStatus.done;
  final today = DateTime.now();
  final people = [
    for (final m in space.items(WorkspaceSection.household))
      () {
        final name = m.title.split(' ').first;
        final mine = chores.where((r) => r.person == name);
        final work = school.where((r) => r.person == name);
        return BoardPerson(
          name: name,
          role: m.fields['householdRole'] ?? 'child',
          points: space.availablePoints(name),
          choresDone: mine.where(done).length,
          choresTotal: mine.length,
          schoolDone: work.where(done).length,
          schoolTotal: work.length,
        );
      }(),
  ]..sort((a, b) => b.points.compareTo(a.points));
  final rewards = space.items(WorkspaceSection.rewards).toList()
    ..sort((a, b) => a.points.compareTo(b.points));
  return RewardsView(
    people,
    BoardStats(
      chores.where(done).length,
      school.where(done).length,
      space.records
          .where((r) => !done(r) && r.date != null && r.date!.isBefore(today))
          .length,
      people.where((p) => p.role == 'child' && p.points > 0).length,
    ),
    rewards,
    space.availablePoints(rewardsChild),
  );
});

class RewardsState {
  const RewardsState({this.tab = RewardsTab.board, this.cheered = const {}});
  final RewardsTab tab;
  final Set<String> cheered;
}

final rewardsControllerProvider = NotifierProvider.autoDispose
    .family<RewardsController, RewardsState, String>(RewardsController.new);

class RewardsController extends Notifier<RewardsState> {
  RewardsController(this.workspaceId);
  final String workspaceId;

  @override
  RewardsState build() => const RewardsState();

  void tab(RewardsTab value) =>
      state = RewardsState(tab: value, cheered: state.cheered);

  /// Cheers someone once. Returns false when they were already cheered.
  bool cheer(String name) {
    if (state.cheered.contains(name)) return false;
    state = RewardsState(tab: state.tab, cheered: {...state.cheered, name});
    return true;
  }

  /// Spends the child's points on [reward]. Returns false when it failed.
  Future<bool> give(WorkspaceRecord reward) async {
    try {
      await ref
          .read(localWorkspacesProvider.notifier)
          .redeemReward(workspaceId, reward.id, rewardsChild);
      return true;
    } catch (_) {
      return false;
    }
  }
}
