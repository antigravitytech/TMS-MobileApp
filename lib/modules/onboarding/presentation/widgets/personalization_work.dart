import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/workspace_setup.dart';
import '../../application/workspace_personalization_draft.dart';
import 'personal_setup_controls.dart';

class WorkPersonalization extends StatelessWidget {
  const WorkPersonalization({super.key, required this.draft});
  final PersonalizationDraft draft;

  @override
  Widget build(BuildContext context) {
    final slug = draft.name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    const jobs = [
      (TmsIcons.edit, DesignColor.purple),
      (TmsIcons.barChart, DesignColor.teal),
      (TmsIcons.school, DesignColor.blue),
      (TmsIcons.shoppingBag, DesignColor.amber),
      (TmsIcons.code, DesignColor.green),
      (TmsIcons.more, DesignColor.red),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr('workspaces.setup.job'), style: setupLabel(context)),
        LayoutBuilder(
          builder: (context, bounds) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (index, job) in IndividualOccupation.values.indexed)
                SizedBox(
                  width: (bounds.maxWidth - 16) / 3,
                  child: SetupOption(
                    selected: draft.job == job,
                    onTap: () => draft.setJob(job),
                    radius: 20,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 88),
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                      child: Column(
                        spacing: 8,
                        children: [
                          SetupIconTile(
                            jobs[index].$1,
                            jobs[index].$2,
                            size: 36,
                          ),
                          Text(
                            context.tr('workspaces.jobs.${job.name}'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          context.tr('setup_details.clients_question'),
          style: setupLabel(context),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.dark ? context.panel : const Color(0xffe8eaf4),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: context.outline),
          ),
          child: Row(
            spacing: 4,
            children: [
              for (final yes in const [true, false])
                Expanded(
                  child: Semantics(
                    selected: draft.clients == yes,
                    child: AnimatedContainer(
                      duration: DesignMotion.duration(
                        context,
                        const Duration(milliseconds: 250),
                      ),
                      curve: DesignMotion.curve,
                      decoration: BoxDecoration(
                        color: draft.clients == yes
                            ? context.raised
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          foregroundColor: draft.clients == yes
                              ? context.foreground
                              : context.muted,
                          textStyle: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        onPressed: () => draft.setClients(yes),
                        child: Text(
                          context.tr(
                            yes ? 'setup_details.yes' : 'setup_details.no',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SetupInfo(
          icon: TmsIcons.star,
          color: context.lavender,
          child: Text(
            context.tr(
              draft.clients
                  ? 'setup_details.clients_info'
                  : 'setup_details.solo_info',
            ),
            style: const TextStyle(fontSize: 13.5, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
        SetupNameInput(
          label: context.tr('setup_details.name_space'),
          hint: context.tr('setup_details.work_hint'),
          value: draft.name,
          onChanged: draft.setName,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            'onboarding.workspace_link',
            namedArgs: {
              'url': 'sabipipu.app/${slug.isEmpty ? 'my-space' : slug}',
            },
          ),
          style: TextStyle(fontSize: 12, color: context.muted),
        ),
      ],
    );
  }
}
