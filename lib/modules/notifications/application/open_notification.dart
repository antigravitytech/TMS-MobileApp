import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../chat/application/chat_session.dart';
import '../../chat/data/chat_directory.dart';
import '../../workspace/application/workspace_preview.dart';
import '../data/notification_previews.dart';

final openNotificationProvider =
    Provider<Future<TmsRoute> Function(NotificationPreview)>((ref) {
      return (notification) async {
        ref.read(workspacePreviewProvider).markRead([notification.id]);
        switch (notification.kind) {
          case NotificationKind.review:
            return TmsRoute.approvals;
          case NotificationKind.birthday:
            return TmsRoute.birthdays;
          case NotificationKind.mention:
            final directory = await ref
                .read(chatDirectoryProvider.future)
                .then<ChatDirectory?>(
                  (directory) => directory,
                  onError: (Object _) => null,
                );
            if (!ref.mounted || directory == null) return TmsRoute.chat;
            final thread = directory.recent
                .where((item) => item.initials == notification.initials)
                .firstOrNull;
            if (thread == null) return TmsRoute.chat;
            ref
                .read(chatSessionProvider(directory.workspace).notifier)
                .open(thread);
            return TmsRoute.conversation;
        }
      };
    });
