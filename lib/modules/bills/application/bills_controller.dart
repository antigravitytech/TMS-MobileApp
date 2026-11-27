import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

enum BillFilter { all, open, paid }

enum BillShare { full, half, fixed }

/// The prototype's fixed part-payment, in kobo (₦50,000).
const billFixedShare = 5000000;
const billMethods = ['transfer', 'cash', 'card'];

extension BillRecord on WorkspaceRecord {
  bool get settled => amount > 0 && paid >= amount;
  String get billName => fields['billName'] ?? title;

  DateTime? get dueOn => date ?? DateTime.tryParse(fields['dueOn'] ?? '');

  /// Kobo a [share] of the balance comes to.
  int share(BillShare share) => switch (share) {
    BillShare.full => outstanding,
    BillShare.half => (outstanding / 2).round(),
    BillShare.fixed =>
      outstanding < billFixedShare ? outstanding : billFixedShare,
  };
}

class BillsSummary {
  const BillsSummary(this.bills, this.total, this.paid, this.dueThisWeek);
  final List<WorkspaceRecord> bills;
  final int total, paid, dueThisWeek;
  int get outstanding => total - paid;
}

final billsSummaryProvider = Provider.autoDispose.family<BillsSummary, String>((
  ref,
  id,
) {
  final space = ref
      .watch(localWorkspacesProvider)
      .value
      ?.workspaces
      .where((w) => w.id == id)
      .firstOrNull;
  final bills =
      space
          ?.items(WorkspaceSection.bills)
          .where((r) => r.amount > 0)
          .toList() ??
      const <WorkspaceRecord>[];
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  final end = start.add(const Duration(days: 7));
  return BillsSummary(
    bills,
    bills.fold(0, (s, b) => s + b.amount),
    bills.fold(0, (s, b) => s + b.paid.clamp(0, b.amount)),
    bills
        .where((b) {
          final due = b.dueOn;
          return due != null && !due.isBefore(start) && due.isBefore(end);
        })
        .fold(0, (s, b) => s + b.outstanding),
  );
});

class BillsState {
  const BillsState({this.filter = BillFilter.all});
  final BillFilter filter;
}

final billsControllerProvider = NotifierProvider.autoDispose
    .family<BillsController, BillsState, String>(BillsController.new);

class BillsController extends Notifier<BillsState> {
  BillsController(this.workspaceId);
  final String workspaceId;

  @override
  BillsState build() => const BillsState();

  LocalWorkspaces get _directory => ref.read(localWorkspacesProvider.notifier);

  void filter(BillFilter value) => state = BillsState(filter: value);

  /// Records [kobo] against [bill]. Returns false when it failed.
  Future<bool> payKobo(WorkspaceRecord bill, int kobo) async {
    if (kobo <= 0) return false;
    try {
      await _directory.recordPayment(workspaceId, bill.id, kobo);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Adds a bill; blank fields use the prototype's examples.
  Future<bool> add({
    required String name,
    required String amount,
    required String due,
    required String fallbackName,
    required String fallbackDue,
  }) async {
    final naira = int.tryParse(amount.replaceAll(RegExp('[^0-9]'), ''));
    try {
      await _directory.saveRecord(
        workspaceId,
        WorkspaceRecord(
          id: '',
          section: WorkspaceSection.bills,
          title: name.trim().isEmpty ? fallbackName : name.trim(),
          amount: (naira == null || naira == 0 ? 15000 : naira) * 100,
          points: 0,
          fields: {
            'billKind': 'other',
            'dueText': due.trim().isEmpty ? fallbackDue : due.trim(),
          },
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
