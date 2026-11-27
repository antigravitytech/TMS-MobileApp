import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../specials/presentation/widgets/special_hero.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit.dart';
import '../../../shared/kit/kit_visuals.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../application/bills_controller.dart';
import 'widgets/bill_add_sheet.dart';
import 'widgets/bills_widgets.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key, required this.workspace});
  final LocalWorkspace workspace;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final id = workspace.id;
    final state = ref.watch(billsControllerProvider(id));
    final actions = ref.read(billsControllerProvider(id).notifier);
    final sum = ref.watch(billsSummaryProvider(id));
    final share = sum.total == 0 ? 0.0 : sum.paid / sum.total;
    final visible = sum.bills.where(
      (b) => switch (state.filter) {
        BillFilter.all => true,
        BillFilter.open => !b.settled,
        BillFilter.paid => b.settled,
      },
    );
    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.family,
        active: TmsRoute.home,
        badges: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitHeader(
              title: c.tr('bills.title'),
              subtitle: c.tr('bills.subtitle'),
              back: c.tr('common.back'),
              action: KitIconButton(
                primary: true,
                icon: TmsIcons.add,
                tooltip: c.tr('bills.add'),
                onPressed: () => showBillAdd(c, id),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                children: [
                  DesignEntrance(
                    child: SpecialMoneyHero(
                      label: c.tr('bills.paid_so_far'),
                      amount: naira(c, sum.paid),
                      sub: c.tr(
                        'bills.of_total',
                        namedArgs: {'amount': naira(c, sum.total)},
                      ),
                      ratio: share,
                      trio: [
                        (
                          c.tr('bills.trio.outstanding'),
                          naira(c, sum.outstanding),
                        ),
                        (
                          c.tr('bills.trio.due_week'),
                          naira(c, sum.dueThisWeek),
                        ),
                        (c.tr('bills.trio.count'), '${sum.bills.length}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  KitTabs(
                    padding: 0,
                    children: [
                      for (final f in BillFilter.values)
                        KitChip(
                          label: c.tr('bills.filters.${f.name}'),
                          selected: state.filter == f,
                          onTap: () => actions.filter(f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  KitList(
                    key: ValueKey(state.filter),
                    children: [
                      for (final bill in visible)
                        BillRow(
                          key: ValueKey(bill.id),
                          bill: bill,
                          onPay: () => showBillPayment(c, id, bill, actions),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
