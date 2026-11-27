import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/bills/application/bills_controller.dart';
import 'package:sabi_pipu_tms/modules/chores/application/chores_controller.dart';
import 'package:sabi_pipu_tms/modules/rewards/application/rewards_controller.dart';
import 'package:sabi_pipu_tms/modules/shopping/application/shopping_controller.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/family/data/family_reference.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
      WorkspaceDirectory(activeId: 'family', workspaces: [familyReference()]),
    );
    container = ProviderContainer();
    await container.read(localWorkspacesProvider.future);
  });
  tearDown(() => container.dispose());

  T keep<T>(ProviderListenable<T> p) {
    final sub = container.listen(p, (_, _) {});
    addTearDown(sub.close);
    return sub.read();
  }

  test('chores hide the ledger and finished chores earn points', () async {
    final chores = keep(choreItemsProvider('family'));
    expect(
      chores.map((c) => c.title),
      contains('Wash the plates after dinner'),
    );
    expect(chores.where((c) => c.fields['ledger'] == 'true'), isEmpty);
    expect(keep(familyPointsProvider(('family', 'Tobi'))), 140);
    keep(choresControllerProvider('family'));
    final plates = chores.firstWhere(
      (c) => c.points == 10 && c.person == 'Tobi',
    );
    expect(
      await container
          .read(choresControllerProvider('family').notifier)
          .toggle(plates),
      isTrue,
    );
    expect(container.read(familyPointsProvider(('family', 'Tobi'))), 150);
  });

  test('a new chore goes to the chosen person with stepped points', () async {
    keep(choresControllerProvider('family'));
    final c = container.read(choresControllerProvider('family').notifier);
    c.pickWho('Kwame');
    expect(container.read(choresControllerProvider('family')).draft.points, 0);
    c.pickWho('Ada');
    c.stepPoints(5);
    expect(await c.add('', 'Sweep the compound'), 'Ada');
    final first = keep(choreItemsProvider('family')).first;
    expect(
      (first.title, first.person, first.points),
      ('Sweep the compound', 'Ada', 15),
    );
  });

  test('bills summarise the term and record a half payment', () async {
    final sum = keep(billsSummaryProvider('family'));
    expect(sum.bills.length, 4);
    expect(sum.total, 77900000);
    expect(sum.paid, 36900000);
    keep(billsControllerProvider('family'));
    final c = container.read(billsControllerProvider('family').notifier);
    final estate = sum.bills.firstWhere((b) => b.billName.startsWith('Estate'));
    expect(estate.share(BillShare.half), 3000000);
    expect(await c.payKobo(estate, estate.share(BillShare.half)), isTrue);
    final after = container.read(billsSummaryProvider('family'));
    expect(after.paid, 39900000);
  });

  test('rewards rank the household and spend the child points', () async {
    final view = keep(rewardsViewProvider('family'));
    expect(view.people.take(3).map((p) => p.name), ['Tobi', 'Ada', 'Bisi']);
    expect(view.people[1].points, 40);
    keep(rewardsControllerProvider('family'));
    final c = container.read(rewardsControllerProvider('family').notifier);
    expect(c.cheer('Ada'), isTrue);
    expect(c.cheer('Ada'), isFalse);
    final screen = view.rewards.firstWhere((r) => r.points == 50);
    expect(await c.give(screen), isTrue);
    expect(container.read(rewardsViewProvider('family')).childPoints, 90);
  });

  test('shopping moves items between to buy, cart and bought', () async {
    final items = keep(shoppingItemsProvider('family'));
    expect(items.where(ShoppingFilter.got.matches).map((i) => i.title), [
      'Bread',
    ]);
    keep(shoppingControllerProvider('family'));
    final c = container.read(shoppingControllerProvider('family').notifier);
    await c.toggleCart(items.first);
    expect(
      container.read(shoppingItemsProvider('family')).first.status,
      WorkspaceStatus.inProgress,
    );
    expect(await c.add('Garri'), isTrue);
    expect(
      container.read(shoppingItemsProvider('family')).first.title,
      'Garri',
    );
  });
}
