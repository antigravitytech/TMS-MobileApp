import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/family/data/family_reference.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/family_plans/application/family_plan_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'plan creation keeps selected steps, assigns owners, and persists progress',
    () async {
      SharedPreferences.setMockInitialValues({});
      await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
        WorkspaceDirectory(activeId: 'family', workspaces: [familyReference()]),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(localWorkspacesProvider.future);
      final subscription = container.listen(
        familyPlanControllerProvider('family'),
        (_, _) {},
      );
      addTearDown(subscription.close);
      final d = container.read(familyPlanControllerProvider('family'));
      d.start(0);
      d.toggleStep(2);
      d.toggleStep(7);
      expect(d.kept, 7);
      final steps = List.generate(9, (i) => 'Step $i');
      expect(await d.create('Family trip', steps), isTrue);
      expect(d.plan!.todos.length, 7);
      expect(d.plan!.todos.containsKey('Step 2'), isFalse);
      expect(d.plan!.fields['owner0'], 'Ada');
      expect(d.plan!.fields['owner1'], 'Funmi');
      expect(d.plan!.fields['owner2'], 'Ibrahim');
      expect(d.plan!.fields['owner3'], 'Tobi');
      expect(await d.toggleDone('Step 5'), isTrue);
      expect(d.plan!.todos['Step 5'], isTrue);
      container.invalidate(familyPlanControllerProvider('family'));
      final restored = container.read(familyPlanControllerProvider('family'));
      expect(restored.plan!.todos['Step 5'], isTrue);
      restored.start(5);
      expect(restored.total, 3);
      for (var i = 0; i < 3; i++) {
        restored.toggleStep(i);
      }
      expect(
        await restored.create('Our plan', ['First', 'Second', 'Third']),
        isFalse,
      );
      restored.toggleStep(0);
      restored.changeMode(2);
      expect(
        await restored.create('Our plan', ['First', 'Second', 'Third']),
        isTrue,
      );
      expect(restored.plan!.title, 'Our plan');
      expect(restored.plan!.todos.keys, ['First']);
      expect(restored.plan!.fields['mode'], '2');
    },
  );
}
