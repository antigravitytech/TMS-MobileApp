import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import 'workspace_invoice.dart';
import 'workspace_proposal_editor.dart';
import 'workspace_ui.dart';

const invoiceStyles = ['modern', 'bold', 'classic', 'minimal'];
const proposalTemplates = [
  'blank',
  'design',
  'website',
  'retainer',
  'consulting',
  'event',
];
const billingPeriods = ['once', 'month', 'week', 'hour'];
const documentAccents = [
  DesignColor.purple,
  DesignColor.teal,
  DesignColor.blue,
  DesignColor.rose,
];

class WorkspaceDocumentPreview extends StatefulWidget {
  const WorkspaceDocumentPreview({super.key, required this.record});
  final WorkspaceRecord record;

  @override
  State<WorkspaceDocumentPreview> createState() =>
      _WorkspaceDocumentPreviewState();
}

class _WorkspaceDocumentPreviewState extends State<WorkspaceDocumentPreview> {
  final previewKey = GlobalKey();
  bool saving = false;

  List<String> _lines(BuildContext context) {
    final r = widget.record, f = r.fields;
    final invoice = r.section == WorkspaceSection.invoices;
    return [
      if ((f['invoiceFrom'] ?? '').isNotEmpty) f['invoiceFrom']!,
      if ((f['fromDetails'] ?? '').isNotEmpty) f['fromDetails']!,
      if (r.person.isNotEmpty)
        context.tr('workspaces.doc.for_client', namedArgs: {'name': r.person}),
      if ((f['clientDetails'] ?? '').isNotEmpty) f['clientDetails']!,
      if (r.date != null)
        context.tr(
          'workspaces.doc.due',
          namedArgs: {
            'date': MaterialLocalizations.of(context).formatMediumDate(r.date!),
          },
        ),
      if (!invoice && (f['documentBody'] ?? '').isNotEmpty)
        ...f['documentBody']!.split('\n'),
      for (final line in r.invoiceLines)
        '${line.description}\n${invoiceLineTotal(context, line)}',
      if (invoice &&
          r.invoiceLines.isNotEmpty &&
          ((f['discount'] ?? '').isNotEmpty || (f['tax'] ?? '').isNotEmpty))
        context.tr(
          'workspaces.doc.subtotal',
          namedArgs: {
            'amount': workspaceAmount(
              context,
              r.invoiceLines.fold(0, (n, l) => n + l.total),
            ),
          },
        ),
      for (final k in ['discount', 'tax'])
        if ((f[k] ?? '').isNotEmpty)
          '${context.tr('workspaces.fields.$k')} · ${f[k]}',
      if (invoice)
        context.tr(
          'workspaces.invoice_total',
          namedArgs: {'amount': workspaceAmount(context, r.amount)},
        )
      else if (r.amount > 0)
        '${workspaceAmount(context, r.amount)} · ${context.tr('workspaces.period.${f['billingPeriod'] ?? 'once'}')}',
      if ((f['paymentDetails'] ?? '').isNotEmpty) f['paymentDetails']!,
      if (r.notes.isNotEmpty) r.notes,
    ];
  }

