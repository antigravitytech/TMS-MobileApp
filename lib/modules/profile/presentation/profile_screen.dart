import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspacePreviewProvider);
    return DesignPage(
      title: context.tr('common.profile'),
      actions: [
        DesignIcon(
          icon: TmsIcons.edit,
          label: context.tr('common.edit_profile'),
          onPressed: () => _edit(context, state),
        ),
      ],
      children: [
        DesignCard(
          child: Column(
            spacing: 8,
            children: [
              const DesignAvatar('CO', size: 76),
              Text(
                '${state.firstName} ${state.lastName}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              DesignLabel(
                context.tr(
                  'profile.jobtitle_engineering',
                  namedArgs: {'jobTitle': state.jobTitle},
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  DesignPill(context.tr('common.member')),
                  DesignPill(context.tr('common.line_manager')),
                  DesignPill(context.tr('profile.pm')),
                  DesignPill(context.tr('common.team_lead')),
                ],
              ),
              DesignButton(
                context.tr(state.status),
                secondary: true,
                icon: TmsIcons.smile,
                onPressed: () async {
                  final result = await designSheet<String>(
                    context,
                    title: context.tr('profile.set_your_status'),
                    builder: (sheet) => Column(
                      children: [
                        for (final status in [
                          'profile.available',
                          'profile.in_a_meeting',
                          'profile.focusing',
                          'profile.away',
                          'profile.out_of_office',
                        ])
                          DesignTile(
                            title: context.tr(status),
                            icon: TmsIcons.circle,
                            onTap: () => Navigator.pop(sheet, status),
                          ),
                      ],
                    ),
                  );
                  if (result != null) state.setStatus(result);
                },
              ),
            ],
          ),
        ),
        DesignSection(
          children: [
            DesignTile(
              title: 'Ibrahim Musa',
              subtitle: context.tr('profile.reports_to'),
              leading: const DesignAvatar('IM', color: DesignColor.blue),
              onTap: () => TmsRoute.conversation.open(context),
            ),
            DesignTile(
              title: context.tr('profile.4_direct_reports'),
              subtitle: 'Tech Team',
              icon: TmsIcons.groups,
              onTap: () => TmsRoute.teams.open(context),
            ),
          ],
        ),
        DesignCard(
          child: Row(
            children: [
              for (final (label, value, detail) in [
                (
                  context.tr('profile.points'),
                  '640',
                  context.tr('profile.level_2'),
                ),
                (
                  context.tr('profile.streak'),
                  context.tr('profile.4_days'),
                  context.tr('profile.best_11'),
                ),
                (
                  context.tr('profile.badges'),
                  context.tr('profile.3_of_5'),
                  context.tr('profile.earned'),
                ),
              ])
                Expanded(
                  child: Column(
                    spacing: 5,
                    children: [
                      DesignLabel(label),
                      Text(
                        value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      DesignLabel(detail),
                    ],
                  ),
                ),
            ],
          ),
        ),
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 9,
            children: [
              DesignTitle(context.tr('profile.streak_history')),
              DesignLabel(context.tr('profile.last_15_weeks')),
              _StreakGrid(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DesignLabel(context.tr('profile.less')),
                  DesignLabel(context.tr('common.more')),
                ],
              ),
            ],
          ),
        ),
        DesignTitle(context.tr('profile.badges')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DesignPill(
              context.tr('common.on_time'),
              icon: TmsIcons.clock,
              color: DesignColor.green,
            ),
            DesignPill(
              context.tr('profile.reviewer'),
              icon: TmsIcons.verified,
              color: DesignColor.purple,
            ),
            DesignPill(
              context.tr('profile.streak'),
              icon: TmsIcons.flame,
              color: DesignColor.amber,
            ),
          ],
        ),
        DesignButton(
          context.tr('common.performance'),
          secondary: true,
          icon: TmsIcons.insights,
          onPressed: () => TmsRoute.performance.open(context),
        ),
        DesignButton(
          context.tr('common.settings'),
          secondary: true,
          icon: TmsIcons.settings,
          onPressed: () => TmsRoute.settings.open(context),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WorkspacePreview state) async {
    var first = state.firstName, last = state.lastName, job = state.jobTitle;
    final saved = await designSheet<bool>(
      context,
      title: context.tr('common.edit_profile'),
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 11,
        children: [
          DesignField(
            label: context.tr('common.first_name'),
            initialValue: first,
            onChanged: (v) => first = v,
          ),
          DesignField(
            label: context.tr('common.last_name'),
            initialValue: last,
            onChanged: (v) => last = v,
          ),
          DesignField(
            label: context.tr('common.job_title'),
            initialValue: job,
            onChanged: (v) => job = v,
          ),
          DesignButton(
            context.tr('common.save_profile'),
            onPressed: () => Navigator.pop(sheet, true),
          ),
        ],
      ),
    );
    if (saved == true) state.saveProfile(first, last, job);
  }
}

class _StreakGrid extends StatelessWidget {
  const _StreakGrid();
  @override
  Widget build(BuildContext context) => Column(
    spacing: 3,
    children: [
      for (var i = 0; i < 7; i++)
        Row(
          spacing: 3,
          children: [
            for (var j = 0; j < 15; j++)
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: (i * 3 + j * 2) % 7 < 2
                          ? context.raised
                          : DesignColor.green.withValues(
                              alpha: .35 + (i * j % 7) * .08,
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
    ],
  );
}
