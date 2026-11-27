import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/church/application/church_controller.dart';
import 'package:sabi_pipu_tms/modules/specials/application/special_actions.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_demo.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer c;
  const args = ('church', ChurchTab.overview);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
      WorkspaceDirectory(
        activeId: 'church',
        workspaces: [demoWorkspace(WorkspaceKind.church, DateTime.now())],
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

  ChurchView view() => c.read(churchViewProvider('church'))!;
  ChurchController actions() => c.read(churchControllerProvider(args).notifier);

  test('overview reads the prototype congregation', () {
    final v = keep(churchViewProvider('church'))!;
    keep(churchControllerProvider(args));
    expect(v.space.name, 'Victory Chapel — Ikeja');
    expect(v.highlight?.title, 'Harvest thanksgiving');
    expect(
      (v.members, v.lastSunday, v.openPrayers, v.notCalled),
      (260, 549, 5, 1),
    );
    expect(v.givingTotal, 257200000);
    expect(v.recentGifts.first.$2.name, 'Ibrahim Musa');
  });

  test('attendance and giving are saved on their records', () async {
    keep(churchViewProvider('church'));
    keep(churchControllerProvider(args));
    final service = view().nextService!;
    expect(service.title, 'Midweek Bible study');
    await actions().saveAttendance(service, {
      'men': 40,
      'women': 70,
      'children': 5,
      'online': 31,
    });
    expect(view().trend.last.field('attendance'), 146);
    final welfare = view().funds.firstWhere((f) => f.title == 'Welfare');
    await actions().recordGift(
      welfare,
      kobo: 2000000,
      method: 'cash',
      giver: '',
    );
    expect(view().funds.firstWhere((f) => f.title == 'Welfare').paid, 6500000);
    expect(view().recentGifts.first.$2.name, '');
  });

  test('prayer, first-timers and notices move forward', () async {
    keep(churchViewProvider('church'));
    keep(churchControllerProvider(args));
    actions().toggleHideName();
    expect(await actions().sharePrayer('Safe delivery', 'Chioma'), isTrue);
    final mine = view().prayers.firstWhere((p) => p.title == 'Safe delivery');
    expect((mine.person, mine.flag('anonymous')), ('', true));
    expect(await actions().togglePraying(mine), isTrue);
    expect(
      view().prayers.firstWhere((p) => p.id == mine.id).field('praying'),
      1,
    );
    await actions().markAnswered(mine);
    expect(view().answeredPrayers, 1);

    final daniel = view().firstTimers.firstWhere((f) => f.stage == 0);
    await actions().advance(daniel, 'Chioma');
    final called = view().firstTimers.firstWhere((f) => f.id == daniel.id);
    expect((called.stage, called.fields['followsUp']), (1, 'Chioma'));

    expect(
      await c
          .read(specialActionsProvider('church'))
          .postNotice('Choir in white'),
      isTrue,
    );
    expect(view().notices.first.title, 'Choir in white');
  });
}
