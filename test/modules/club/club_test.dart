import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/club/application/club_controller.dart';
import 'package:sabi_pipu_tms/modules/specials/application/special_actions.dart';
import 'package:sabi_pipu_tms/modules/specials/presentation/widgets/special_meetings.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_demo.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer c;
  const args = ('club', ClubTab.overview);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
      WorkspaceDirectory(
        activeId: 'club',
        workspaces: [demoWorkspace(WorkspaceKind.club, DateTime.now())],
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

  ClubView view() => c.read(clubViewProvider('club'))!;

  test('overview reads Ikoyi Sunday League FC', () {
    final v = keep(clubViewProvider('club'))!;
    expect(v.space.name, 'Ikoyi Sunday League FC');
    expect(
      (v.members, v.collected, v.target, v.owing),
      (32, 15000000, 96000000, 2),
    );
    expect(v.upcoming.length, 3);
    expect(v.upcoming[1].tags, ['Bus leaves 2pm', 'Captain']);
    expect((v.marked(0), v.marked(1), v.marked(2)), (2, 1, 1));
    expect(v.notices.length, 1);
  });

  test('replies, fees and attendance change', () async {
    keep(clubViewProvider('club'));
    keep(clubControllerProvider(args));
    final actions = c.read(specialActionsProvider('club'));
    expect(await actions.reply(view().upcoming.first, 'in'), isTrue);
    expect(view().upcoming.first.fields['myReply'], 'in');

    final musa = view().fees.firstWhere((f) => f.title == 'Musa Bello');
    await actions.recordPayment(musa, kobo: musa.outstanding, method: 'cash');
    expect(view().owing, 1);

    final kenny = view().attendance.firstWhere((a) => a.title == 'Kenny Eze');
    expect(
      await c.read(clubControllerProvider(args).notifier).mark(kenny, 0),
      isTrue,
    );
    expect(view().marked(0), 3);
  });
}
