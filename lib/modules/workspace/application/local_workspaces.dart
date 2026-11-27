import '../domain/workspace_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local_workspace_store.dart';
import '../data/workspace_repository.dart';
import '../data/workspace_demo.dart';
import '../data/reference_refresh.dart';
import '../domain/local_workspace.dart';
import '../domain/event_seating.dart';
import '../domain/workspace_kind.dart';
import '../domain/workspace_setup.dart';

part 'local_workspace_events.dart';

final localWorkspacesProvider =
    AsyncNotifierProvider<LocalWorkspaces, WorkspaceDirectory>(
      LocalWorkspaces.new,
    );

class LocalWorkspaces extends AsyncNotifier<WorkspaceDirectory> {
  late LocalWorkspaceStore _store;
  Future<void> _pendingWrite = Future.value();

  @override
  Future<WorkspaceDirectory> build() async {
    _store = LocalWorkspaceStore(await SharedPreferences.getInstance());
    var directory = _store.load();
    final preferences = await SharedPreferences.getInstance();
    for (final (flag, refresh) in referenceRefreshes) {
      if (!_store.hasSavedDirectory || preferences.containsKey(flag)) continue;
      directory = refresh(directory, DateTime.now());
      await _store.save(directory);
      await preferences.setBool(flag, true);
      break;
    }
    final prepared = _repository.prepare(directory, DateTime.now());
    if (!identical(prepared, directory)) await _store.save(prepared);
    return prepared;
  }

  WorkspaceRepository get _repository => ref.read(workspaceRepositoryProvider);

  Future<void> select(String id) => _update((directory) {
    if (id != WorkspaceDirectory.companyId &&
        !directory.workspaces.any((workspace) => workspace.id == id)) {
      throw StateError('Unknown workspace');
    }
    return directory.activeId == id
        ? directory
        : directory.copyWith(activeId: id);
  });

  Future<void> enterDemo(String id) => _update((directory) {
    if (id != WorkspaceDirectory.companyId &&
        !directory.workspaces.any((w) => w.id == id)) {
      throw StateError('Unknown workspace');
    }
    final now = DateTime.now();
    // Only populate a fresh installation. A later demo visit preserves edits and deletions.
    if (_store.hasSavedDirectory) return directory.copyWith(activeId: id);
    return directory.copyWith(
      activeId: id,
      workspaces: [
        for (final w in directory.workspaces) demoWorkspace(w.kind, now),
      ],
    );
  });

  Future<void> create(
    WorkspaceKind kind,
    String name, {
    WorkspaceSetup setup = const WorkspaceSetup(),
  }) => _update((directory) {
    if (kind == WorkspaceKind.business) {
      throw ArgumentError.value(
        kind,
        'kind',
        'Company uses the existing workspace',
      );
    }
    var nextId = directory.nextId;
    final id = 'workspace-${nextId++}';
    final members = [
      for (final member in setup.members)
        WorkspaceRecord(
          id: 'record-${nextId++}',
          section: WorkspaceSection.household,
          title: member.name,
          fields: {'householdRole': member.role.name},
        ),
    ];
    return directory.copyWith(
      activeId: id,
      nextId: nextId,
      workspaces: [
        ...directory.workspaces,
        _repository.fill(
          LocalWorkspace(
            id: id,
            kind: kind,
            name: name,
            crest: setup.crest,
            occupation: setup.occupation?.name ?? '',
            withClients: setup.withClients,
            occasion: setup.occasion,
            eventDate: setup.date,
            records: members,
          ),
          DateTime.now(),
        ),
      ],
    );
  });

  Future<void> saveRecord(
    String workspaceId,
    WorkspaceRecord record, {
    Iterable<String> alsoAssignTo = const [],
  }) => _update((directory) {
    final isNew = record.id.isEmpty;
    final item = isNew
        ? record.copyWith(id: 'record-${directory.nextId}')
        : record;
    var nextId = directory.nextId + (isNew ? 1 : 0);
    final next = _replaceWorkspace(directory, workspaceId, (workspace) {
      if (!workspace.kind.sections.contains(item.section)) {
        throw StateError('Section is unavailable for this workspace');
      }
      if (item.section == WorkspaceSection.guests &&
          (item.status == WorkspaceStatus.confirmed ||
              item.status == WorkspaceStatus.maybe) &&
          !workspace.canSeat(item.group, item)) {
        throw StateError('Table capacity exceeded');
      }
      if (item.section == WorkspaceSection.seating &&
          (workspace
                  .items(WorkspaceSection.seating)
                  .any(
                    (r) =>
                        r.id != item.id &&
                        r.title.toLowerCase() == item.title.toLowerCase(),
                  ) ||
              item.duration < workspace.seatsTaken(item.title))) {
        throw StateError('Invalid table');
      }
      final records = [...workspace.records];
      if (isNew) {
        records.add(item);
        if (item.section.view == WorkspaceView.review) {
          for (final person in alsoAssignTo.toSet().where(
            (s) => s.isNotEmpty && s != item.person,
          )) {
            records.add(
              item.copyWith(id: 'record-${nextId++}', person: person),
            );
          }
        }
      } else {
        final index = records.indexWhere((record) => record.id == item.id);
        if (index < 0 ||
            (item.section != WorkspaceSection.giving &&
                item.amount < records[index].paid)) {
          throw StateError('Record changed before edit was saved');
        }
        records[index] = item.copyWith(
          paid: records[index].paid,
          entries: records[index].entries,
        );
      }
      return workspace.copyWith(records: records);
    });
    return isNew ? next.copyWith(nextId: nextId) : next;
  });

