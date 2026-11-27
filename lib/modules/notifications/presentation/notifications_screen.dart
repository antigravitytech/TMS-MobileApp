import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../router/tms_routes.dart';
import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../../authentication/presentation/widgets/account_action_form.dart';
import '../../home/application/live_home.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/workspace_preview.dart';
import '../application/live_notifications.dart';
import '../application/open_notification.dart';
import '../data/live_notifications_repository.dart';
import '../data/notification_previews.dart';

part 'widgets/notification_widgets.dart';
part 'live_notifications_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationKind? filter;
  bool unreadOnly = false;

  Future<void> open(NotificationPreview item) async {
    final route = await ref.read(openNotificationProvider)(item);
    if (mounted) route.open(context);
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(environmentProvider).isLive) {
      return const _LiveNotificationsScreen();
    }
    final state = ref.watch(workspacePreviewProvider);
    final read = state.readNotifications;
    final shown = notificationPreviews
        .where(
          (item) =>
              (filter == null || item.kind == filter) &&
              (!unreadOnly || !read.contains(item.id)),
        )
        .toList();
    final groups = {
      for (final day in NotificationDay.values)
        day: shown.where((item) => item.day == day).toList(),
    };
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    spacing: 10,
                    children: [
                      DesignIcon(
                        icon: TmsIcons.chevronBack,
                        label: context.tr('common.back'),
                        onPressed: () async {
                          if (!await context.router.maybePop() &&
                              context.mounted) {
                            TmsRoute.home.reset(context);
                          }
                        },
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          context.tr('common.notifications'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.45,
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () => state.markRead(
                              notificationPreviews.map((item) => item.id),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: context.lavender,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              textStyle: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                            ),
                            child: Text(
                              context.tr('notifications.mark_all_read'),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Row(
                    spacing: 8,
                    children: [
                      for (final (kind, label) in const [
                        (null, 'common.all'),
                        (NotificationKind.mention, 'notifications.mentions'),
                        (NotificationKind.review, 'notifications.reviews'),
                      ])
                        _NotificationFilter(
                          label: context.tr(label),
                          selected: filter == kind,
                          count: notificationPreviews
                              .where(
                                (item) => kind == null || item.kind == kind,
                              )
                              .length,
                          onTap: () => setState(() => filter = kind),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: _UnreadToggle(
                    selected: unreadOnly,
                    onTap: () => setState(() => unreadOnly = !unreadOnly),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    children: [
                      for (final group in groups.entries)
                        if (group.value.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                            child: Text(
                              context
                                  .tr(
                                    group.key == NotificationDay.today
                                        ? 'common.today'
                                        : 'notifications.yesterday',
                                  )
                                  .toUpperCase(),
                              style: TextStyle(
                                color: context.muted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          for (final item in group.value)
                            Padding(
                              key: ValueKey(item.id),
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _NotificationRow(
                                item: item,
                                unread: !read.contains(item.id),
                                onTap: () => open(item),
                              ),
                            ),
                        ],
                      if (shown.isEmpty)
                        DesignEntrance(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 50,
                              horizontal: 10,
                            ),
                            child: Column(
                              spacing: 16,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    color: DesignColor.green.withValues(
                                      alpha: .15,
                                    ),
                                    border: Border.all(
                                      color: DesignColor.green.withValues(
                                        alpha: .3,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    TmsIcons.check,
                                    color: DesignColor.green,
                                    size: 30,
                                  ),
                                ),
                                Text(
                                  context.tr(
                                    'notifications.youre_all_caught_up',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
