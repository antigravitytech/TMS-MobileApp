import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Live numbers for the Individual home cards.
class IndividualSummary {
  const IndividualSummary({
    required this.activeClients,
    required this.clients,
    required this.received,
    required this.billed,
    required this.owing,
    required this.weekMinutes,
    required this.billableValue,
    required this.openProposals,
    required this.watch,
    required this.upcoming,
  });
  final int activeClients, clients, received, billed, owing;
  final int weekMinutes, billableValue, openProposals;

  /// The gig flagged at risk, if any.
  final WorkspaceRecord? watch;

  /// Open tasks, soonest first.
  final List<WorkspaceRecord> upcoming;
}

final individualSummaryProvider = Provider.autoDispose
    .family<IndividualSummary?, String>((ref, id) {
      final space = ref
          .watch(localWorkspacesProvider)
          .value
          ?.workspaces
          .where((w) => w.id == id)
          .firstOrNull;
      if (space == null) return null;
      final clients = space.items(WorkspaceSection.clients).toList();
      final invoices = space.items(WorkspaceSection.invoices).toList();
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final week = space
          .items(WorkspaceSection.time)
          .where((t) => t.date == null || !t.date!.isBefore(weekStart));
      final billable = week
          .where((t) => t.flagged)
          .fold(0, (s, t) => s + t.duration);
      final upcoming =
          space
              .items(WorkspaceSection.tasks)
              .where((t) => t.status != WorkspaceStatus.done)
              .toList()
            ..sort(
              (a, b) => (a.date ?? DateTime(9999)).compareTo(
                b.date ?? DateTime(9999),
              ),
            );
      return IndividualSummary(
        activeClients: clients
            .where((c) => (c.fields['stage'] ?? 'active') == 'active')
            .length,
        clients: clients.length,
        received: invoices.fold(0, (s, v) => s + v.paid.clamp(0, v.amount)),
        billed: invoices.fold(0, (s, v) => s + v.amount),
        owing: invoices.where((v) => v.outstanding > 0).length,
        weekMinutes: week.fold(0, (s, t) => s + t.duration),
        billableValue: (billable * space.hourlyRate / 60).round(),
        openProposals: space
            .items(WorkspaceSection.proposals)
            .where((p) => p.status != WorkspaceStatus.done)
            .length,
        watch: space
            .items(WorkspaceSection.gigs)
            .where((g) => g.fields['health'] == 'risk')
            .firstOrNull,
        upcoming: upcoming,
      );
    });

/// What a quick-add line means: the task title and its recognised tokens.
class TaskDraft {
  const TaskDraft({
    required this.title,
    this.due,
    this.priority,
    this.project,
    this.person,
  });
  final String title;

  /// Due day as a weekday (1–7), 0 for today or 8 for tomorrow.
  final int? due;
  final String? priority, project, person;
  bool get hasTokens =>
      due != null || priority != null || project != null || person != null;
}

const _days = {
  'mon': 1,
  'tue': 2,
  'wed': 3,
  'thu': 4,
  'fri': 5,
  'sat': 6,
  'sun': 7,
  'today': 0,
  'tomorrow': 8,
};
const _priorities = {'high', 'urgent', 'low', 'med'};

/// Reads "fri !high #brand @tolu" style shortcuts out of a quick-add line.
TaskDraft parseTask(String line) {
  int? due;
  String? priority, project, person;
  final words = <String>[];
  for (final word in line.trim().split(RegExp(r'\s+'))) {
    final lower = word.toLowerCase();
    if (word.isEmpty) continue;
    if (_days.containsKey(lower)) {
      due = _days[lower];
    } else if (lower.startsWith('!') &&
        _priorities.contains(lower.substring(1))) {
      priority = lower.substring(1);
    } else if (word.length > 1 && word.startsWith('#')) {
      project = word.substring(1);
    } else if (word.length > 1 && word.startsWith('@')) {
      person = word.substring(1);
    } else {
      words.add(word);
    }
  }
  return TaskDraft(
    title: words.join(' '),
    due: due,
    priority: priority,
    project: project,
    person: person,
  );
}

/// The date a draft's due token points at, defaulting to the coming Friday.
DateTime taskDueDate(TaskDraft draft, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final due = draft.due ?? 5;
  if (due == 0) return today;
  if (due == 8) return today.add(const Duration(days: 1));
  final ahead = (due - today.weekday) % 7;
  return today.add(Duration(days: ahead == 0 ? 7 : ahead));
}

final individualHomeProvider = NotifierProvider.autoDispose
    .family<IndividualHome, String, String>(IndividualHome.new);

/// Holds the quick-add line and saves tasks from it.
class IndividualHome extends Notifier<String> {
  IndividualHome(this.workspaceId);
  final String workspaceId;

  @override
  String build() => '';

  void edit(String line) => state = line;

  /// Saves the line as a task. Returns its title, or null when nothing saved.
  Future<String?> add() async {
    final draft = parseTask(state);
    if (draft.title.isEmpty) return null;
    try {
      await ref
          .read(localWorkspacesProvider.notifier)
          .saveRecord(
            workspaceId,
            WorkspaceRecord(
              id: '',
              section: WorkspaceSection.tasks,
              title: draft.title,
              person: draft.person ?? '',
              date: taskDueDate(draft, DateTime.now()),
              points: 0,
              fields: {
                'project': draft.project ?? '',
                'priority': draft.priority ?? '',
              },
            ),
          );
      state = '';
      return draft.title;
    } catch (_) {
      return null;
    }
  }
}
