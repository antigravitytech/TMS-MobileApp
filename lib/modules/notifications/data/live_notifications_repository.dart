import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/domain/account.dart';

final liveNotificationsRepositoryProvider =
    Provider<LiveNotificationsRepository>(
      (ref) => LiveNotificationsRepository(
        ref.watch(networkCallsRepositoryProvider),
      ),
    );

class LiveNotification {
  const LiveNotification({
    required this.id,
    required this.message,
    required this.kind,
    required this.actor,
    required this.createdAt,
    required this.isRead,
  });

  factory LiveNotification.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return LiveNotification(
      id: json['id'] as String,
      message: json['message'] as String,
      kind: json['kind'] as String,
      actor: [
        actor?['first_name'],
        actor?['last_name'],
      ].whereType<String>().join(' ').trim(),
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool,
    );
  }

  final String id, message, kind, actor;
  final DateTime createdAt;
  final bool isRead;

  LiveNotification asRead() => isRead
      ? this
      : LiveNotification(
          id: id,
          message: message,
          kind: kind,
          actor: actor,
          createdAt: createdAt,
          isRead: true,
        );
}

typedef NotificationPage = ({
  List<LiveNotification> items,
  int page,
  bool hasMore,
});

class LiveNotificationsRepository {
  const LiveNotificationsRepository(this._network);

  final NetworkCallsRepository _network;

  Future<NotificationPage> list(
    String workspaceId, {
    required bool unreadOnly,
    int page = 1,
  }) async {
    final id = Uri.encodeComponent(workspaceId);
    final data = accountPayload(
      await _network.get<Map<String, dynamic>>(
        '/notification/list-notifications/$id/',
        queryParameters: {
          'unread_only': unreadOnly,
          'page': page,
          'page_size': 20,
        },
      ),
    );
    try {
      return (
        items: (data['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(LiveNotification.fromJson)
            .toList(growable: false),
        page: page,
        hasMore: page < (data['total_pages'] as int),
      );
    } on TypeError {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    } on FormatException {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
  }

  Future<int> unreadCount(String workspaceId) async {
    final id = Uri.encodeComponent(workspaceId);
    final body = accountPayload(
      await _network.get<Map<String, dynamic>>(
        '/notification/get-unread-count/$id/',
      ),
    );
    final count = body['unread'];
    if (count is! int || count < 0) {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
    return count;
  }

  Future<void> markRead(String id) =>
      _mark('/notification/mark-read/${Uri.encodeComponent(id)}/');

  Future<void> markAllRead(String workspaceId) =>
      _mark('/notification/mark-all-read/${Uri.encodeComponent(workspaceId)}/');

  Future<void> _mark(String path) async {
    accountPayload(await _network.post<Map<String, dynamic>>(path));
  }
}
