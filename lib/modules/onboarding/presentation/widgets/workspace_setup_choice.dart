import 'package:easy_localization/easy_localization.dart';
import '../../../../shared/design/design_widgets.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';

class WorkspaceSetupChoice extends StatelessWidget {
  const WorkspaceSetupChoice({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.color = DesignColor.purple,
    this.grid = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final bool grid;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(grid ? 18 : 22),
        child: AnimatedContainer(
          duration: DesignMotion.duration(context, DesignMotion.fast),
          curve: DesignMotion.curve,
          padding: EdgeInsets.all(grid ? 16 : 16),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    DesignColor.purple.withValues(alpha: .14),
                    context.panel,
                  )
                : context.panel,
            borderRadius: BorderRadius.circular(grid ? 18 : 22),
            border: Border.all(
              color: selected ? DesignColor.purple : context.outline,
            ),
            boxShadow: selected && !grid
                ? [
                    BoxShadow(
                      color: DesignColor.purple.withValues(alpha: .20),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: grid
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: selected ? context.lavender : context.muted,
                      size: 29,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle!,
                        style: TextStyle(color: context.muted, fontSize: 13),
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: color.withValues(alpha: .22)),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: context.muted,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected ? TmsIcons.checkCircleFilled : TmsIcons.circle,
                      color: selected ? DesignColor.purple : context.muted,
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}

class WorkspaceNameField extends StatelessWidget {
  const WorkspaceNameField({
    super.key,
    required this.fieldType,
    required this.name,
    required this.slug,
    required this.onChanged,
  });
  final String fieldType;
  final String name;
  final String slug;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = context.tr('onboarding.setup_name.$fieldType');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          textField: true,
          child: TextFormField(
            key: ValueKey(fieldType),
            initialValue: name,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: context.tr('onboarding.setup_name_hint.$fieldType'),
              filled: true,
              fillColor: context.panel,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: context.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: DesignColor.purple),
              ),
            ),
          ),
        ),
        if (slug.isNotEmpty) ...[
          const SizedBox(height: 8),
          DesignLabel(
            context.tr(
              'onboarding.workspace_link',
              namedArgs: {'url': 'sabipipu.app/$slug'},
            ),
          ),
        ],
      ],
    );
  }
}
