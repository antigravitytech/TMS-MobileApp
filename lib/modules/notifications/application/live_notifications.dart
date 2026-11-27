import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../data/live_notifications_repository.dart';

final notificationUnreadProvider = FutureProvider.autoDispose
    .family<int, String>((ref, workspace) {
      final accountId = ref.watch(
        accountSessionProvider.select((account) => account?.id),
      );
      if (accountId == null) return 0;
      return ref
          .watch(liveNotificationsRepositoryProvider)
          .unreadCount(workspace);
    });

typedef NotificationInbox = ({NotificationPage page, bool busy});

final liveNotificationsProvider = AsyncNotifierProvider.autoDispose
    .family<LiveNotifications, NotificationInbox, String>(
      LiveNotifications.new,
    );

class LiveNotifications extends AsyncNotifier<NotificationInbox> {
  LiveNotifications(this.workspaceId);

  final String workspaceId;
  bool _unreadOnly = false;
  bool get unreadOnly => _unreadOnly;
  bool get _busy => state.isLoading || (state.value?.busy ?? false);

  LiveNotificationsRepository get _repository =>
      ref.read(liveNotificationsRepositoryProvider);

  @override
  Future<NotificationInbox> build() async {
    final accountId = ref.watch(
      accountSessionProvider.select((account) => account?.id),
    );
    final NotificationPage page = accountId == null
        ? (items: const <LiveNotification>[], page: 1, hasMore: false)
        : await _read(1);
    return (page: page, busy: false);
  }

  Future<NotificationPage> _read(int page) => _withSession(
    () => _repository.list(workspaceId, unreadOnly: _unreadOnly, page: page),
  );

  Future<void> refresh() async {
    if (_busy) return;
    final previous = state.value?.page;
    state = previous == null
        ? const AsyncLoading()
        : AsyncData((page: previous, busy: true));
    final result = await AsyncValue.guard(
      () async => (page: await _read(1), busy: false),
    );
    if (ref.mounted) {
      ref.invalidate(notificationUnreadProvider(workspaceId));
      state = result;
    }
  }

  Future<void> loadMore() async {
    final current = state.value?.page;
    if (_busy || current == null || !current.hasMore) return;
    await _update(current, () async {
      final next = await _read(current.page + 1);
      final seen = current.items.map((item) => item.id).toSet();
      return (
        items: [
          ...current.items,
          ...next.items.where((item) => seen.add(item.id)),
        ],
        page: next.page,
        hasMore: next.hasMore,
      );
    });
  }

  Future<void> setUnreadOnly(bool value) async {
    if (_busy || _unreadOnly == value) return;
    _unreadOnly = value;
    await refresh();
  }

  Future<void> markRead(LiveNotification item) => _mark(item);

  Future<void> markAllRead() => _mark(null);

  Future<void> _mark(LiveNotification? item) async {
    final current = state.value?.page;
    if (_busy || current == null || item?.isRead == true) return;
    await _update(current, () async {
      await _withSession(
        () => item == null
            ? _repository.markAllRead(workspaceId)
            : _repository.markRead(item.id),
      );
      if (!ref.mounted) return current;
      ref.invalidate(notificationUnreadProvider(workspaceId));

      final updated = (
        items: [
          for (final row in current.items)
            if (item == null || row.id == item.id) row.asRead() else row,
        ],
        page: current.page,
        hasMore: current.hasMore,
      );
      // Removing an unread item shifts the server's page boundaries.
      if (!_unreadOnly) return updated;
      if (item == null) {
        return (items: const <LiveNotification>[], page: 1, hasMore: false);
      }
      try {
        return await _read(1);
      } catch (_) {
        if (ref.mounted) {
          state = AsyncData((
            page: (
              items: updated.items.where((item) => !item.isRead).toList(),
              page: 1,
              hasMore: false,
            ),
            busy: false,
          ));
        }
        rethrow;
      }
    });
  }

  Future<void> _update(
    NotificationPage previous,
    Future<NotificationPage> Function() operation,
  ) async {
    state = AsyncData((page: previous, busy: true));
    try {
      final value = await operation();
      if (ref.mounted) state = AsyncData((page: value, busy: false));
    } catch (_) {
      if (ref.mounted && state.value?.busy == true) {
        state = AsyncData((page: previous, busy: false));
      }
      rethrow;
    }
  }

  Future<T> _withSession<T>(Future<T> Function() operation) async {
    final session = ref.read(accountSessionProvider.notifier);
    final accountId = ref.read(accountSessionProvider)?.id;
    try {
      return await operation();
    } on AccountFailure catch (error) {
      if (ref.mounted && accountId != null) {
        await session.expire(error, accountId: accountId);
      }
      rethrow;
    }
  }
}
