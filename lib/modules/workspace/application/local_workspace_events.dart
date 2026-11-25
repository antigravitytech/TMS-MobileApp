part of 'local_workspaces.dart';

extension WorkspaceEventActions on LocalWorkspaces {
  Future<void> startProgrammeItem(String workspaceId, String id) =>
      _updateWorkspace(workspaceId, (workspace) {
        final entries = workspace.items(WorkspaceSection.programme).toList()
          ..sort((a, b) => a.date!.compareTo(b.date!));
        final current = entries.indexWhere((r) => r.id == id);
        if (current < 0) throw StateError('Unknown programme item');
        final stages = {
          for (final (i, r) in entries.indexed)
            r.id: i < current
                ? WorkspaceStatus.done
                : i == current
                ? WorkspaceStatus.inProgress
                : WorkspaceStatus.todo,
        };
        return workspace.copyWith(
          records: [
            for (final r in workspace.records)
              stages.containsKey(r.id) ? r.copyWith(status: stages[r.id]) : r,
          ],
        );
      });

  Future<void> lineUpProgramme(String workspaceId, DateTime start) =>
      _updateWorkspace(workspaceId, (workspace) {
        final entries = workspace.items(WorkspaceSection.programme).toList()
          ..sort((a, b) => a.date!.compareTo(b.date!));
        var cursor = start;
        final times = <String, DateTime>{};
        for (final item in entries) {
          times[item.id] = cursor;
          cursor = cursor.add(Duration(minutes: item.duration));
        }
        return workspace.copyWith(
          records: [
            for (final r in workspace.records)
              times.containsKey(r.id) ? r.copyWith(date: times[r.id]) : r,
          ],
        );
      });

  Future<void> respondToInvite(
    String workspaceId,
    String guestId,
    WorkspaceStatus status,
  ) => _updateWorkspace(workspaceId, (w) {
    final guest = w
        .items(WorkspaceSection.guests)
        .firstWhere((r) => r.id == guestId);
    final reserved =
        status == WorkspaceStatus.confirmed || status == WorkspaceStatus.maybe;
    final changed = guest.copyWith(
      status: status,
      flagged: status == WorkspaceStatus.confirmed && guest.flagged,
      group: reserved && w.canSeat(guest.group, guest) ? guest.group : '',
    );
    return w.copyWith(
      records: [for (final r in w.records) r.id == guestId ? changed : r],
    );
  });

  Future<void> autoSeatGuests(String id) =>
      _updateWorkspace(id, (w) => w.copyWith(records: w.autoSeat()));
  Future<void> seatGuest(String id, String guestId, String table) =>
      _updateWorkspace(id, (w) {
        final guest = w.arrivingGuests.firstWhere((g) => g.id == guestId);
        if (!w.canSeat(table, guest)) {
          throw StateError('Table capacity exceeded');
        }
        return w.copyWith(
          records: [
            for (final r in w.records)
              r.id == guestId ? r.copyWith(group: table) : r,
          ],
        );
      });
  Future<void> removeTable(String id, String tableId) =>
      _updateWorkspace(id, (w) {
        final table = w
            .items(WorkspaceSection.seating)
            .firstWhere((r) => r.id == tableId);
        return w.copyWith(
          records: [
            for (final r in w.records)
              if (r.id != tableId)
                r.section == WorkspaceSection.guests && r.group == table.title
                    ? r.copyWith(group: '')
                    : r,
          ],
        );
      });

  Future<void> importGuests(String workspaceId, List<WorkspaceRecord> guests) =>
      _update((directory) {
        var next = directory.nextId;
        final updated = _replaceWorkspace(directory, workspaceId, (workspace) {
          if (workspace.kind != WorkspaceKind.event) {
            throw StateError('Guest list unavailable');
          }
          return workspace.copyWith(
            records: [
              ...workspace.records,
              for (final guest in guests)
                guest.copyWith(id: 'record-${next++}'),
            ],
          );
        });
        return updated.copyWith(nextId: next);
      });
}
