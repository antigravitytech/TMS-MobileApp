import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

const familyPlanTemplates = ['trip', 'bday', 'term', 'move', 'xmas', 'blank'];
const familyPlanStepCounts = [9, 8, 8, 7, 7, 3];
const familyPlanPeople = [
  'Ada',
  'Bisi',
  'Funmi',
  'Ibrahim',
  'Kwame',
  'Sule',
  'Tobi',
];
final familyPlanControllerProvider = ChangeNotifierProvider.autoDispose
    .family<FamilyPlanController, String>(
      (ref, id) => FamilyPlanController(
        id,
        ref.read(localWorkspacesProvider.notifier),
        () => ref
            .read(localWorkspacesProvider)
            .requireValue
            .workspaces
            .firstWhere((w) => w.id == id),
      ),
    );

class FamilyPlanController extends ChangeNotifier {
  FamilyPlanController(this.workspaceId, this.directory, this.current);
  final String workspaceId;
  final LocalWorkspaces directory;
  final LocalWorkspace Function() current;
  int template = 0, mode = 0;
  final members = <String>{'Ada', 'Funmi', 'Ibrahim', 'Tobi'};
  final omitted = <int>{};
  bool busy = false, disposed = false;
  WorkspaceRecord? get plan => current()
      .items(WorkspaceSection.plans)
      .where((r) => r.fields['familyPlan'] == 'true')
      .lastOrNull;
  void start(int value) {
    template = value;
    omitted.clear();
    notifyListeners();
  }

  void changeMode(int value) {
    mode = value;
    notifyListeners();
  }

  void toggleMember(String name) {
    if (!members.remove(name)) members.add(name);
    notifyListeners();
  }

  void toggleStep(int value) {
    if (!omitted.remove(value)) omitted.add(value);
    notifyListeners();
  }

  int get total => familyPlanStepCounts[template];
  int get kept => total - omitted.length;
  Future<bool> create(String title, List<String> steps) async {
    if (busy || kept == 0) return false;
    busy = true;
    notifyListeners();
    try {
      final people = familyPlanPeople.where(members.contains).toList();
      if (people.isEmpty) people.add('Ibrahim');
      final keptSteps = [
        for (var i = 0; i < steps.length; i++)
          if (!omitted.contains(i)) steps[i],
      ];
      await directory.saveRecord(
        workspaceId,
        WorkspaceRecord(
          id: plan?.id ?? '',
          section: WorkspaceSection.plans,
          title: title,
          fields: {
            'familyPlan': 'true',
            'mode': '$mode',
            for (var i = 0; i < keptSteps.length; i++)
              'owner$i': people[i % people.length],
          },
          todos: {for (final step in keptSteps) step: false},
        ),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      busy = false;
      if (!disposed) notifyListeners();
    }
  }

  Future<bool> toggleDone(String step) async {
    final record = plan;
    if (record == null || busy) return false;
    busy = true;
    try {
      await directory.updateRecord(
        workspaceId,
        record.id,
        (r) => r.copyWith(todos: {...r.todos, step: !(r.todos[step] ?? false)}),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      busy = false;
      if (!disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
