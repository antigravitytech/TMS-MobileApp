import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/alumni/application/alumni_controller.dart';
import 'package:sabi_pipu_tms/modules/specials/application/special_actions.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_demo.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer c;
  const args = ('alumni', AlumniTab.overview);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
      WorkspaceDirectory(
        activeId: 'alumni',
        workspaces: [demoWorkspace(WorkspaceKind.alumni, DateTime.now())],
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

  AlumniView view() => c.read(alumniViewProvider('alumni'))!;
  AlumniController actions() => c.read(alumniControllerProvider(args).notifier);

  test('overview reads the Class of 2006', () {
    final v = keep(alumniViewProvider('alumni'))!;
    expect(v.space.name, 'Class of 2006 Reunion');
    expect((v.size, v.collected, v.target), (112, 65000000, 600000000));
    expect((v.owing.length, v.committees.length, v.openTodos), (3, 6, 9));
    expect(v.poll?.votes, [3, 1, 0]);
    expect((v.active, v.classmates.length), (3, 4));
  });

  test('dues, committees, the poll and the directory change', () async {
    keep(alumniViewProvider('alumni'));
    keep(alumniControllerProvider(args));
    final chinwe = view().dues.firstWhere((d) => d.title == 'Chinwe Eke');
    await c
        .read(specialActionsProvider('alumni'))
        .recordPayment(chinwe, kobo: chinwe.outstanding, method: 'cash');
    expect(view().owing.length, 2);

    final media = view().committees.firstWhere((k) => k.title == 'Media');
    await actions().takeLead(media, 'Chioma');
    await actions().toggleTodo(media, 'Photographer shortlist');
    final led = view().committees.firstWhere((k) => k.id == media.id);
    expect((led.person, led.todos['Photographer shortlist']), ('Chioma', true));

    await c.read(specialActionsProvider('alumni')).vote(view().poll!, 2);
    expect(view().poll!.votes, [3, 1, 1]);

    final bola = view().classmates.firstWhere((p) => p.title == 'Bola A.');
    await actions().setActivity(bola, 0);
    expect(view().active, 4);
  });
}
