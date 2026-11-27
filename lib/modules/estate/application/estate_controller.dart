import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/application/special_actions.dart';
import '../../specials/presentation/widgets/special_stages.dart';

export '../../specials/presentation/widgets/special_stages.dart'
    show SpecialStage;
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

enum EstateTab { overview, levies, passes, issues, notices, poll }

/// Facility issue stages, in order.
const issueStages = ['reported', 'fixing', 'fixed'];

/// When a new gate pass is for, as day offsets from today.
const passDays = {'today': 0, 'tomorrow': 1, 'saturday': -1};

extension EstateRecord on WorkspaceRecord {
  bool get isMeta => fields['meta'] == 'true';
  String get code => fields['accessCode'] ?? '';
}

/// Everything the Estate home shows, derived from the workspace records.
class EstateView {
  EstateView(this.space, DateTime now)
    : today = DateTime(now.year, now.month, now.day),
      levies = space.items(WorkspaceSection.levies).toList(),
      passes = space.items(WorkspaceSection.passes).toList()
        ..sort((a, b) => (a.date ?? now).compareTo(b.date ?? now)),
      issues = space.items(WorkspaceSection.issues).toList(),
      notices =
          space.items(WorkspaceSection.notices).where((r) => !r.isMeta).toList()
            ..sort((a, b) => (b.date ?? now).compareTo(a.date ?? now)),
      info = space
          .items(WorkspaceSection.notices)
          .where((r) => r.isMeta)
          .firstOrNull,
      poll = space.items(WorkspaceSection.poll).lastOrNull;
  final LocalWorkspace space;
  final DateTime today;
  final List<WorkspaceRecord> levies, passes, issues, notices;

  /// The estate record: houses, the next meeting and the levy target.
  final WorkspaceRecord? info;
  final WorkspaceRecord? poll;

  int get houses => int.tryParse(info?.fields['size'] ?? '') ?? levies.length;
  int get collected => levies.fold(0, (s, l) => s + l.paid.clamp(0, l.amount));
  int get target => (info?.amount ?? 0) > 0
      ? info!.amount
      : levies.fold(0, (s, l) => s + l.amount);
  int get owing => levies.where((l) => l.outstanding > 0).length;

  /// Passes from today on.
  List<WorkspaceRecord> get upcomingPasses =>
      passes.where((p) => p.date == null || !p.date!.isBefore(today)).toList();
  int get openIssues => issues.where((i) => i.stage < 2).length;
}

final estateViewProvider = Provider.autoDispose.family<EstateView?, String>((
  ref,
  id,
) {
  final space = ref
      .watch(localWorkspacesProvider)
      .value
      ?.workspaces
      .where((w) => w.id == id)
      .firstOrNull;
  return space == null ? null : EstateView(space, DateTime.now());
});

class EstateState {
  const EstateState({this.tab = EstateTab.overview});
  final EstateTab tab;
}

final estateControllerProvider = NotifierProvider.autoDispose
    .family<EstateController, EstateState, (String, EstateTab)>(
      EstateController.new,
    );

/// Holds the open tab and changes Estate records through [SpecialActions].
class EstateController extends Notifier<EstateState> {
  EstateController(this.args);

  /// Workspace id and the tab the screen opened on.
  final (String, EstateTab) args;

  @override
  EstateState build() => EstateState(tab: args.$2);

  SpecialActions get _actions => ref.read(specialActionsProvider(args.$1));

  void tab(EstateTab value) => state = EstateState(tab: value);

  /// Creates a gate pass with a fresh four-digit code. Returns the code.
  Future<String?> createPass(String who, String when) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final offset = passDays[when] ?? 0;
    final date = offset >= 0
        ? today.add(Duration(days: offset))
        : today.add(Duration(days: (DateTime.saturday - today.weekday) % 7));
    final code = '${1000 + Random().nextInt(9000)}';
    final ok = await _actions.add(
      WorkspaceRecord(
        id: '',
        section: WorkspaceSection.passes,
        title: who,
        date: date,
        points: 0,
        fields: {'accessCode': code, 'anyTime': 'true', 'new': 'true'},
      ),
    );
    return ok ? code : null;
  }
}
