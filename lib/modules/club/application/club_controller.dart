import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/application/special_actions.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

enum ClubTab { overview, sessions, fees, attendance, notices }

/// Replies to a session, and attendance marks, in order.
const sessionReplies = ['in', 'maybe', 'out'];
const attendanceMarks = ['present', 'maybe', 'absent'];

extension ClubRecord on WorkspaceRecord {
  bool get isMeta => fields['meta'] == 'true';

  /// Index into [attendanceMarks].
  int get mark => int.tryParse(fields['mark'] ?? '') ?? 0;
}

/// Everything the Club home shows, derived from the workspace records.
class ClubView {
  ClubView(this.space, DateTime now)
    : today = DateTime(now.year, now.month, now.day),
      sessions =
          space
              .items(WorkspaceSection.sessions)
              .where((s) => s.date != null)
              .toList()
            ..sort((a, b) => a.date!.compareTo(b.date!)),
      fees = space.items(WorkspaceSection.fees).toList(),
      attendance = space.items(WorkspaceSection.attendance).toList(),
      notices =
          space.items(WorkspaceSection.notices).where((r) => !r.isMeta).toList()
            ..sort((a, b) => (b.date ?? now).compareTo(a.date ?? now)),
      season = space
          .items(WorkspaceSection.notices)
          .where((r) => r.isMeta)
          .firstOrNull;
  final LocalWorkspace space;
  final DateTime today;
  final List<WorkspaceRecord> sessions, fees, attendance, notices;
  final WorkspaceRecord? season;

  int get members =>
      int.tryParse(season?.fields['size'] ?? '') ?? attendance.length;
  List<WorkspaceRecord> get upcoming =>
      sessions.where((s) => !s.date!.isBefore(today)).toList();
  int get collected => fees.fold(0, (s, f) => s + f.paid.clamp(0, f.amount));
  int get target => (season?.amount ?? 0) > 0
      ? season!.amount
      : fees.fold(0, (s, f) => s + f.amount);
  int get owing => fees.where((f) => f.outstanding > 0).length;
  int marked(int mark) => attendance.where((a) => a.mark == mark).length;
}

final clubViewProvider = Provider.autoDispose.family<ClubView?, String>((
  ref,
  id,
) {
  final space = ref
      .watch(localWorkspacesProvider)
      .value
      ?.workspaces
      .where((w) => w.id == id)
      .firstOrNull;
  return space == null ? null : ClubView(space, DateTime.now());
});

final clubControllerProvider = NotifierProvider.autoDispose
    .family<ClubController, ClubTab, (String, ClubTab)>(ClubController.new);

/// Holds the open tab and marks attendance through [SpecialActions].
class ClubController extends Notifier<ClubTab> {
  ClubController(this.args);

  /// Workspace id and the tab the screen opened on.
  final (String, ClubTab) args;

  @override
  ClubTab build() => args.$2;

  SpecialActions get _actions => ref.read(specialActionsProvider(args.$1));

  void tab(ClubTab value) => state = value;

  Future<bool> mark(WorkspaceRecord member, int mark) => _actions.update(
    member,
    (r) => r.copyWith(fields: {...r.fields, 'mark': '$mark'}),
  );
}
