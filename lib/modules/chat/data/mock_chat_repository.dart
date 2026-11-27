part of 'chat_repository.dart';

/// The prototype's chats from the bundled fixtures. Conversations started
/// here stay local (see `ChatSessionController`), so the server-only
/// message calls are never reached.
class MockChatRepository implements ChatRepository {
  const MockChatRepository({required this.fixtures, required this.workspace});

  final Future<Json> Function() fixtures;
  final Future<LocalWorkspace?> Function() workspace;

  @override
  Duration? get inboxPolling => null;
  @override
  Duration? get threadPolling => null;

  @override
  Future<ChatDirectory> inbox() async {
    final data = await fixtures();
    final active = await workspace();
    final kind = active?.kind ?? WorkspaceKind.business;
    final id = active?.id ?? kind.name;
    return ChatDirectory(id, kind, id == kind.name ? data[kind.name] : null);
  }

  @override
  Future<List<ChatContact>> searchPeople(
    ChatDirectory inbox,
    String query,
  ) async => [
    for (final p in inbox.people)
      if ('${p.name} ${p.role}'.toLowerCase().contains(
        query.toLowerCase().trim(),
      ))
        p,
  ];

  @override
  Future<ChatRow> start(
    ChatDirectory inbox,
    List<ChatContact> people, {
    required bool group,
    String title = '',
  }) async => group
      ? ChatRow(
          initials: people.take(2).map((p) => p.initials[0]).join(),
          color: 'a1',
          name: title.trim().isEmpty
              ? people.map((p) => p.name.split(' ').first).join(', ')
              : title.trim(),
        )
      : people.first.row;

  @override
  Future<void> respond(ChatRequest request, {required bool accept}) async {}

  @override
  Future<List<ChatMessage>> messages(String conversationId) async => const [];

  @override
  Future<ChatMessage> send(String conversationId, String text) =>
      throw UnsupportedError('Prototype threads are local');

  @override
  Future<void> markRead(String conversationId, String messageId) async {}

  @override
  Future<ChatMessage> toggleHeart(ChatMessage message) =>
      throw UnsupportedError('Prototype threads are local');
}
