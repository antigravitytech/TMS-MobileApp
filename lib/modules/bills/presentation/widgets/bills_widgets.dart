import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../../../shared/kit/payment_sheet.dart';
import '../../application/bills_controller.dart';

/// Naira from kobo, grouped for the active locale (e.g. ₦45,000).
String naira(BuildContext c, int kobo) => NumberFormat.currency(
  locale: c.locale.toString(),
  symbol: '₦',
  decimalDigits: 0,
).format(kobo / 100);

/// One `.bill` row: tile, name, due, status, paid bar and Pay.
class BillRow extends StatelessWidget {
  const BillRow({super.key, required this.bill, required this.onPay});
  final WorkspaceRecord bill;
  final VoidCallback onPay;
  @override
  Widget build(BuildContext c) {
    final (icon, color) = switch (bill.fields['billKind']) {
      'power' => (TmsIcons.power, DesignColor.amber),
      'school' => (TmsIcons.school, DesignColor.blue),
      'home' => (TmsIcons.home, DesignColor.teal),
      'tv' => (TmsIcons.monitor, null),
      _ => (TmsIcons.receipt, DesignColor.red),
    };
    final (status, tone) = bill.settled
        ? ('paid', KitColor.done)
        : bill.paid > 0
        ? ('part', KitColor.submitted)
        : ('unpaid', KitColor.overdue);
    final typed = bill.fields['dueText'];
    final due =
        bill.fields['due'] ??
        (typed == null ? '' : c.tr('bills.due_on', namedArgs: {'date': typed}));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            spacing: 12,
            children: [
              KitTile(icon, color: color, size: 42),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.billName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (due.isNotEmpty)
                      Text(due, style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
              KitStatus(c.tr('bills.status.$status'), tone),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: naira(c, bill.paid),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          children: [
                            TextSpan(
                              text: ' / ${naira(c, bill.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      KitBar(
                        value: bill.amount == 0 ? 0 : bill.paid / bill.amount,
                        color: KitColor.done,
                      ),
                    ],
                  ),
                ),
                if (!bill.settled)
                  KitMiniButton(
                    c.tr('bills.pay'),
                    primary: true,
                    onPressed: onPay,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Record a payment" for a bill, on the shared payment sheet.
Future<void> showBillPayment(
  BuildContext context,
  String workspaceId,
  WorkspaceRecord bill,
  BillsController actions,
) => showPaymentSheet(
  context,
  eyebrow: context.tr('bills.record'),
  title: bill.billName,
  balance: context.tr(
    'bills.balance',
    namedArgs: {'amount': naira(context, bill.outstanding)},
  ),
  shares: [
    for (final s in BillShare.values)
      (
        switch (s) {
          BillShare.full => context.tr(
            'bills.full',
            namedArgs: {'amount': naira(context, bill.outstanding)},
          ),
          BillShare.half => context.tr('bills.half'),
          BillShare.fixed => naira(context, billFixedShare),
        },
        bill.share(s),
      ),
  ],
  methods: billMethods,
  method: (m) => context.tr('bills.methods.$m'),
  amount: (kobo) => naira(context, kobo),
  onConfirm: (kobo, method) => actions.payKobo(bill, kobo),
  saved: (kobo) => context.tr(
    'bills.recorded',
    namedArgs: {'amount': naira(context, kobo), 'name': bill.billName},
  ),
);