  Future<void> redeemReward(
    String workspaceId,
    String rewardId,
    String person,
  ) => _updateWorkspace(workspaceId, (workspace) {
    final reward = workspace
        .items(WorkspaceSection.rewards)
        .firstWhere((r) => r.id == rewardId);
    if (reward.points < 1 ||
        workspace.availablePoints(person) < reward.points) {
      throw StateError('Insufficient points');
    }
    return workspace.copyWith(
      redeemedPoints: {
        ...workspace.redeemedPoints,
        person: (workspace.redeemedPoints[person] ?? 0) + reward.points,
      },
    );
  });

  Future<void> updateRecord(
    String workspaceId,
    String recordId,
    WorkspaceRecord Function(WorkspaceRecord) change,
  ) => _updateWorkspace(workspaceId, (workspace) {
    final records = [...workspace.records];
    final index = records.indexWhere((record) => record.id == recordId);
    if (index < 0) throw StateError('Unknown workspace record');
    records[index] = change(records[index]);
    return workspace.copyWith(records: records);
  });

  Future<void> addEntry(
    String workspaceId,
    String recordId,
    WorkspaceEntry entry,
  ) => updateRecord(workspaceId, recordId, (record) {
    if (entry.kind == EntryKind.payment) {
      if (record.section.view != WorkspaceView.money ||
          entry.amount <= 0 ||
          (record.section != WorkspaceSection.giving &&
              entry.amount > record.outstanding)) {
        throw StateError('Invalid payment');
      }
      final index = entry.pledgeIndex;
      if (index != null &&
          (index < 0 ||
              index >= record.entries.length ||
              record.entries[index].kind != EntryKind.pledge ||
              record.pledgeBalance(index) < entry.amount)) {
        throw StateError('Invalid pledge payment');
      }
      return record.copyWith(
        paid: record.paid + entry.amount,
        entries: [...record.entries, entry],
      );
    }
    if (entry.kind == EntryKind.pledge && entry.amount <= 0) {
      throw StateError('Invalid pledge');
    }
    return record.copyWith(entries: [...record.entries, entry]);
  });
  Future<void> recordPayment(String workspaceId, String recordId, int amount) =>
      addEntry(
        workspaceId,
        recordId,
        WorkspaceEntry(
          kind: EntryKind.payment,
          date: DateTime.now(),
          amount: amount,
        ),
      );

  Future<void> removeRecord(String workspaceId, String recordId) =>
      _updateWorkspace(
        workspaceId,
        (workspace) => workspace.copyWith(
          records: workspace.records
              .where((record) => record.id != recordId)
              .toList(),
        ),
      );

  Future<void> _updateWorkspace(
    String id,
    LocalWorkspace Function(LocalWorkspace) change,
  ) => _update((directory) => _replaceWorkspace(directory, id, change));

  WorkspaceDirectory _replaceWorkspace(
    WorkspaceDirectory directory,
    String id,
    LocalWorkspace Function(LocalWorkspace) change,
  ) {
    final index = directory.workspaces.indexWhere(
      (workspace) => workspace.id == id,
    );
    if (index < 0) throw StateError('Unknown workspace');
    final workspaces = [...directory.workspaces];
    final current = workspaces[index], updated = change(current);
    for (final person in updated.redeemedPoints.keys) {
      final available = updated.availablePoints(person);
      if (available < 0 && available < current.availablePoints(person)) {
        throw const PointsAlreadySpent();
      }
    }
    workspaces[index] = updated;
    return directory.copyWith(workspaces: workspaces);
  }

  Future<void> _update(WorkspaceDirectory Function(WorkspaceDirectory) change) {
    final write = _pendingWrite.then((_) async {
      final current = await future;
      final updated = change(current);
      if (identical(current, updated)) return;
      await _store.save(updated);
      if (ref.mounted) state = AsyncData(updated);
    });
    _pendingWrite = write.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return write;
  }
}
