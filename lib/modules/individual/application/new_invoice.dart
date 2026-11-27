import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Creates invoices from the New invoice sheet: picks a client, prices it
/// from tracked time and numbers it after the last invoice.
final newInvoiceProvider = Provider.autoDispose.family<NewInvoice, String>(
  (ref, id) => NewInvoice(ref, id),
);

class NewInvoice {
  NewInvoice(this._ref, this.workspaceId);
  final Ref _ref;
  final String workspaceId;

  LocalWorkspace? get _space => _ref
      .read(localWorkspacesProvider)
      .value
      ?.workspaces
      .where((w) => w.id == workspaceId)
      .firstOrNull;

  /// Current clients (not past ones) A–Z, else anyone invoiced before.
  List<String> get clients {
    final space = _space;
    if (space == null) return const [];
    final saved = [
      for (final c in space.items(WorkspaceSection.clients))
        if (c.fields['stage'] != 'past' && c.title.trim().isNotEmpty) c.title,
    ]..sort();
    if (saved.isNotEmpty) return saved;
    return {
      for (final i in space.items(WorkspaceSection.invoices))
        if (i.person.trim().isNotEmpty) i.person,
    }.toList()..sort();
  }

  /// All billable time tracked, priced at the hourly rate, in kobo.
  int get fromTime {
    final space = _space;
    if (space == null) return 0;
    final minutes = space
        .items(WorkspaceSection.time)
        .where((t) => t.flagged)
        .fold(0, (s, t) => s + t.duration);
    return (minutes * space.hourlyRate / 60).round();
  }

  /// The next number after the highest `INV-###`.
  String get nextNumber {
    final last = (_space?.items(WorkspaceSection.invoices) ?? const [])
        .map((i) => int.tryParse(i.title.replaceAll(RegExp(r'\D'), '')) ?? 0)
        .fold(0, (a, b) => a > b ? a : b);
    return 'INV-${'${last + 1}'.padLeft(3, '0')}';
  }

  /// Saves an unpaid invoice due in two weeks. Returns its number, or null.
  Future<String?> create(String client, int kobo) async {
    if (client.trim().isEmpty || kobo <= 0) return null;
    final number = nextNumber;
    final now = DateTime.now();
    try {
      await _ref
          .read(localWorkspacesProvider.notifier)
          .saveRecord(
            workspaceId,
            WorkspaceRecord(
              id: '',
              section: WorkspaceSection.invoices,
              title: number,
              person: client,
              amount: kobo,
              date: DateTime(now.year, now.month, now.day + 14),
              points: 0,
              invoiceLines: [InvoiceLine(number, 1, kobo)],
            ),
          );
      return number;
    } catch (_) {
      return null;
    }
  }
}
