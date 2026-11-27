import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// The person field used for time that isn't billed to a client.
const adminClient = 'Admin';

class TimeSummary {
  const TimeSummary({
    required this.entries,
    required this.clients,
    required this.byClient,
    required this.minutes,
    required this.billableMinutes,
    required this.rate,
  });

  /// This week's entries, newest first.
  final List<WorkspaceRecord> entries;

  /// Active clients the timer can bill to.
  final List<String> clients;

  /// Minutes per client this week, clients first and Admin last.
  final List<(String, int)> byClient;
  final int minutes, billableMinutes;

  /// Hourly rate in kobo.
  final int rate;
  int get billableValue => (billableMinutes * rate / 60).round();
}

final timeSummaryProvider = Provider.autoDispose.family<TimeSummary?, String>((
  ref,
  id,
) {
  final space = ref
      .watch(localWorkspacesProvider)
      .value
      ?.workspaces
      .where((w) => w.id == id)
      .firstOrNull;
  if (space == null) return null;
  final now = DateTime.now();
  final weekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final entries =
      space
          .items(WorkspaceSection.time)
          .where((t) => t.date == null || !t.date!.isBefore(weekStart))
          .toList()
        ..sort(
          (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
        );
  final clients = space
      .items(WorkspaceSection.clients)
      .where((c) => (c.fields['stage'] ?? 'active') == 'active')
      .map((c) => c.title)
      .toList();
  final totals = <String, int>{for (final c in clients) c: 0};
  for (final e in entries) {
    final who = e.person.isEmpty ? adminClient : e.person;
    totals[who] = (totals[who] ?? 0) + e.duration;
  }
  final admin = totals.remove(adminClient);
  return TimeSummary(
    entries: entries,
    clients: clients,
    byClient: [
      for (final MapEntry(:key, :value) in totals.entries) (key, value),
      (adminClient, admin ?? 0),
    ],
    minutes: entries.fold(0, (s, e) => s + e.duration),
    billableMinutes: entries
        .where((e) => e.flagged)
        .fold(0, (s, e) => s + e.duration),
    rate: space.hourlyRate,
  );
});

final timeActionsProvider = Provider.autoDispose.family<TimeActions, String>(
  (ref, id) => TimeActions(ref, id),
);

class TimeActions {
  TimeActions(this._ref, this.workspaceId);
  final Ref _ref;
  final String workspaceId;

  /// Flips an entry between billable and not. Returns false on failure.
  Future<bool> toggleBillable(WorkspaceRecord entry) async {
    try {
      await _ref
          .read(localWorkspacesProvider.notifier)
          .updateRecord(
            workspaceId,
            entry.id,
            (r) => r.copyWith(flagged: !r.flagged),
          );
      return true;
    } catch (_) {
      return false;
    }
  }
}
