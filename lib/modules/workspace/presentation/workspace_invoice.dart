import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/design/design_widgets.dart';
import '../domain/local_workspace.dart';
import 'workspace_ui.dart';
import '../../../shared/design/tms_icons.dart';

class InvoiceLinesEditor extends StatelessWidget {
  const InvoiceLinesEditor({
    super.key,
    required this.lines,
    required this.onChanged,
  });

  final List<InvoiceLine> lines;
  final ValueChanged<List<InvoiceLine>> onChanged;

  Future<void> _editLine(BuildContext context, [int? index]) async {
    final line = await designSheet<InvoiceLine>(
      context,
      title: context.tr(
        index == null ? 'workspaces.add_line' : 'workspaces.edit_line',
      ),
      builder: (_) => _LineForm(line: index == null ? null : lines[index]),
    );
    if (line == null || !context.mounted) return;
    final updated = [...lines];
    if (index == null) {
      updated.add(line);
    } else {
      updated[index] = line;
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      if (lines.isNotEmpty) ...[
        DesignTitle(context.tr('workspaces.invoice_lines')),
        ...lines.indexed.map((entry) {
          final (index, line) = entry;
          return DesignTile(
            title: line.description,
            subtitle: invoiceLineTotal(context, line),
            onTap: () => _editLine(context, index),
            trailing: IconButton(
              tooltip: context.tr('workspaces.remove_line'),
              onPressed: () => onChanged([...lines]..removeAt(index)),
              icon: const Icon(TmsIcons.removeCircle),
            ),
          );
        }),
        DesignLabel(
          context.tr(
            'workspaces.invoice_total',
            namedArgs: {
              'amount': workspaceAmount(
                context,
                lines.fold(0, (sum, line) => sum + line.total),
              ),
            },
          ),
        ),
      ],
      DesignButton(
        context.tr('workspaces.add_line'),
        icon: TmsIcons.add,
        secondary: true,
        onPressed: () => _editLine(context),
      ),
    ],
  );
}

String invoiceLineTotal(BuildContext context, InvoiceLine line) => context.tr(
  'workspaces.invoice_line_total',
  namedArgs: {
    'quantity': NumberFormat.decimalPattern(
      context.locale.toString(),
    ).format(line.quantity),
    'rate': workspaceAmount(context, line.rate),
    'amount': workspaceAmount(context, line.total),
  },
);

class _LineForm extends StatefulWidget {
  const _LineForm({required this.line});
  final InvoiceLine? line;

  @override
  State<_LineForm> createState() => _LineFormState();
}

class _LineFormState extends State<_LineForm> {
  late String description = widget.line?.description ?? '';
  late String quantity = widget.line?.quantity.toString() ?? '1';
  late String rate = widget.line == null
      ? ''
      : (widget.line!.rate / 100).toStringAsFixed(2);
  bool attempted = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      DesignField(
        label: context.tr('tasks.description'),
        initialValue: description,
        onChanged: (value) => description = value,
      ),
      DesignField(
        label: context.tr('workspaces.quantity'),
        initialValue: quantity,
        keyboardType: TextInputType.number,
        onChanged: (value) => quantity = value,
      ),
      DesignField(
        label: context.tr('workspaces.unit_rate'),
        initialValue: rate,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) => rate = value,
      ),
      if (attempted) DesignLabel(context.tr('workspaces.invalid_line')),
      DesignButton(
        context.tr('workspaces.save'),
        onPressed: () {
          final units = int.tryParse(quantity.trim());
          final unitRate = parseWorkspaceAmount(rate);
          if (description.trim().isEmpty ||
              units == null ||
              units < 1 ||
              units > 10000 ||
              unitRate == null ||
              unitRate < 1 ||
              units * unitRate > 999999999999) {
            setState(() => attempted = true);
          } else {
            Navigator.pop(
              context,
              InvoiceLine(description.trim(), units, unitRate),
            );
          }
        },
      ),
    ],
  );
}
