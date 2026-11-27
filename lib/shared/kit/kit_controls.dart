import 'package:flutter/material.dart';

import '../design/design_tokens.dart';

/// `.seg` segmented control.
class KitSegment<T> extends StatelessWidget {
  const KitSegment({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: c.dark ? c.panel : const Color(0xffe8eaf4),
      border: Border.all(color: c.outline),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      spacing: 4,
      children: [
        for (final v in values)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: DesignMotion.fast,
                curve: DesignMotion.curve,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: v == selected
                      ? (c.dark ? c.raised : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: v == selected && c.dark
                      ? const [
                          BoxShadow(
                            color: Color(0xcc000000),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                            spreadRadius: -6,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label(v),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: v == selected ? c.foreground : c.muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// `.input` field: 54px, rounded, placeholder only, lavender focus ring.
class KitInput extends StatelessWidget {
  const KitInput({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.autofocus = false,
    this.lines = 1,
    this.onChanged,
  });
  final TextEditingController controller;
  final String hint;

  /// Visible lines; above one the field grows with its text.
  final int lines;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool autofocus;
  @override
  Widget build(BuildContext c) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      onChanged: onChanged,
      minLines: lines > 1 ? lines : null,
      maxLines: lines > 1 ? null : 1,
      style: TextStyle(
        fontSize: lines > 1 ? 14.5 : 16,
        height: lines > 1 ? 1.45 : null,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.muted.withValues(alpha: .8)),
        filled: true,
        fillColor: c.panel,
        constraints: const BoxConstraints(minHeight: 54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder: border(c.outline),
        focusedBorder: border(DesignColor.purple),
        border: border(c.outline),
      ),
    );
  }
}
