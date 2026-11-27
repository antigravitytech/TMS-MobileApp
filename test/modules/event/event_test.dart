import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/event/application/event_controller.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_demo.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer c;
  const args = ('event', EventTab.overview);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
      WorkspaceDirectory(
        activeId: 'event',
        workspaces: [demoWorkspace(WorkspaceKind.event, DateTime.now())],
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

  EventView view() => c.read(eventViewProvider('event'))!;
  EventController actions() => c.read(eventControllerProvider(args).notifier);

  test('overview reads the wedding', () {
    final v = keep(eventViewProvider('event'))!;
    expect(v.space.name, 'Chinwe & Dayo’s Wedding');
    expect((v.seatsConfirmed, v.awaiting, v.space.eventCapacity), (8, 3, 300));
    expect((v.committed, v.paid), (490000000, 287500000));
    expect(v.dueSoon.map((d) => d.title).first, 'Mama Tolu’s Kitchen');
    expect(
      (v.seated, v.capacity, v.unseated.single.title),
      (8, 46, 'Dayo Coker'),
    );
  });

  test('check-in, seating and vendor payments update the wedding', () async {
    keep(eventViewProvider('event'));
    keep(eventControllerProvider(args));
    final ifeoma = view().guests.firstWhere((g) => g.title == 'Ifeoma Nwosu');
    await actions().toggleCheckIn(ifeoma);
    expect(view().checkedIn, 1);

    final dayo = view().unseated.single;
    actions().pickGuest(dayo.id);
    expect(await actions().seatPicked('Table 3'), isTrue);
    expect(view().seatedAt('Table 3'), 3);
    expect(view().unseated, isEmpty);

    final dj = view().vendors.firstWhere((v) => v.title.startsWith('DJ'));
    expect(await actions().payVendor(dj), 10000000);
    expect(view().paid, 297500000);
  });
}
