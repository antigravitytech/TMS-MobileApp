import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/tms_routes.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../application/live_notifications.dart';

class LiveNotificationBell extends ConsumerWidget {
  const LiveNotificationBell({super.key, required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread =
        ref.watch(notificationUnreadProvider(workspaceId)).value ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DesignIcon(
          icon: TmsIcons.notifications,
          label: context.tr('common.notifications'),
          onPressed: () => TmsRoute.notifications.open(context),
        ),
        if (unread > 0)
          PositionedDirectional(
            top: 2,
            end: 1,
            child: IgnorePointer(
              child: Semantics(
                label: context.plural(
                  'notifications.unread_count',
                  unread,
                  name: 'count',
                ),
                child: ExcludeSemantics(
                  child: Badge(
                    backgroundColor: DesignColor.red,
                    label: Text(
                      NumberFormat.compact(
                        locale: context.locale.toString(),
                      ).format(unread),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
