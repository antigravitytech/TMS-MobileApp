import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';

/// Proposal text remains editable as plain text, including in older drafts.
class ProposalEditor extends StatefulWidget {
  const ProposalEditor({
    super.key,
    required this.text,
    required this.onChanged,
  });
  final String text;
  final ValueChanged<String> onChanged;
  @override
  State<ProposalEditor> createState() => _ProposalEditorState();
}

class _ProposalEditorState extends State<ProposalEditor> {
  late final controller = TextEditingController(text: widget.text);
  final history = UndoHistoryController();
  final focus = FocusNode();
  @override
  void dispose() {
    history.dispose();
    focus.dispose();
    controller.dispose();
    super.dispose();
  }

  void format(String token, {bool inline = false}) {
    final value = controller.value, text = value.text;
    final start = value.selection.isValid ? value.selection.start : text.length;
    final end = value.selection.isValid ? value.selection.end : text.length;
    final from = inline
        ? start
        : (start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1);
    final selection = text.substring(from, end);
    final inserted = inline ? '$token$selection$token' : '$token$selection';
    final next = text.replaceRange(from, end, inserted);
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection(
        baseOffset: from + token.length,
        extentOffset: from + token.length + selection.length,
      ),
    );
    widget.onChanged(next);
    focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 6,
    children: [
      DesignLabel(context.tr('workspaces.fields.documentBody')),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (label, icon, token, inline) in [
            ('heading', TmsIcons.heading, '## ', false),
            ('bold', TmsIcons.bold, '**', true),
            ('italic', TmsIcons.italic, '*', true),
            ('list', TmsIcons.list, '• ', false),
            ('quote', TmsIcons.quote, '> ', false),
          ])
            IconButton(
              tooltip: context.tr('workspaces.format.$label'),
              icon: Icon(icon, size: 19),
              onPressed: () => format(token, inline: inline),
            ),
          ValueListenableBuilder(
            valueListenable: history,
            builder: (context, value, _) => IconButton(
              tooltip: context.tr('workspaces.format.undo'),
              icon: const Icon(TmsIcons.undo, size: 19),
              onPressed: value.canUndo ? history.undo : null,
            ),
          ),
        ],
      ),
      TextField(
        controller: controller,
        focusNode: focus,
        undoController: history,
        minLines: 5,
        maxLines: 12,
        decoration: InputDecoration(
          labelText: context.tr('workspaces.format.body'),
          alignLabelWithHint: true,
        ),
        onChanged: widget.onChanged,
      ),
    ],
  );
}

class ProposalParagraph {
  ProposalParagraph(String raw)
    : heading = raw.startsWith('## '),
      quote = raw.startsWith('> '),
      text = raw.replaceFirst(RegExp(r'^(## |> )'), '');
  final String text;
  final bool heading, quote;
  Iterable<({String text, bool bold, bool italic})> get spans sync* {
    var cursor = 0;
    for (final match in RegExp(
      r'\*\*(.+?)\*\*|\*([^*]+?)\*',
    ).allMatches(text)) {
      if (match.start > cursor) {
        yield (
          text: text.substring(cursor, match.start),
          bold: heading,
          italic: quote,
        );
      }
      yield (
        text: match[1] ?? match[2]!,
        bold: heading || match[1] != null,
        italic: quote || match[2] != null,
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      yield (text: text.substring(cursor), bold: heading, italic: quote);
    }
  }

  Widget get preview => Text.rich(
    TextSpan(
      children: [
        for (final span in spans)
          TextSpan(
            text: span.text,
            style: TextStyle(
              fontWeight: span.bold ? FontWeight.w700 : null,
              fontStyle: span.italic ? FontStyle.italic : null,
              fontSize: heading ? 18 : null,
            ),
          ),
      ],
    ),
  );
  pw.Widget get pdf => pw.RichText(
    text: pw.TextSpan(
      children: [
        for (final span in spans)
          pw.TextSpan(
            text: span.text,
            style: pw.TextStyle(
              fontWeight: span.bold ? pw.FontWeight.bold : null,
              fontStyle: span.italic ? pw.FontStyle.italic : null,
              fontSize: heading ? 16 : 11,
            ),
          ),
      ],
    ),
  );
}
