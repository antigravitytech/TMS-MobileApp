part of 'workspace_record_widgets.dart';

String invoiceAmount(BuildContext context, int kobo) => NumberFormat.currency(
  locale: context.locale.toString(),
  symbol: '₦',
  decimalDigits: kobo % 100 == 0 ? 0 : 2,
).format(kobo / 100);

class WorkspacePaymentSummary extends StatelessWidget {
  const WorkspacePaymentSummary({
    super.key,
    required this.items,
    this.invoice = false,
  });
  final bool invoice;
  final List<WorkspaceRecord> items;

  @override
  Widget build(BuildContext context) {
    final amountText = invoice ? invoiceAmount : workspaceAmount;
    final total = items.fold(0, (sum, item) => sum + item.amount);
    final paid = items.fold(0, (sum, item) => sum + item.paid);
    final ratio = total == 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);
    final outstanding = items.fold<int>(0, (sum, r) => sum + r.outstanding);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xff262a60), Color(0xff1b1e45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('studio.received'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        amountText(context, paid),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        invoice
                            ? context.tr(
                                'invoices.billed',
                                namedArgs: {
                                  'amount': amountText(context, total),
                                },
                              )
                            : context.tr(
                                'workspaces.paid_of_total',
                                namedArgs: {
                                  'paid': amountText(context, paid),
                                  'total': amountText(context, total),
                                },
                              ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox.square(
                  dimension: invoice ? 84 : 58,
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: DesignMotion.duration(
                          context,
                          DesignMotion.object,
                        ),
                        builder: (_, v, _) => CircularProgressIndicator(
                          value: v,
                          strokeWidth: invoice ? 9 : 6,
                          color: DesignColor.teal,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      Center(
                        child: Text(
                          NumberFormat.percentPattern(
                            context.locale.toString(),
                          ).format(ratio),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!invoice) const Divider(color: Colors.white12, height: 1),
            if (invoice)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (label, value, color) in [
                    (
                      'invoices.outstanding',
                      amountText(context, outstanding),
                      Colors.white,
                    ),
                    (
                      'workspaces.overdue',
                      amountText(
                        context,
                        items
                            .where(
                              (r) =>
                                  r.outstanding > 0 &&
                                  r.date != null &&
                                  DateUtils.dateOnly(r.date!).isBefore(
                                    DateUtils.dateOnly(DateTime.now()),
                                  ),
                            )
                            .fold<int>(0, (sum, r) => sum + r.outstanding),
                      ),
                      DesignColor.rose,
                    ),
                    (
                      'workspaces.paid_in_full',
                      NumberFormat.decimalPattern(
                        context.locale.toString(),
                      ).format(items.where((r) => r.outstanding == 0).length),
                      Colors.white,
                    ),
                  ])
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .06),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .08),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(label),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: 14,
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            else
              Text(
                context.tr(
                  'workspaces.balance_amount',
                  namedArgs: {'amount': amountText(context, outstanding)},
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
