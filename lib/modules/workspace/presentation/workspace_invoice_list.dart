import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/tms_icons.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import 'workspace_record_widgets.dart';
import 'workspace_ui.dart';

enum _InvoiceFilter { all, owing, overdue, paid }

bool _overdue(WorkspaceRecord r, DateTime today) =>
    r.outstanding > 0 &&
    r.date != null &&
    DateUtils.dateOnly(r.date!).isBefore(today);

class WorkspaceInvoiceList extends StatefulWidget {
  const WorkspaceInvoiceList({
    super.key,
    required this.workspace,
    required this.records,
    required this.navigation,
    required this.create,
    required this.open,
    required this.payment,
  });
  final LocalWorkspace workspace;
  final List<WorkspaceRecord> records;
  final Widget navigation;
  final VoidCallback create;
  final ValueChanged<WorkspaceRecord> open, payment;
  @override
  State<WorkspaceInvoiceList> createState() => _WorkspaceInvoiceListState();
}

class _WorkspaceInvoiceListState extends State<WorkspaceInvoiceList> {
  _InvoiceFilter filter = _InvoiceFilter.all;
  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final visible = widget.records
        .where(
          (r) => switch (filter) {
            _InvoiceFilter.all => true,
            _InvoiceFilter.owing => r.outstanding > 0,
            _InvoiceFilter.paid => r.outstanding == 0,
            _InvoiceFilter.overdue => _overdue(r, today),
          },
        )
        .toList();
    final section = WorkspaceSection.invoices;
    return DesignPage(
      headerTop: 58,
      title: section.label(context),
      subtitle: workspaceName(context, widget.workspace),
      tab: TmsRoute.workspacePlan,
      navigation: widget.navigation,
      actions: [
        IconButton.filled(
          tooltip: section.addLabel(context),
          style: IconButton.styleFrom(
            backgroundColor: DesignColor.purple,
            foregroundColor: DesignColor.ink,
            minimumSize: const Size.square(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: widget.create,
          icon: const Icon(TmsIcons.add),
        ),
      ],
      children: [
        WorkspacePaymentSummary(items: widget.records, invoice: true),
        DesignChoices(
          items: [
            context.tr('common.all'),
            context.tr('invoices.owing'),
            context.tr('workspaces.overdue'),
            context.tr('invoices.paid'),
          ],
          selected: filter.index,
          onChanged: (i) => setState(() => filter = _InvoiceFilter.values[i]),
        ),
        if (visible.isNotEmpty)
          DesignSection(
            children: [
              for (final record in visible)
                _InvoiceRow(
                  key: ValueKey(record.id),
                  record: record,
                  overdue: _overdue(record, today),
                  open: () => widget.open(record),
                  payment: () => widget.payment(record),
                ),
            ],
          )
        else if (widget.records.isEmpty) ...[
          DesignLabel(context.tr('workspaces.sections.invoices.empty')),
          DesignButton(
            section.addLabel(context),
            icon: TmsIcons.add,
            onPressed: widget.create,
          ),
        ] else
          DesignLabel(context.tr('invoices.none')),
      ],
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    super.key,
    required this.record,
    required this.overdue,
    required this.open,
    required this.payment,
  });
  final WorkspaceRecord record;
  final bool overdue;
  final VoidCallback open, payment;
  @override
  Widget build(BuildContext context) {
    final short = TextStyle(fontSize: 12, color: context.muted);
    final due = record.date;
    final color = record.outstanding == 0
        ? DesignColor.green
        : overdue
        ? DesignColor.rose
        : DesignColor.amber;
    final status = record.outstanding == 0
        ? 'invoices.paid'
        : overdue
        ? 'workspaces.overdue'
        : record.paid > 0
        ? 'invoices.part'
        : 'invoices.owing';
    final ratio = record.amount == 0
        ? 0.0
        : (record.paid / record.amount).clamp(0.0, 1.0);
    return InkWell(
      onTap: open,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: short.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: .4,
                        ),
                      ),
                      if (record.person.isNotEmpty)
                        Text(
                          record.person,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 4,
                  children: [
                    Text(
                      invoiceAmount(context, record.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        context.tr(status),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Text(
                        [
                          if (due != null)
                            context.tr(
                              'invoices.due',
                              namedArgs: {
                                'date': DateFormat.MMMEd(
                                  context.locale.toString(),
                                ).format(due),
                              },
                            ),
                          context.tr(
                            'invoices.paid_amount',
                            namedArgs: {
                              'amount': invoiceAmount(context, record.paid),
                            },
                          ),
                        ].join(' · '),
                        style: short,
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: DesignMotion.duration(
                          context,
                          DesignMotion.object,
                        ),
                        builder: (_, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(5),
                          backgroundColor: context.raised,
                          color: DesignColor.green,
                        ),
                      ),
                    ],
                  ),
                ),
                if (record.outstanding > 0)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 36),
                      backgroundColor: DesignColor.purple,
                      foregroundColor: DesignColor.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    onPressed: payment,
                    child: Text(
                      context.tr('invoices.payment'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (overdue)
                  TextButton(
                    onPressed: () async {
                      final message = context.tr(
                        'invoices.reminder',
                        namedArgs: {
                          'number': record.title,
                          'amount': workspaceAmount(
                            context,
                            record.outstanding,
                          ),
                        },
                      );
                      await Clipboard.setData(ClipboardData(text: message));
                      if (context.mounted) {
                        designToast(context, context.tr('invoices.copied'));
                      }
                    },
                    child: Text(context.tr('invoices.remind')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
