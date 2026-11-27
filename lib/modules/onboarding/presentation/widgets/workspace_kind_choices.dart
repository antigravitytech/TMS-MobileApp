import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../workspace/domain/workspace_kind.dart';
import 'personal_setup_controls.dart';
import 'special_setup_options.dart';

class WorkspaceKindChoices extends StatelessWidget {
  const WorkspaceKindChoices({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final WorkspaceKind? selected;
  final ValueChanged<WorkspaceKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = specialSetupOptions.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('workspaces.specials').toUpperCase(),
          style: setupLabel(context).copyWith(
            fontSize: 11.5,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('onboarding.setup_specials_title'),
          style: const TextStyle(
            fontSize: 28,
            height: 1.12,
            letterSpacing: -.7,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('onboarding.setup_specials_description'),
          style: TextStyle(color: context.muted, fontSize: 15, height: 1.45),
        ),
        const SizedBox(height: 22),
        Column(
          spacing: 10,
          children: [
            for (var index = 0; index < options.length; index += 2)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    for (final entry in options.skip(index).take(2))
                      Expanded(
                        child: SetupOption(
                          selected: entry.key == selected,
                          onTap: () => onSelected(entry.key),
                          radius: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 10,
                              children: [
                                SetupIconTile(entry.value.$1, entry.value.$2),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 2,
                                  children: [
                                    Text(
                                      specialSetupTitle(context, entry.key),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        letterSpacing: 0,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      context.tr(
                                        'setup_specials.kinds.${entry.key.name}.description',
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        letterSpacing: 0,
                                        height: 1.45,
                                        color: context.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
