import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/estate/application/estate_controller.dart';
import 'package:sabi_pipu_tms/modules/specials/application/special_actions.dart';
import 'package:sabi_pipu_tms/modules/specials/presentation/widgets/special_records.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_demo.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer c;
  const args = ('estate', EstateTab.overview);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
      WorkspaceDirectory(
        activeId: 'estate',
        workspaces: [demoWorkspace(WorkspaceKind.estate, DateTime.now())],
      ),
    );
    c = ProviderContainer();
    await c.read(localWorkspacesProvider.future);
  });
  tearDown(() => c.dispose());

  T keep<T>(ProviderListenable<T> p) {
    final sub = c.listen(p, (_, _) {});
    addTearDown(sub.close);
    return sub.read();
  }

  EstateView view() => c.read(estateViewProvider('estate'))!;
  EstateController actions() => c.read(estateControllerProvider(args).notifier);

  test('overview reads Palm Grove Estate', () {
    final v = keep(estateViewProvider('estate'))!;
    expect(v.space.name, 'Palm Grove Estate');
    expect(
      (v.houses, v.collected, v.target, v.owing),
      (64, 38000000, 360000000, 3),
    );
    expect(
      (v.upcomingPasses.length, v.openIssues, v.notices.length),
      (3, 2, 2),
    );
    expect(v.poll?.votes, [3, 1, 1]);
  });

  test('levies, passes and issues change', () async {
    keep(estateViewProvider('estate'));
    keep(estateControllerProvider(args));
    final bello = view().levies.firstWhere((l) => l.title.contains('Bello'));
    await c
        .read(specialActionsProvider('estate'))
        .recordPayment(bello, kobo: bello.outstanding, method: 'transfer');
    expect(view().owing, 2);

    final code = await actions().createPass('Mr Ade → House 2', 'tomorrow');
    expect(code, hasLength(4));
    expect(view().upcomingPasses.any((p) => p.code == code), isTrue);

    final motor = view().issues.firstWhere((i) => i.stage == 0);
    await c.read(specialActionsProvider('estate')).setStage(motor, 2);
    expect(view().openIssues, 1);
    expect(
      await c
          .read(specialActionsProvider('estate'))
          .addStaged(WorkspaceSection.issues, 'Water leak by Gate 2', 'you'),
      isTrue,
    );
    expect(view().openIssues, 2);
  });
}
