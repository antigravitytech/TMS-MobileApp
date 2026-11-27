import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/workspace_kind.dart';
import 'personal_setup_controls.dart';

class PersonalKindChoices extends StatelessWidget {
  const PersonalKindChoices({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final WorkspaceKind? selected;
  final ValueChanged<WorkspaceKind> onSelected;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.tr('onboarding.setup_personal').toUpperCase(),
        style: setupLabel(context).copyWith(
          letterSpacing: 1,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        context.tr('onboarding.setup_personal_title'),
        style: const TextStyle(
          fontSize: 28,
          height: 1.12,
          letterSpacing: -.7,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        context.tr('onboarding.setup_personal_description'),
        style: setupLabel(
          context,
        ).copyWith(fontSize: 15, fontWeight: FontWeight.w400),
      ),
      const SizedBox(height: 24),
      for (final kind in const [
        WorkspaceKind.individual,
        WorkspaceKind.family,
      ]) ...[
        if (kind == WorkspaceKind.family) const SizedBox(height: 14),
        _KindCard(
          kind: kind,
          selected: selected == kind,
          onTap: () => onSelected(kind),
        ),
      ],
    ],
  );
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.kind,
    required this.selected,
    required this.onTap,
  });
  final WorkspaceKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final family = kind == WorkspaceKind.family;
    final perks = family
        ? ['chores', 'school', 'bills', 'shopping', 'errands']
        : ['clients', 'invoices', 'billing', 'proposals', 'gigs'];
    return SetupOption(
      selected: selected,
      onTap: onTap,
      radius: 26,
      glow: true,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 14,
              children: [
                SetupIconTile(
                  family ? TmsIcons.home : TmsIcons.person,
                  family ? DesignColor.teal : DesignColor.blue,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('onboarding.setup_kind.${kind.name}'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr(
                          'onboarding.setup_kind_description.${kind.name}',
                        ),
                        style: setupLabel(
                          context,
                        ).copyWith(fontSize: 13.5, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: DesignMotion.duration(context, DesignMotion.fast),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? DesignColor.purple : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? DesignColor.purple
                          : context.muted.withValues(alpha: .65),
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          TmsIcons.check,
                          color: DesignColor.ink,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final perk in perks)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.foreground.withValues(alpha: .04),
                      border: Border.all(
                        color: context.outline.withValues(alpha: .08),
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      context.tr('setup_details.perks.$perk'),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? context.foreground : context.muted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    context.tr('setup_details.audience.${kind.name}'),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: context.muted,
                    ),
                  ),
                ),
                for (final (i, (initial, color))
                    in (family
                            ? const [
                                ('IM', DesignColor.teal),
                                ('FI', DesignColor.rose),
                                ('TI', DesignColor.amber),
                                ('AI', Color(0xffbedb9a)),
                              ]
                            : const [('KA', Color(0xffa3c8f1))])
                        .indexed)
                  Align(
                    widthFactor: i == 0 ? 1 : .42,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: selected
                            ? setupSelection(context)
                            : context.panel,
                        shape: BoxShape.circle,
                      ),
                      child: DesignAvatar(initial, color: color, size: 23),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
