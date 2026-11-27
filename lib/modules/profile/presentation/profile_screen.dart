import 'dart:ui' show ImageFilter;

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/network_failure_localization.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/hero_gradient.dart';
import '../../../shared/design/tms_icons.dart';
import '../../authentication/domain/account.dart';
import '../../chat/application/chat_session.dart';
import '../application/profile_controller.dart';
import '../domain/profile.dart';
import 'widgets/presence_labels.dart';

part 'widgets/profile_activity.dart';
part 'widgets/profile_actions.dart';
part 'widgets/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: switch (profile) {
              AsyncValue(value: final p?) => _ProfileView(p),
              AsyncValue(error: final error?) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    DesignLabel(_profileError(context, error)),
                    DesignButton(
                      context.tr('workspaces.try_again'),
                      onPressed: () => ref.invalidate(profileProvider),
                    ),
                  ],
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView(this.p);
  final ProfileSummary p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const orange = Color(0xfff29962);
    final manager = p.reportsTo;
    final number = NumberFormat.decimalPattern(context.locale.toString());
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ProfileHeader(p),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (manager != null || p.directReportCount > 0) ...[
                DesignCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (manager != null)
                        _ProfileRelation(
                          avatar: DesignAvatar(
                            _initials(manager.name),
                            size: 36,
                            color: const Color(0xffa3c8f1),
                          ),
                          title: manager.name,
                          detail: context.tr('profile.reports_to'),
                          captionFirst: true,
                          // A live person's chat opens from the inbox.
                          route: manager.id.isEmpty
                              ? TmsRoute.conversation
                              : TmsRoute.chat,
                          beforeOpen: manager.id.isEmpty
                              ? ref
                                    .read(
                                      chatSessionProvider('business').notifier,
                                    )
                                    .openDefault
                              : null,
                        ),
                      if (manager != null && p.directReportCount > 0)
                        Divider(
                          height: 1,
                          color: context.outline.withValues(alpha: .08),
                        ),
                      if (p.directReportCount > 0)
                        _ProfileRelation(
                          avatar: _ReportAvatars(p.directReports),
                          title: context.plural(
                            'profile.direct_reports_count',
                            p.directReportCount,
                          ),
                          detail: p.team ?? '',
                          route: TmsRoute.teams,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                spacing: 10,
                children: [
                  for (final (label, value, detail, accent) in [
                    (
                      'profile.points',
                      number.format(p.points),
                      context.tr(
                        'profile.level_n',
                        namedArgs: {'n': number.format(p.level)},
                      ),
                      context.lavender,
                    ),
                    (
                      'profile.streak',
                      context.plural('profile.days_count', p.streak),
                      switch (p.bestStreak) {
                        final best? => context.tr(
                          'profile.best_n',
                          namedArgs: {'n': number.format(best)},
                        ),
                        null => '',
                      },
                      orange,
                    ),
                    (
                      'profile.badges',
                      context.tr(
                        'profile.badges_of',
                        namedArgs: {
                          'earned': number.format(p.earned.length),
                          'total': number.format(Badge.values.length),
                        },
                      ),
                      context.tr('profile.earned'),
                      context.muted,
                    ),
                  ])
                    Expanded(
                      child: DesignCard(
                        padding: const EdgeInsets.all(13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            _ProfileCaption(detail, color: accent),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              if (p.streakHistory) ...[
                const SizedBox(height: 26),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: DesignTitle(context.tr('profile.streak_history')),
                    ),
                    _ProfileCaption(context.tr('profile.last_15_weeks')),
                  ],
                ),
                const SizedBox(height: 12),
                const _StreakGrid(),
              ],
              const SizedBox(height: 26),
              DesignTitle(context.tr('profile.badges')),
              const SizedBox(height: 12),
              _BadgeGrid(p.earned),
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
    );
  }
}
