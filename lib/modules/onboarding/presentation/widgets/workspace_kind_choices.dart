import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_widgets.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../workspace/presentation/workspace_ui.dart';
import 'workspace_setup_choice.dart';

class WorkspaceKindChoices extends StatelessWidget {
  const WorkspaceKindChoices({
    super.key,
    required this.personal,
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  final bool personal;
  final List<WorkspaceKind> choices;
  final WorkspaceKind? selected;
  final ValueChanged<WorkspaceKind> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.tr(
          personal
              ? 'onboarding.setup_personal_title'
              : 'onboarding.setup_specials_title',
        ),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -.7,
        ),
      ),
      const SizedBox(height: 8),
      DesignLabel(
        context.tr(
          personal
              ? 'onboarding.setup_personal_description'
              : 'onboarding.setup_specials_description',
        ),
      ),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final choice in choices)
              SizedBox(
                width: (constraints.maxWidth - 10) / 2,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 120),
                  child: WorkspaceSetupChoice(
                    title: context.tr('onboarding.setup_kind.${choice.name}'),
                    subtitle: personal
                        ? context.tr(
                            'onboarding.setup_kind_description.${choice.name}',
                          )
                        : null,
                    icon: choice.icon,
                    grid: true,
                    selected: selected == choice,
                    onTap: () => onSelected(choice),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
