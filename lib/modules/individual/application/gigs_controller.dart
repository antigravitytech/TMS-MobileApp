import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Number of gig templates in the `studio.gigs.g{i}` catalog.
const gigTemplateCount = 10;

enum MilestoneState { done, late, upcoming }

/// Reads a gig record the way the Gigs screen shows it.
extension GigView on WorkspaceRecord {
  bool get atRisk => fields['health'] == 'risk';
  List<String> get milestones => todos.keys.toList();
  DateTime? milestoneDate(int i) => DateTime.tryParse(fields['m$i'] ?? '');

  MilestoneState milestoneState(int i) {
    final name = milestones[i];
    if (todos[name] == true) return MilestoneState.done;
    if (name == fields['next'] && atRisk) return MilestoneState.late;
    return MilestoneState.upcoming;
  }

  /// Share of milestones done, unless the record carries its own progress.
  double get tasksDone {
    final stored = int.tryParse(fields['progress'] ?? '');
    if (stored != null) return stored / 100;
    if (todos.isEmpty) return 0;
    return todos.values.where((d) => d).length / todos.length;
  }

  double get acceptedDelivery =>
      (int.tryParse(fields['accepted'] ?? '') ?? 0) / 100;
}

/// Running gigs, newest first.
final gigsProvider = Provider.autoDispose.family<List<WorkspaceRecord>, String>(
  (ref, id) {
    final space = ref
        .watch(localWorkspacesProvider)
        .value
        ?.workspaces
        .where((w) => w.id == id)
        .firstOrNull;
    final gigs =
        space
            ?.items(WorkspaceSection.gigs)
            .where((g) => g.status != WorkspaceStatus.done)
            .toList() ??
        const <WorkspaceRecord>[];
    return gigs.reversed.toList();
  },
);

final gigsControllerProvider = Provider.autoDispose
    .family<GigsController, String>((ref, id) => GigsController(ref, id));

class GigsController {
  GigsController(this._ref, this.workspaceId);
  final Ref _ref;
  final String workspaceId;
  LocalWorkspaces get _directory => _ref.read(localWorkspacesProvider.notifier);

  /// Starts a gig from a template. Milestones land this week, next week
  /// and in three weeks. Returns false when nothing was saved.
  Future<bool> start({
    required String name,
    required String description,
    required List<String> milestones,
    required String client,
  }) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    try {
      await _directory.saveRecord(
        workspaceId,
        WorkspaceRecord(
          id: '',
          section: WorkspaceSection.gigs,
          title: name,
          notes: description,
          person: client,
          points: 0,
          status: WorkspaceStatus.inProgress,
          fields: {
            'health': 'ontrack',
            'mode': 'simple',
            for (final (i, offset) in [3, 10, 21].indexed)
              'm$i': day.add(Duration(days: offset)).toIso8601String(),
          },
          todos: {for (final m in milestones) m: false},
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ticks or unticks a milestone. Returns false when saving failed.
  Future<bool> toggleMilestone(WorkspaceRecord gig, String milestone) async {
    try {
      await _directory.updateRecord(workspaceId, gig.id, (r) {
        final todos = {...r.todos, milestone: !(r.todos[milestone] ?? false)};
        final fields = {...r.fields}..remove('progress');
        return r.copyWith(todos: todos, fields: fields);
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
