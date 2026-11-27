import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';

/// A card with a two-line text box, optional chips and a send button.
class SpecialCompose extends StatefulWidget {
  const SpecialCompose({
    super.key,
    required this.hint,
    required this.action,
    required this.onSend,
    this.options = const [],
    this.footnote,
  });
  final String hint, action;
  final String? footnote;
  final List<Widget> options;

  /// Returns true when the text was saved, which clears the box.
  final Future<bool> Function(String text) onSend;
  @override
  State<SpecialCompose> createState() => _SpecialComposeState();
}

class _SpecialComposeState extends State<SpecialCompose> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_text.text.trim().isEmpty) return;
    if (await widget.onSend(_text.text) && mounted) _text.clear();
  }

  @override
  Widget build(BuildContext c) => KitCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _text,
          minLines: 2,
          maxLines: 5,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.all(4),
            hintText: widget.hint,
            hintStyle: TextStyle(color: c.muted),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: widget.footnote != null
                  ? Text(
                      widget.footnote!,
                      style: TextStyle(fontSize: 12, color: c.muted),
                    )
                  : Wrap(spacing: 8, runSpacing: 8, children: widget.options),
            ),
            KitMiniButton(widget.action, primary: true, onPressed: _send),
          ],
        ),
      ],
    ),
  );
}

/// Overlapping small avatars (`.avs`).
class SpecialFaces extends StatelessWidget {
  const SpecialFaces(this.names, {super.key});
  final List<String> names;
  @override
  Widget build(BuildContext c) => SizedBox(
    width: 28 + (names.length - 1) * 20.0,
    height: 28,
    child: Stack(
      children: [
        for (final (i, n) in names.indexed)
          Positioned(
            left: i * 20.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.panel, width: 2),
              ),
              child: DesignAvatar(
                kitPerson(n).$1,
                size: 28,
                color: kitPerson(n).$2,
              ),
            ),
          ),
      ],
    ),
  );
}

/// Empty state for a tab with nothing recorded yet.
class SpecialEmpty extends StatelessWidget {
  const SpecialEmpty(this.section, {super.key});

  /// Section name, for `workspaces.sections.<section>.empty`.
  final String section;
  @override
  Widget build(BuildContext c) => KitPop(
    child: KitCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          Text(
            c.tr('workspaces.no_records'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            c.tr('workspaces.sections.$section.empty'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
        ],
      ),
    ),
  );
}

String specialWhen(BuildContext c, DateTime? d, DateTime today) {
  if (d == null) return '';
  final days = today.difference(DateTime(d.year, d.month, d.day)).inDays;
  return switch (days) {
    0 => c.tr('common.today'),
    1 => c.tr('individual.yesterday'),
    _ => DateFormat.MMMEd(c.locale.toString()).format(d),
  };
}

void specialToast(
  BuildContext c,
  bool ok,
  String key, [
  Map<String, String>? a,
]) {
  if (c.mounted) {
    designToast(c, c.tr(ok ? key : 'workspaces.try_again', namedArgs: a));
  }
}

/// `.tile` showing a name's first letter, tinted by [color].
class SpecialInitialTile extends StatelessWidget {
  const SpecialInitialTile(this.letter, this.color, {super.key});
  final String letter;
  final Color? color;
  @override
  Widget build(BuildContext c) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color?.withValues(alpha: .13) ?? c.raised,
      border: Border.all(color: color?.withValues(alpha: .28) ?? c.outline),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Text(
      letter,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: color ?? c.lavender,
      ),
    ),
  );
}

/// Tile tints for lists of lettered tiles, in order.
const specialTints = <Color?>[
  null,
  DesignColor.amber,
  DesignColor.teal,
  DesignColor.blue,
  DesignColor.red,
  DesignColor.green,
];
