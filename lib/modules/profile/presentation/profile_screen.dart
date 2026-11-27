import 'dart:ui' show ImageFilter;

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/hero_gradient.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../chat/application/chat_session.dart';

part 'widgets/profile_activity.dart';
part 'widgets/profile_actions.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspacePreviewProvider);
    Widget action(IconData icon, String label, VoidCallback tap) => IconButton(
      onPressed: tap,
      tooltip: context.tr(label),
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xfff3f5fe),
        backgroundColor: const Color(0x17ffffff),
        minimumSize: const Size.square(44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x22ffffff)),
        ),
      ),
    );
    const orange = Color(0xfff29962);
    final statusColor = switch (state.status) {
      'profile.available' => DesignColor.green,
      'profile.in_a_meeting' => DesignColor.amber,
      'profile.focusing' => DesignColor.purple,
      _ => const Color(0xff9397ab),
    };
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                CustomPaint(
                  painter: const DesignHeroGradient(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            action(
                              TmsIcons.chevronBack,
                              'common.back',
                              () async {
                                if (!await context.router.maybePop() &&
                                    context.mounted) {
                                  TmsRoute.home.reset(context);
                                }
                              },
                            ),
                            action(
                              TmsIcons.edit,
                              'common.edit_profile',
                              () => TmsRoute.settings.open(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          spacing: 16,
                          children: [
                            DecoratedBox(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x22ffffff),
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: DesignAvatar(
                                [state.firstName, state.lastName]
                                    .where((value) => value.isNotEmpty)
                                    .map(
                                      (value) =>
                                          value.characters.first.toUpperCase(),
                                    )
                                    .join(),
                                size: 84,
                                color: const Color(0xffc4bdf6),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${state.firstName} ${state.lastName}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      height: 1.12,
                                      letterSpacing: -.6,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xfff3f5fe),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    context.tr(
                                      'profile.jobtitle_engineering',
                                      namedArgs: {'jobTitle': state.jobTitle},
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Color(0xffc9cbe0),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      backgroundColor: const Color(0x17ffffff),
                                      foregroundColor: const Color(0xfff3f5fe),
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    onPressed: () => _status(context, state),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: 7,
                                      children: [
                                        CircleAvatar(
                                          radius: 4,
                                          backgroundColor: statusColor,
                                        ),
                                        Flexible(
                                          child: Text(context.tr(state.status)),
                                        ),
                                        const Icon(
                                          TmsIcons.chevronDown,
                                          size: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final (label, color) in const [
                              ('common.member', DesignColor.teal),
                              ('common.line_manager', Color(0xffd2cefd)),
                              ('profile.pm', Color(0xffd2cefd)),
                              ('common.team_lead', Color(0xffd2cefd)),
                            ])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .17),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  context.tr(label),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DesignCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _ProfileRelation(
                              avatar: const DesignAvatar(
                                'IM',
                                size: 36,
                                color: Color(0xffa3c8f1),
                              ),
                              title: 'Ibrahim Musa',
                              detail: context.tr('profile.reports_to'),
                              captionFirst: true,
                              route: TmsRoute.conversation,
                              beforeOpen: ref
                                  .read(
                                    chatSessionProvider('business').notifier,
                                  )
                                  .openDefault,
                            ),
                            Divider(
                              height: 1,
                              color: context.outline.withValues(alpha: .08),
                            ),
                            _ProfileRelation(
                              avatar: const _ReportAvatars(),
                              title: context.tr('profile.4_direct_reports'),
                              detail: 'Tech Team',
                              route: TmsRoute.teams,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        spacing: 10,
                        children: [
                          for (final (label, value, detail, accent) in [
                            (
                              'profile.points',
                              NumberFormat.decimalPattern(
                                context.locale.toString(),
                              ).format(640),
                              'profile.level_2',
                              context.lavender,
                            ),
                            (
                              'profile.streak',
                              context.tr('profile.4_days'),
                              'profile.best_11',
                              orange,
                            ),
                            (
                              'profile.badges',
                              context.tr('profile.3_of_5'),
                              'profile.earned',
                              context.muted,
                            ),
                          ])
                            Expanded(
                              child: DesignCard(
                                padding: const EdgeInsets.all(13),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  spacing: 2,
                                  children: [
                                    _ProfileCaption(context.tr(label)),
                                    Text(
                                      value,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    _ProfileCaption(
                                      context.tr(detail),
                                      color: accent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: DesignTitle(
                              context.tr('profile.streak_history'),
                            ),
                          ),
                          _ProfileCaption(context.tr('profile.last_15_weeks')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _StreakGrid(),
                      const SizedBox(height: 26),
                      DesignTitle(context.tr('profile.badges')),
                      const SizedBox(height: 12),
                      const _BadgeGrid(),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.foreground,
                          side: BorderSide(color: context.outline),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => TmsRoute.performance.open(context),
                        icon: const Icon(TmsIcons.file, size: 18),
                        label: Text(context.tr('profile.appraisal_export')),
                      ),
                    ],
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
