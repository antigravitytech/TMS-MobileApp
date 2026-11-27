import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_repository.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'workspace records stay isolated and reload from local storage',
    () async {
      final container = ProviderContainer(
        overrides: [
          workspaceRepositoryProvider.overrideWithValue(
            const LiveWorkspaceRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final initial = await container.read(localWorkspacesProvider.future);
      expect(initial.active, isNull);
      expect(
        initial.workspaces.map((item) => item.kind),
        WorkspaceKind.values.skip(1),
      );

      final controller = container.read(localWorkspacesProvider.notifier);
      await controller.select(WorkspaceKind.individual.name);
      await controller.saveRecord(
        WorkspaceKind.individual.name,
        const WorkspaceRecord(
          id: '',
          section: WorkspaceSection.clients,
          title: 'Client A',
        ),
      );
      await controller.create(
        WorkspaceKind.individual,
        'Second client workspace',
      );
      expect(
        container.read(localWorkspacesProvider).requireValue.active!.records,
        isEmpty,
      );

      final reloaded = ProviderContainer(
        overrides: [
          workspaceRepositoryProvider.overrideWithValue(
            const LiveWorkspaceRepository(),
          ),
        ],
      );
      addTearDown(reloaded.dispose);
      final directory = await reloaded.read(localWorkspacesProvider.future);
      expect(directory.active!.name, 'Second client workspace');
      expect(directory.active!.records, isEmpty);

      await reloaded
          .read(localWorkspacesProvider.notifier)
          .select(WorkspaceKind.individual.name);
      final first = reloaded.read(localWorkspacesProvider).requireValue.active!;
      expect(first.items(WorkspaceSection.clients).single.title, 'Client A');
      expect(first.kind.sections, isNot(contains(WorkspaceSection.chores)));
    },
  );

  test(
    'overlapping payment writes respect the remaining invoice balance',
    () async {
      final container = ProviderContainer(
        overrides: [
          workspaceRepositoryProvider.overrideWithValue(
            const LiveWorkspaceRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(localWorkspacesProvider.future);
      final controller = container.read(localWorkspacesProvider.notifier);
      const workspaceId = 'individual';
      await controller.select(workspaceId);
      await controller.saveRecord(
        workspaceId,
        const WorkspaceRecord(
          id: '',
          section: WorkspaceSection.invoices,
          title: 'INV-100',
          amount: 10000,
          invoiceLines: [InvoiceLine('Work', 2, 5000)],
        ),
      );
      final id = container
          .read(localWorkspacesProvider)
          .requireValue
          .active!
          .records
          .single
          .id;
      final first = controller.recordPayment(workspaceId, id, 6000);
      final overpayment = expectLater(
        controller.recordPayment(workspaceId, id, 6000),
        throwsStateError,
      );
      await first;
      await overpayment;
      await controller.recordPayment(workspaceId, id, 4000);

      final invoice = container
          .read(localWorkspacesProvider)
          .requireValue
          .active!
          .records
          .single;
      expect(invoice.outstanding, 0);
      expect(invoice.invoiceLines.single.total, invoice.amount);
    },
  );
  test(
    'demo setup, shared assignments and redemption survive switching',
    () async {
      final container = ProviderContainer(
        overrides: [
          workspaceRepositoryProvider.overrideWithValue(
            const LiveWorkspaceRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(localWorkspacesProvider.notifier);
      await controller.enterDemo('family');
      LocalWorkspace active() =>
          container.read(localWorkspacesProvider).requireValue.active!;
      final reward = active().items(WorkspaceSection.rewards).first;
      await controller.saveRecord(
        'family',
        const WorkspaceRecord(
          id: '',
          section: WorkspaceSection.chores,
          title: 'Clear table',
          person: 'Tomi',
          points: 5,
          status: WorkspaceStatus.done,
        ),
        alsoAssignTo: {'Sam', 'Tomi'},
      );
      expect(
        active()
            .items(WorkspaceSection.chores)
            .where((r) => r.title == 'Clear table')
            .length,
        2,
      );
      await controller.redeemReward('family', reward.id, 'Tomi');
      expect(active().availablePoints('Tomi'), 0);
      await expectLater(
        controller.redeemReward('family', reward.id, 'Tomi'),
        throwsStateError,
      );
      await controller.enterDemo('estate');
      expect(active().kind, WorkspaceKind.estate);
      await controller.enterDemo('family');
      expect(active().availablePoints('Tomi'), 0);
      expect(active().availablePoints('Sam'), 5);
    },
  );

  test('seating keeps a party together and refuses a full table', () async {
    final container = ProviderContainer(
      overrides: [
        workspaceRepositoryProvider.overrideWithValue(
          const LiveWorkspaceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final ctrl = container.read(localWorkspacesProvider.notifier);
    await ctrl.select('event');
    await ctrl.saveRecord(
      'event',
      const WorkspaceRecord(
        id: '',
        section: WorkspaceSection.seating,
        title: 'Garden',
        duration: 3,
      ),
    );
    for (final title in ['A', 'B']) {
      await ctrl.saveRecord(
        'event',
        WorkspaceRecord(
          id: '',
          section: WorkspaceSection.guests,
          title: title,
          duration: 2,
          status: WorkspaceStatus.confirmed,
        ),
      );
    }
    await ctrl.autoSeatGuests('event');
    LocalWorkspace active() =>
        container.read(localWorkspacesProvider).requireValue.active!;
    final guests = active().items(WorkspaceSection.guests);
    expect(guests.where((r) => r.group == 'Garden'), hasLength(1));
    final unassigned = guests.firstWhere((r) => r.group.isEmpty);
    await expectLater(
      ctrl.seatGuest('event', unassigned.id, 'Garden'),
      throwsStateError,
    );
  });

  test(
    'pledge payments cannot exceed a pledge but gifts may exceed a fund target',
    () async {
      final container = ProviderContainer(
        overrides: [
          workspaceRepositoryProvider.overrideWithValue(
            const LiveWorkspaceRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final ctrl = container.read(localWorkspacesProvider.notifier);
      await ctrl.select('church');
      await ctrl.saveRecord(
        'church',
        const WorkspaceRecord(
          id: '',
          section: WorkspaceSection.giving,
          title: 'Hall repairs',
          amount: 5000,
        ),
      );
      WorkspaceRecord fund() => container
          .read(localWorkspacesProvider)
          .requireValue
          .active!
          .records
          .single;
      final id = fund().id, date = DateTime(2026, 10, 15);
      await ctrl.addEntry(
        'church',
        id,
        WorkspaceEntry(
          kind: EntryKind.pledge,
          date: date,
          amount: 7000,
          name: 'Member A',
        ),
      );
      final payment = WorkspaceEntry(
        kind: EntryKind.payment,
        date: date,
        amount: 7000,
        pledgeIndex: 0,
      );
      await ctrl.addEntry('church', id, payment);
      await expectLater(ctrl.addEntry('church', id, payment), throwsStateError);
      await ctrl.saveRecord(
        'church',
        WorkspaceRecord(
          id: id,
          section: WorkspaceSection.giving,
          title: 'Repair fund',
          amount: 5000,
        ),
      );
      expect(fund().pledgeBalance(0), 0);
      expect(fund().paid, 7000);
      expect(fund().entries, hasLength(2));
    },
  );
}
