import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/application/special_actions.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

enum CommitteeTab { overview, meetings, actions, minutes, decisions }

/// Action item stages, in order.
const actionStages = ['todo', 'doing', 'done'];

/// Replies to a meeting invite.
const meetingReplies = ['coming', 'maybe', 'cant'];

extension CommitteeRecord on WorkspaceRecord {
  bool get isMeta => fields['meta'] == 'true';
}

/// Everything the Committee home shows, derived from the workspace records.
class CommitteeView {
  CommitteeView(this.space, DateTime now)
    : today = DateTime(now.year, now.month, now.day),
      meetings =
          space
              .items(WorkspaceSection.meetings)
              .where((m) => !m.isMeta && m.date != null)
              .toList()
            ..sort((a, b) => a.date!.compareTo(b.date!)),
      actions = space.items(WorkspaceSection.actions).toList(),
      minutes = space.items(WorkspaceSection.minutes).toList()
        ..sort((a, b) => (b.date ?? now).compareTo(a.date ?? now)),
      decision = space.items(WorkspaceSection.decisions).lastOrNull,
      term = space
          .items(WorkspaceSection.meetings)
          .where((m) => m.isMeta)
          .firstOrNull;
  final LocalWorkspace space;
  final DateTime today;
  final List<WorkspaceRecord> meetings, actions, minutes;
  final WorkspaceRecord? decision, term;

  int get members => int.tryParse(term?.fields['size'] ?? '') ?? 0;
  List<WorkspaceRecord> get upcoming =>
      meetings.where((m) => !m.date!.isBefore(today)).toList();
  int get openActions =>
      actions.where((a) => a.status != WorkspaceStatus.done).length;
  int get draftMinutes =>
      minutes.where((m) => m.status != WorkspaceStatus.done).length;
}

final committeeViewProvider = Provider.autoDispose
    .family<CommitteeView?, String>((ref, id) {
      final space = ref
          .watch(localWorkspacesProvider)
          .value
          ?.workspaces
          .where((w) => w.id == id)
          .firstOrNull;
      return space == null ? null : CommitteeView(space, DateTime.now());
    });

final committeeControllerProvider = NotifierProvider.autoDispose
    .family<CommitteeController, CommitteeTab, (String, CommitteeTab)>(
      CommitteeController.new,
    );

/// Holds the open tab and changes Committee records via [SpecialActions].
class CommitteeController extends Notifier<CommitteeTab> {
  CommitteeController(this.args);

  /// Workspace id and the tab the screen opened on.
  final (String, CommitteeTab) args;

  @override
  CommitteeTab build() => args.$2;

  SpecialActions get _actions => ref.read(specialActionsProvider(args.$1));

  void tab(CommitteeTab value) => state = value;

  /// Saves edited minutes and marks them shared with members.
  Future<bool> saveMinutes(WorkspaceRecord minutes, String text) =>
      _actions.update(
        minutes,
        (r) => r.copyWith(
          notes: text,
          status: WorkspaceStatus.done,
          fields: {...r.fields, 'read': '1'},
        ),
      );

  /// Turns minute lines that give someone a job ("X to do Y") into action
  /// items. Returns how many were added, or null when saving failed.
  Future<int?> actionsFromMinutes(String text, String from) async {
    final jobs = [
      for (final line in text.split('\n'))
        if (RegExp(r'^\s*\S+ to \S').hasMatch(line)) line.trim(),
    ];
    for (final job in jobs) {
      final owner = job.split(' ').first;
      final ok = await _actions.addStaged(
        WorkspaceSection.actions,
        job.replaceAll(RegExp(r'\.$'), ''),
        '$from · $owner',
      );
      if (!ok) return null;
    }
    return jobs.length;
  }
}
