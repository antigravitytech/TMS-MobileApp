import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/quick_create.dart';
import '../../tasks/presentation/task_card.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../workspace/presentation/workspace_home.dart';
import '../../../shared/design/tms_icons.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspacePreviewProvider);
    final workspace = ref.watch(localWorkspacesProvider).asData?.value.active;
    if (workspace != null) {
      return WorkspaceHome(
        key: ValueKey(workspace.id),
        workspace: workspace,
        companyName: state.workspace,
      );
    }
    final due = state.tasks
        .where(
          (t) =>
              t.group == 'Mine' && t.due == 'Today' && t.status != 'Completed',
        )
        .toList();
    final waiting = state.reviewQueue.toList();
    final greeting = context.tr('home.greeting').split('{name}');
    return DesignPage(
      title: state.workspace,
      subtitle: context.tr('common.monday_23_november'),
      tab: TmsRoute.home,
      floatingActionButton: const QuickCreate(),
      actions: [
        Badge(
          smallSize: 7,
          backgroundColor: DesignColor.red,
          isLabelVisible: state.readNotifications.length < 6,
          offset: const Offset(-5, 6),
          child: DesignIcon(
            icon: TmsIcons.notifications,
            label: context.tr('common.notifications'),
            onPressed: () => TmsRoute.notifications.open(context),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: context.tr('home.my_profile'),
          onPressed: () => TmsRoute.profile.open(context),
          icon: const DesignAvatar('CO'),
        ),
      ],
      children: [
        Text.rich(
          TextSpan(
            text: greeting.first,
            children: [
              for (final suffix in greeting.skip(1)) ...[
                TextSpan(
                  text: state.firstName,
                  style: TextStyle(color: context.lavender),
                ),
                TextSpan(text: suffix),
              ],
            ],
          ),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -.9,
          ),
        ),
        DesignCard(
          onTap: () => TmsRoute.search.open(context),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            spacing: 9,
            children: [
              Icon(TmsIcons.search, color: context.muted),
              Expanded(
                child: DesignLabel(
                  context.tr('common.search_tasks_people_or_actions'),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.raised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  TmsIcons.microphone,
                  size: 19,
                  color: context.lavender,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              DesignPill(
                context.tr(
                  'home.due_today',
                  namedArgs: {'count': due.length.toString()},
                ),
                icon: TmsIcons.dot,
                color: DesignColor.amber,
                onTap: () => TmsRoute.tasks.open(context),
              ),
              DesignPill(
                context.tr('home.0_overdue'),
                icon: TmsIcons.dot,
                color: DesignColor.red,
                onTap: () => TmsRoute.tasks.open(context),
              ),
              DesignPill(
                context.tr(
                  'home.to_review',
                  namedArgs: {'count': waiting.length.toString()},
                ),
                icon: TmsIcons.dot,
                color: DesignColor.purple,
                onTap: () => TmsRoute.approvals.open(context),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: DesignMotion.duration(context, DesignMotion.page),
          child: state.birthdayDismissed
              ? const SizedBox(width: double.infinity)
              : _BirthdayBanner(onClose: state.dismissBirthday),
        ),
        Row(
          children: [
            Expanded(child: DesignTitle(context.tr('home.daily_report'))),
            DesignPill(
              state.reportSent
                  ? context.tr('home.sent_today')
                  : context.tr('home.due_by_5_00_pm'),
              color: state.reportSent ? DesignColor.green : DesignColor.amber,
            ),
          ],
        ),
        DesignCard(
          child: Column(
            spacing: 14,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: 12,
                children: [
                  const CircleAvatar(
                    backgroundColor: DesignColor.teal,
                    foregroundColor: DesignColor.ink,
                    child: Icon(TmsIcons.report, size: 18),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DesignTitle(context.tr('common.daily_status_update')),
                        DesignLabel(
                          context.tr('home.for_ibrahim_musa_weekdays'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 6; i++)
                    Flexible(
                      child: Column(
                        spacing: 5,
                        children: [
                          Icon(
                            i == 5 && !state.reportSent
                                ? TmsIcons.circle
                                : [0, 3].contains(i)
                                ? TmsIcons.circle
                                : TmsIcons.checkCircleFilled,
                            color: i == 5 && !state.reportSent
                                ? DesignColor.purple
                                : [0, 3].contains(i)
                                ? DesignColor.red
                                : DesignColor.green,
                            size: 26,
                          ),
                          DesignLabel(
                            [
                              context.tr('home.t'),
                              context.tr('home.w'),
                              context.tr('home.t'),
                              context.tr('home.f'),
                              context.tr('home.f'),
                              context.tr('common.today'),
                            ][i],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              DesignButton(
                state.reportSent
                    ? context.tr('home.view_daily_report')
                    : context.tr('home.log_todays_report'),
                secondary: true,
                onPressed: () => TmsRoute.reports.open(context),
              ),
            ],
          ),
        ),
        DesignTitle(
          context.tr(
            'home.due_today_heading',
            namedArgs: {'count': due.length.toString()},
          ),
          action: context.tr('home.view_all'),
          onTap: () => TmsRoute.tasks.open(context),
        ),
        for (final task in due) TaskCard(task),
        DesignTitle(
          context.tr(
            'home.review_heading',
            namedArgs: {'count': waiting.length.toString()},
          ),
          action: context.tr('home.open_queue'),
          onTap: () => TmsRoute.approvals.open(context),
        ),
        for (final task in waiting.take(2))
          DesignCard(
            key: ValueKey(task.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 9,
              children: [
                DesignLabel('${task.person} · ${task.project}'),
                Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: DesignButton(
                        context.tr('common.return'),
                        secondary: true,
                        onPressed: () => TmsRoute.approvals.open(context),
                      ),
                    ),
                    Expanded(
                      child: DesignButton(
                        context.tr('common.approve'),
                        color: DesignColor.green,
                        icon: TmsIcons.check,
                        onPressed: () {
                          state.review(task, approve: true);
                          designToast(
                            context,
                            context.tr(
                              'approvals.approved_notice',
                              namedArgs: {'task': task.title},
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        DesignTitle(
          context.tr('home.team_today'),
          action: context.tr('home.summaries'),
          onTap: () => TmsRoute.reports.open(context),
        ),
        DesignSection(
          children: [
            DesignTile(
              title: context.tr('home.daily_reports'),
              subtitle: context.tr('common.2_of_5_sent_1_blocker'),
              icon: TmsIcons.report,
              onTap: () => TmsRoute.reports.open(context),
            ),
            DesignTile(
              title: context.tr('common.attendance'),
              subtitle: context.tr('home.tech_team_4_in'),
              icon: TmsIcons.clock,
              onTap: () => TmsRoute.attendance.open(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _BirthdayBanner extends StatelessWidget {
  const _BirthdayBanner({required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xff6940c8), Color(0xffa63990)],
      ),
      borderRadius: BorderRadius.circular(17),
      boxShadow: [
        BoxShadow(
          color: const Color(0xff9c3e9e).withValues(alpha: .25),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(11, 6, 2, 6),
      child: Row(
        spacing: 6,
        children: [
          const Icon(TmsIcons.birthday, color: Colors.white, size: 21),
          Expanded(
            child: Text(
              context.tr('home.happy_birthday'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: TextButton(
              onPressed: () => TmsRoute.birthdays.open(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff5437a5),
              ),
              child: Text(context.tr('home.wish_tunde')),
            ),
          ),
          IconButton(
            tooltip: context.tr('home.dismiss_birthday_banner'),
            onPressed: onClose,
            icon: const Icon(TmsIcons.close, color: Colors.white70, size: 16),
          ),
        ],
      ),
    ),
  );
}
