import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const items = [
    (
      'notifications.sarah_submitted_a_task_for_review',
      'notifications.onboarding_flow_usability_test_12m',
      'notifications.review',
      TmsIcons.checkCircle,
      TmsRoute.approvals,
    ),
    (
      'notifications.tunde_mentioned_you',
      'notifications.customer_portal_revamp_general_28m',
      'common.chat',
      TmsIcons.chat,
      TmsRoute.conversation,
    ),
    (
      'notifications.daily_report_due_at_5_00_pm',
      'notifications.tech_team_45m',
      'notifications.work',
      TmsIcons.report,
      TmsRoute.reports,
    ),
    (
      'notifications.its_tundes_birthday',
      'notifications.send_a_card_1h',
      'notifications.work',
      TmsIcons.birthday,
      TmsRoute.birthdays,
    ),
    (
      'notifications.new_task_from_ibrahim',
      'notifications.q4_hiring_plan_for_tech_team_2h',
      'notifications.work',
      TmsIcons.checkSquare,
      TmsRoute.task,
    ),
    (
      'notifications.amaka_sent_you_a_message',
      'notifications.chat_yesterday',
      'common.chat',
      TmsIcons.chat,
      TmsRoute.conversation,
    ),
  ];
  static const tabs = [
    'common.all',
    'notifications.review',
    'common.chat',
    'notifications.work',
  ];
  int tab = 0;
  bool unreadOnly = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspacePreviewProvider);
    final shown = [
      for (final (i, item) in items.indexed)
        if ((tab == 0 || item.$3 == tabs[tab]) &&
            (!unreadOnly || !state.readNotifications.contains(i)))
          (i, item),
    ];
    return DesignPage(
      title: context.tr('common.notifications'),
      children: [
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('notifications.unread_only')),
                value: unreadOnly,
                onChanged: (value) => setState(() => unreadOnly = value),
              ),
            ),
            TextButton(
              onPressed: () => state.markRead(Iterable.generate(items.length)),
              child: Text(context.tr('notifications.mark_all_read')),
            ),
          ],
        ),
        DesignChoices(
          items: tabs.map(context.tr).toList(),
          selected: tab,
          onChanged: (i) => setState(() => tab = i),
        ),
        if (shown.isEmpty)
          DesignEmpty(
            context.tr('notifications.youre_all_caught_up'),
            context.tr('notifications.new_updates_will_appear_here'),
          )
        else
          DesignSection(
            children: [
              for (final (i, item) in shown)
                DesignTile(
                  title: context.tr(item.$1),
                  subtitle: context.tr(item.$2),
                  icon: item.$4,
                  trailing: state.readNotifications.contains(i)
                      ? null
                      : const CircleAvatar(
                          radius: 4.5,
                          backgroundColor: DesignColor.purple,
                        ),
                  onTap: () {
                    state.markRead([i]);
                    item.$5.open(context);
                  },
                ),
            ],
          ),
      ],
    );
  }
}
