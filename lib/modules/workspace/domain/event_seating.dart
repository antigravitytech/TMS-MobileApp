import 'local_workspace.dart';
import 'workspace_kind.dart';

extension EventSeating on LocalWorkspace {
  Iterable<WorkspaceRecord> get arrivingGuests =>
      items(WorkspaceSection.guests).where(
        (r) =>
            r.status == WorkspaceStatus.confirmed ||
            r.status == WorkspaceStatus.maybe,
      );
  int seatsTaken(String table, {String? except}) => arrivingGuests
      .where((r) => r.group == table && r.id != except)
      .fold(0, (n, r) => n + r.duration);
  bool canSeat(String table, WorkspaceRecord guest) {
    final definition = items(
      WorkspaceSection.seating,
    ).where((t) => t.title == table).firstOrNull;
    return definition == null ||
        seatsTaken(table, except: guest.id) + guest.duration <=
            definition.duration;
  }

  List<WorkspaceRecord> autoSeat() {
    final tables = items(WorkspaceSection.seating).toList();
    final free = {
      for (final table in tables)
        table.title: table.duration - seatsTaken(table.title),
    };
    final guests = arrivingGuests.where((g) => g.group.isEmpty).toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));
    final changes = <String, String>{};
    final groupTables = <String, String>{
      for (final g in arrivingGuests)
        if (g.group.isNotEmpty && (g.fields['side'] ?? '').isNotEmpty)
          g.fields['side']!: g.group,
    };
    for (final guest in guests) {
      final side = guest.fields['side'] ?? '';
      final preferred = groupTables[side];
      final table =
          preferred != null && (free[preferred] ?? 0) >= guest.duration
          ? preferred
          : free.keys.where((t) => free[t]! >= guest.duration).firstOrNull;
      if (table == null) continue;
      free[table] = free[table]! - guest.duration;
      changes[guest.id] = table;
      if (side.isNotEmpty) groupTables[side] = table;
    }
    return [
      for (final record in records)
        changes.containsKey(record.id)
            ? record.copyWith(group: changes[record.id])
            : record,
    ];
  }
}
