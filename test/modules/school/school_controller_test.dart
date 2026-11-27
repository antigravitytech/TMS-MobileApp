import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/family/data/family_reference.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/school/application/school_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'school filters, completion, review points and additions persist',
    () async {
      SharedPreferences.setMockInitialValues({});
      await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
        WorkspaceDirectory(activeId: 'family', workspaces: [familyReference()]),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(localWorkspacesProvider.future);
      final subscription = container.listen(
        schoolControllerProvider('family'),
        (_, _) {},
      );
      addTearDown(subscription.close);
      final school = container.read(schoolControllerProvider('family'));
      school.select('Ada');
      expect(school.visible.where((r) => r.group == 'wk').length, 4);
      expect(school.visible.where((r) => r.group == 'od'), isEmpty);
      school.select('Tobi');
      expect(school.visible.where((r) => r.group == 'wk').length, 3);
      final overdue = school.visible.firstWhere((r) => r.id == '1');
      expect(await school.toggle(overdue), isTrue);
      expect(school.visible.firstWhere((r) => r.id == '1').done, isTrue);
      expect(await school.review(true), isTrue);
      expect(school.checked, isTrue);
      expect(
        container
            .read(localWorkspacesProvider)
            .requireValue
            .active!
            .availablePoints('Tobi'),
        155,
      );
      expect(await school.add('form', 'Permission slip'), isTrue);
      final added = school.items.first;
      expect(added.title, 'Permission slip');
      expect(await school.toggle(added), isTrue);
      container.invalidate(schoolControllerProvider('family'));
      final restored = container.read(schoolControllerProvider('family'));
      expect(restored.items.firstWhere((r) => r.id == '1').done, isTrue);
      expect(
        restored.items.firstWhere((r) => r.title == 'Permission slip').done,
        isTrue,
      );
      expect(restored.checked, isTrue);
    },
  );
}
