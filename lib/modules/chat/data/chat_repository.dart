import 'dart:convert';

import 'package:dio/dio.dart' show FormData;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../domain/chat_models.dart';

part 'live_chat_repository.dart';
part 'mock_chat_repository.dart';

final _chatFixtures = FutureProvider<Json>(
  (ref) async =>
      jsonDecode(
            await rootBundle.loadString('assets/fixtures/workspace_chats.json'),
          )
          as Json,
);

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) {
    final fixtures = ref.watch(_chatFixtures.future);
    final directory = ref.watch(localWorkspacesProvider.future);
    return MockChatRepository(
      fixtures: () => fixtures,
      workspace: () async => (await directory).active,
    );
  }
  return LiveChatRepository(
    ref.watch(networkCallsRepositoryProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
    me: ref.watch(accountSessionProvider.select((account) => account?.id)),
  );
});

abstract class ChatRepository {
  /// How often an open inbox or conversation should refresh; null when the
  /// data only changes locally.
  Duration? get inboxPolling;
  Duration? get threadPolling;

  Future<ChatDirectory> inbox();

  /// People who can be messaged, matching [query].
  Future<List<ChatContact>> searchPeople(ChatDirectory inbox, String query);

  /// Opens a direct message with one person, or a group chat with several.
  Future<ChatRow> start(
    ChatDirectory inbox,
    List<ChatContact> people, {
    required bool group,
    String title = '',
  });

  Future<void> respond(ChatRequest request, {required bool accept});

  /// A server conversation's latest messages, oldest first.
  Future<List<ChatMessage>> messages(String conversationId);
  Future<ChatMessage> send(String conversationId, String text);
  Future<void> markRead(String conversationId, String messageId);
  Future<ChatMessage> toggleHeart(ChatMessage message);
}
