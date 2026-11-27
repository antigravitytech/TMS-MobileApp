import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/setup_controls.dart';

export '../../../../shared/design/setup_controls.dart';

Color setupSelection(BuildContext context) =>
    context.dark ? const Color(0xff2a2846) : const Color(0xffefecff);

class SetupOption extends StatelessWidget {
  const SetupOption({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    required this.radius,
    this.glow = false,
  });
  final bool selected, glow;
  final VoidCallback onTap;
  final Widget child;
  final double radius;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: AnimatedContainer(
      duration: DesignMotion.duration(
        context,
        const Duration(milliseconds: 350),
      ),
      curve: DesignMotion.curve,
      transform: Matrix4.translationValues(0, selected ? -2 : 0, 0),
      decoration: BoxDecoration(
        color: selected ? setupSelection(context) : context.panel,
        border: Border.all(
          color: selected ? DesignColor.purple : context.outline,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: DesignColor.purple.withValues(alpha: .18),
                  spreadRadius: 3,
                  blurRadius: 0,
                ),
                if (glow)
                  const BoxShadow(
                    color: DesignColor.purple,
                    offset: Offset(0, 22),
                    blurRadius: 40,
                    spreadRadius: -22,
                  ),
              ]
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: child,
        ),
      ),
    ),
  );
}

class SetupNameInput extends StatelessWidget {
  const SetupNameInput({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });
  final String label, hint, value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: context.outline),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: setupLabel(context)),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          child: TextFormField(
            initialValue: value,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 16, letterSpacing: 0),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: context.panel,
              isDense: true,
              constraints: const BoxConstraints(minHeight: 54),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: outline,
              focusedBorder: outline.copyWith(
                borderSide: const BorderSide(color: DesignColor.purple),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PersonalSetupFooter extends StatelessWidget {
  const PersonalSetupFooter({
    super.key,
    required this.onPressed,
    this.labelKey = 'common.continue',
  });
  final VoidCallback? onPressed;
  final String labelKey;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: context.outline.withValues(alpha: .08)),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            backgroundColor: DesignColor.purple,
            foregroundColor: DesignColor.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(context.tr(labelKey)),
        ),
      ),
    ),
  );
}

class SetupInfo extends StatelessWidget {
  const SetupInfo({
    super.key,
    required this.icon,
    required this.color,
    required this.child,
  });
  final IconData icon;
  final Color color;
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: setupSelection(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.outline),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          SetupIconTile(icon, color, size: 36),
          Expanded(child: child),
        ],
      ),
    ),
  );
}
