import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/individual/application/new_invoice.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_demo.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new invoice picks clients, prices time and numbers itself', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
      WorkspaceDirectory(
        activeId: 'individual',
        workspaces: [demoWorkspace(WorkspaceKind.individual, DateTime.now())],
      ),
    );
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(localWorkspacesProvider.future);
    final invoices = c.read(newInvoiceProvider('individual'));

    expect(invoices.clients, [
      'KD Squares',
      'Nexora Properties',
      'Unique Engineering',
    ]);
    // 390 billable minutes at ₦15,000 an hour.
    expect(invoices.fromTime, 9750000);
    expect(invoices.nextNumber, 'INV-207');
    expect(await invoices.create('Nexora Properties', 0), isNull);
    expect(await invoices.create('Nexora Properties', 9750000), 'INV-207');

    final saved = c
        .read(localWorkspacesProvider)
        .value!
        .workspaces
        .single
        .items(WorkspaceSection.invoices)
        .firstWhere((i) => i.title == 'INV-207');
    expect(
      (saved.person, saved.amount, saved.paid),
      ('Nexora Properties', 9750000, 0),
    );
  });
}
