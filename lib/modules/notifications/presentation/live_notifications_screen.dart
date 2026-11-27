part of 'notifications_screen.dart';

class _LiveNotificationsScreen extends ConsumerWidget {
  const _LiveNotificationsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(accountSessionProvider, (previous, next) {
      if (previous != null && next == null && context.mounted) {
        TmsRoute.signIn.reset(context);
      }
    });
    final directory = ref.watch(accountWorkspacesProvider);
    final workspace = ref.watch(activeLiveWorkspaceProvider);
    if (workspace == null && directory.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (workspace == null || directory.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('common.notifications'))),
        body: Center(
          child: TextButton(
            onPressed: () => TmsRoute.home.reset(context),
            child: Text(context.tr('common.home')),
          ),
        ),
      );
    }

    final provider = liveNotificationsProvider(workspace.id);
    final inbox = ref.watch(provider);
    final busy = inbox.isLoading || (inbox.value?.busy ?? false);
    final controller = ref.read(provider.notifier);
    final unread = ref.watch(notificationUnreadProvider(workspace.id)).value;

    Future<void> act(Future<void> Function() operation) async {
      try {
        await operation();
      } catch (error) {
        if (context.mounted) {
          designToast(context, _notificationError(context, error));
        }
      }
    }

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
                        child: Text(
                          context.tr('common.notifications'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Flexible(
                        child: TextButton(
                          onPressed: busy || !inbox.hasValue || unread == 0
                              ? null
                              : () => act(controller.markAllRead),
                          child: Text(
                            context.tr('notifications.mark_all_read'),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _UnreadToggle(
                    selected: controller.unreadOnly,
                    onTap: busy
                        ? null
                        : () => act(
                            () => controller.setUnreadOnly(
                              !controller.unreadOnly,
                            ),
                          ),
                  ),
                ),
                if (busy && inbox.hasValue) const LinearProgressIndicator(),
                Expanded(
                  child: inbox.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_notificationError(context, error)),
                            TextButton(
                              onPressed: controller.refresh,
                              child: Text(context.tr('workspaces.try_again')),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (snapshot) => RefreshIndicator(
                      onRefresh: controller.refresh,
                      child: _LiveNotificationList(
                        page: snapshot.page,
                        onLoadMore: busy
                            ? null
                            : () => act(controller.loadMore),
                        onRead: busy
                            ? null
                            : (item) => act(() => controller.markRead(item)),
                      ),
                    ),
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

String _notificationError(BuildContext context, Object error) =>
    error is AccountFailure
    ? accountErrorMessage(context, error)
    : context.tr('network.errors.unknown');

class _LiveNotificationList extends StatelessWidget {
  const _LiveNotificationList({
    required this.page,
    required this.onLoadMore,
    required this.onRead,
  });

  final NotificationPage page;
  final VoidCallback? onLoadMore;
  final ValueChanged<LiveNotification>? onRead;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final yesterday = DateUtils.addDaysToDate(DateTime.now(), -1);
    final groups = <DateTime, List<LiveNotification>>{};
    for (final item in page.items) {
      final day = DateUtils.dateOnly(item.createdAt.toLocal());
      groups.putIfAbsent(day, () => []).add(item);
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 44),
            child: Center(
              child: Text(context.tr('notifications.youre_all_caught_up')),
            ),
          ),
        for (final group in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
            child: Text(
              (DateUtils.isSameDay(group.key, DateTime.now())
                      ? context.tr('common.today')
                      : DateUtils.isSameDay(group.key, yesterday)
                      ? context.tr('notifications.yesterday')
                      : DateFormat.yMMMd(locale).format(group.key))
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
            _NotificationTile(
              key: ValueKey(item.id),
              initials: item.actor
                  .split(RegExp(r'\s+'))
                  .where((name) => name.isNotEmpty)
                  .take(2)
                  .map((name) => name.characters.first.toUpperCase())
                  .join(),
              avatar: context.lavender,
              icon: item.kind.contains('mention')
                  ? TmsIcons.mention
                  : TmsIcons.notifications,
              badge: DesignColor.purple,
              message: item.message,
              time: DateFormat.jm(locale).format(item.createdAt.toLocal()),
              unread: !item.isRead,
              onTap: item.isRead || onRead == null ? null : () => onRead!(item),
            ),
        ],
        if (page.hasMore)
          TextButton(
            onPressed: onLoadMore,
            child: Text(context.tr('notifications.load_more')),
          ),
      ],
    );
  }
}