  Color get accent =>
      documentAccents.elementAtOrNull(
        int.tryParse(widget.record.fields['accent'] ?? '') ?? 0,
      ) ??
      documentAccents.first;
  Future<void> _export(bool pdf) async {
    if (saving) return;
    final r = widget.record, lines = _lines(context);
    final kind = context.tr(
      r.section == WorkspaceSection.invoices
          ? 'workspaces.doc.invoice'
          : 'workspaces.doc.proposal',
    );
    setState(() => saving = true);
    try {
      late Uint8List bytes;
      if (pdf) {
        final font = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Inter.ttf'),
        );
        final doc = pw.Document();
        final style = r.fields['style'] ?? 'modern';
        doc.addPage(
          pw.MultiPage(
            theme: pw.ThemeData.withFont(base: font, bold: font),
            pageFormat: PdfPageFormat.a4,
            build: (_) => [
              if (style != 'minimal')
                pw.Container(
                  height: style == 'bold' ? 18 : 4,
                  color: PdfColor.fromInt(accent.toARGB32()),
                ),
              pw.SizedBox(height: 16),
              pw.Text(kind),
              pw.Header(level: 0, text: r.title),
              for (final line in lines) ...[
                if (r.section == WorkspaceSection.proposals)
                  ProposalParagraph(line).pdf
                else
                  pw.Paragraph(text: line),
                pw.SizedBox(height: 3),
              ],
            ],
          ),
        );
        bytes = await doc.save();
      } else {
        await Scrollable.ensureVisible(previewKey.currentContext!);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        final boundary =
            previewKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final ratio = (6000 / boundary.size.height).clamp(.1, 2.0);
        final image = await boundary.toImage(pixelRatio: ratio);
        try {
          bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
        } finally {
          image.dispose();
        }
      }
      if (!mounted) return;
      final filename = r.title
          .replaceAll(RegExp(r'[^\p{L}\p{N}._ -]', unicode: true), '_')
          .trim();
      final uri = await FilePicker.saveFile(
        fileName:
            '${filename.isEmpty ? r.id : filename}.${pdf ? 'pdf' : 'png'}',
        bytes: bytes,
        mimeType: pdf ? 'application/pdf' : 'image/png',
      );
      if (mounted && uri != null) {
        designToast(context, context.tr('workspaces.doc.exported'));
      }
    } catch (_) {
      if (mounted) {
        designToast(context, context.tr('workspaces.doc.export_failed'));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record, style = r.fields['style'] ?? 'modern';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        RepaintBoundary(
          key: previewKey,
          child: ColoredBox(
            color: Colors.white,
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'Inter',
                color: DesignColor.ink,
                fontSize: 13,
                height: 1.5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (style != 'minimal')
                    Container(height: style == 'bold' ? 20 : 5, color: accent),
                  Padding(
                    padding: const EdgeInsets.all(21),
                    child: Column(
                      crossAxisAlignment: style == 'classic'
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Text(
                          context.tr(
                            r.section == WorkspaceSection.invoices
                                ? 'workspaces.doc.invoice'
                                : 'workspaces.doc.proposal',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          r.title,
                          style: TextStyle(
                            fontSize: style == 'bold' ? 30 : 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Divider(color: Color(0xffdedee4)),
                        for (final line in _lines(context))
                          if (r.section == WorkspaceSection.proposals)
                            ProposalParagraph(line).preview
                          else
                            Text(line),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final pdf in [true, false])
              DesignButton(
                context.tr(
                  pdf ? 'workspaces.doc.save_pdf' : 'workspaces.doc.save_image',
                ),
                icon: TmsIcons.file,
                secondary: !pdf,
                onPressed: saving ? null : () => _export(pdf),
              ),
          ],
        ),
      ],
    );
  }
}

class DocumentDesignFields extends StatelessWidget {
  const DocumentDesignFields({
    super.key,
    required this.invoice,
    required this.values,
    required this.onChanged,
  });
  final bool invoice;
  final Map<String, String> values;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final style = values['style'] ?? 'modern';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (invoice) ...[
          DesignLabel(context.tr('workspaces.fields.style')),
          DesignChoices(
            items: [
              for (final s in invoiceStyles) context.tr('workspaces.styles.$s'),
            ],
            selected: invoiceStyles.indexOf(style),
            scroll: false,
            onChanged: (i) {
              values['style'] = invoiceStyles[i];
              onChanged();
            },
          ),
          DesignLabel(context.tr('workspaces.doc.accent')),
          Wrap(
            spacing: 8,
            children: [
              for (final (i, color) in documentAccents.indexed)
                IconButton(
                  tooltip: context.tr('workspaces.doc.color_$i'),
                  style: IconButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: DesignColor.ink,
                  ),
                  onPressed: () {
                    values['accent'] = '$i';
                    onChanged();
                  },
                  icon: Icon(
                    (int.tryParse(values['accent'] ?? '') ?? 0) == i
                        ? TmsIcons.check
                        : TmsIcons.circle,
                  ),
                ),
            ],
          ),
        ] else ...[
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: values['template'] ?? 'blank',
            decoration: InputDecoration(
              labelText: context.tr('workspaces.fields.template'),
            ),
            items: [
              for (final t in proposalTemplates)
                DropdownMenuItem(
                  value: t,
                  child: Text(context.tr('workspaces.templates.$t')),
                ),
            ],
            onChanged: (t) {
              if (t == null) return;
              final previous = values['template'] ?? 'blank';
              final body = values['documentBody'] ?? '';
              if (body.isEmpty ||
                  (previous != 'blank' &&
                      body ==
                          context.tr('workspaces.template_body.$previous'))) {
                values['documentBody'] = t == 'blank'
                    ? ''
                    : context.tr('workspaces.template_body.$t');
              }
              values['template'] = t;
              onChanged();
            },
          ),
          ProposalEditor(
            key: ValueKey(values['template']),
            text: values['documentBody'] ?? '',
            onChanged: (s) => values['documentBody'] = s,
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: values['billingPeriod'] ?? 'once',
            decoration: InputDecoration(
              labelText: context.tr('workspaces.fields.billingPeriod'),
            ),
            items: [
              for (final b in billingPeriods)
                DropdownMenuItem(
                  value: b,
                  child: Text(context.tr('workspaces.period.$b')),
                ),
            ],
            onChanged: (b) {
              if (b != null) values['billingPeriod'] = b;
            },
          ),
        ],
        if (invoice)
          for (final k in [
            'invoiceFrom',
            'fromDetails',
            'clientDetails',
            'paymentDetails',
            'discount',
            'tax',
          ])
            DesignField(
              label: context.tr('workspaces.fields.$k'),
              initialValue: values[k],
              keyboardType: ['discount', 'tax'].contains(k)
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : null,
              onChanged: (s) => values[k] = s.trim(),
            ),
      ],
    );
  }
}
