import 'dart:math' as math;
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/domain/workspace_setup.dart';
import '../../workspace/presentation/workspace_ui.dart';
import '../application/workspace_personalization_draft.dart';
import 'widgets/personalization_family.dart';

class WorkspacePersonalization extends ConsumerWidget {
  const WorkspacePersonalization({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = context.routeData.args is PersonalizationInput
        ? context.routeData.args as PersonalizationInput
        : (kind: WorkspaceKind.individual, name: '');
    final kind = input.kind,
        work = kind == WorkspaceKind.individual,
        family = kind == WorkspaceKind.family;
    final d = ref.watch(personalizationDraftProvider(input));
    final slug = d.name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    math.max(10, 58 - MediaQuery.viewPaddingOf(context).top),
                    20,
                    0,
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      DesignIcon(
                        icon: TmsIcons.chevronBack,
                        label: context.tr('common.back'),
                        onPressed: () => context.router.maybePop(),
                      ),
                      const Expanded(
                        child: LinearProgressIndicator(
                          value: .6,
                          minHeight: 6,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                      DesignLabel(context.tr('setup_details.step')),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                    children: [
                      Text(
                        kind.label(context).toUpperCase(),
                        style: TextStyle(
                          color: context.lavender,
                          fontSize: 12,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(
                          work
                              ? 'setup_details.work'
                              : family
                              ? 'setup_details.family'
                              : kind == WorkspaceKind.alumni
                              ? 'setup_details.set'
                              : 'setup_details.community',
                        ),
                        style: const TextStyle(
                          fontSize: 30,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (work || family) ...[
                        const SizedBox(height: 8),
                        DesignLabel(
                          context.tr(
                            work
                                ? 'setup_details.work_sub'
                                : 'setup_details.family_sub',
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      if (work) ...[
                        DesignTitle(context.tr('workspaces.setup.job')),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, bounds) => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (i, j)
                                  in IndividualOccupation.values.indexed)
                                SizedBox(
                                  width: (bounds.maxWidth - 16) / 3,
                                  child: DesignCard(
                                    color: d.job == j
                                        ? context.raised
                                        : context.panel,
                                    onTap: () => d.setJob(j),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      spacing: 8,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: [
                                              DesignColor.purple,
                                              DesignColor.teal,
                                              DesignColor.blue,
                                              DesignColor.amber,
                                              DesignColor.green,
                                              DesignColor.rose,
                                            ][i].withValues(alpha: .2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            [
                                              TmsIcons.edit,
                                              TmsIcons.barChart,
                                              TmsIcons.school,
                                              TmsIcons.shoppingCart,
                                              TmsIcons.laptop,
                                              TmsIcons.more,
                                            ][i],
                                            size: 20,
                                          ),
                                        ),
                                        Text(
                                          context.tr(
                                            'workspaces.jobs.${j.name}',
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        DesignTitle(context.tr('workspaces.setup.clients')),
                        const SizedBox(height: 8),
                        Row(
                          spacing: 8,
                          children: [
                            for (final yes in [true, false])
                              Expanded(
                                child: DesignButton(
                                  context.tr(
                                    yes
                                        ? 'setup_details.yes'
                                        : 'setup_details.no',
                                  ),
                                  secondary: yes != d.clients,
                                  onPressed: () => d.setClients(yes),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DesignCard(
                          child: DesignLabel(
                            context.tr(
                              d.clients
                                  ? 'setup_details.clients_info'
                                  : 'setup_details.solo_info',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (family)
                        FamilyPersonalization(draft: d)
                      else ...[
                        DesignField(
                          label: context.tr(
                            work
                                ? 'setup_details.name_space'
                                : kind == WorkspaceKind.alumni
                                ? 'setup_details.set_name'
                                : 'workspaces.name',
                          ),
                          initialValue: input.name,
                          onChanged: d.setName,
                        ),
                        if (work)
                          DesignLabel(
                            context.tr(
                              'onboarding.workspace_link',
                              namedArgs: {
                                'url':
                                    'sabipipu.app/${slug.isEmpty ? "my-space" : slug}',
                              },
                            ),
                          )
                        else ...[
                          const SizedBox(height: 12),
                          DesignField(
                            label: context.tr('workspaces.setup.occasion'),
                            onChanged: d.setOccasion,
                          ),
                          const SizedBox(height: 12),
                          DesignButton(
                            d.date == null
                                ? context.tr('workspaces.pick_date')
                                : DateFormat.yMMMd(
                                    context.locale.toString(),
                                  ).format(d.date!),
                            secondary: true,
                            icon: TmsIcons.calendar,
                            onPressed: () async {
                              final date = await pickWorkspaceDate(
                                context,
                                d.date,
                              );
                              if (context.mounted && date != null) {
                                d.setDate(date);
                              }
                            },
                          ),
                          const SizedBox(height: 18),
                          DesignCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                if (d.date != null)
                                  DesignTitle(
                                    context.plural(
                                      'workspaces.days_to_event',
                                      math.max(
                                        0,
                                        DateUtils.dateOnly(d.date!)
                                            .difference(
                                              DateUtils.dateOnly(
                                                DateTime.now(),
                                              ),
                                            )
                                            .inDays,
                                      ),
                                      name: 'count',
                                    ),
                                  ),
                                DesignLabel(
                                  context.tr('setup_details.countdown'),
                                ),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final s in kind.sections)
                                      DesignPill(s.label(context)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: DesignButton(
                    context.tr(
                      work || family
                          ? 'common.continue'
                          : 'setup_details.build',
                    ),
                    onPressed: () => context.router.maybePop(d.finish(kind)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
