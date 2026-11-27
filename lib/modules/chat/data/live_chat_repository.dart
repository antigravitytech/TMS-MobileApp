part of 'chat_repository.dart';

/// Chat over the `/chat` API for the signed-in workspace. There is no
/// realtime channel yet, so screens poll as the integration guide suggests.
class LiveChatRepository implements ChatRepository {
  const LiveChatRepository(this._network, {this.workspace, this.me});

  final NetworkCallsRepository _network;
  final AccountWorkspace? workspace;

  /// The signed-in user, whose messages are drawn on the right.
  final String? me;

  static const heart = '❤️';

  @override
  Duration? get inboxPolling => const Duration(seconds: 15);
  @override
  Duration? get threadPolling => const Duration(seconds: 5);

  String get _workspaceId {
    final id = workspace?.id;
    if (id == null) {
      throw const AccountFailure(NetworkFailureType.unauthorized);
    }
    return Uri.encodeComponent(id);
  }

  @override
  Future<ChatDirectory> inbox() async {
    final id = _workspaceId;
    final [conversations, requests] = await Future.wait([
      _network.get<Json>(
        '/chat/list-conversations/$id/',
        queryParameters: {'page_size': 100},
      ),
      _network.get<Json>(
        '/chat/list-chat-requests/',
        queryParameters: {'page_size': 1},
      ),
    ]);
    final items = _items(accountPayload(conversations));
    final pending = _items(accountPayload(requests));
    return _parse(() {
      final rows = [for (final item in items) (item, _row(item))];
      final pinned = rows.where((r) => r.$1['is_pinned'] == true).firstOrNull;
      bool unpinned(Json item, Set<String> kinds) =>
          !identical(item, pinned?.$1) && kinds.contains(item['kind']);
      return ChatDirectory.live(
        workspace: workspace!.id,
        name: workspace!.name,
        pinned: pinned?.$2,
        tasks: [
          for (final (item, row) in rows)
            if (unpinned(item, {'task'})) row,
        ],
        recent: [
          for (final (item, row) in rows)
            if (unpinned(item, {'dm', 'group'})) row,
        ],
        groups: [
          for (final (item, row) in rows)
            if (unpinned(item, {'channel'})) row,
        ],
        request: switch (pending.firstOrNull) {
          final Json item => _request(item),
          null => null,
        },
      );
    });
  }

  @override
  Future<List<ChatContact>> searchPeople(
    ChatDirectory inbox,
    String query,
  ) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final body = accountPayload(
      await _network.get<Json>(
        '/chat/search-people/$_workspaceId/',
        queryParameters: {'q': q, 'page_size': 20},
      ),
    );
    return _parse(
      () => [
        for (final person in _items(body))
          ChatContact(
            _initials(_name(person)),
            _color(person['id'] as String),
            _name(person),
            person['job_title'] as String? ?? '',
            false,
            id: person['id'] as String,
          ),
      ],
    );
  }

  @override
  Future<ChatRow> start(
    ChatDirectory inbox,
    List<ChatContact> people, {
    required bool group,
    String title = '',
  }) async {
    final id = _workspaceId;
    final detail = accountPayload(
      group
          ? await _network.post<Json>(
              '/chat/create-conversation/$id/',
              data: {
                'kind': 'group',
                if (title.trim().isNotEmpty) 'title': title.trim(),
                'member_ids': [for (final p in people) p.id],
              },
            )
          : await _network.post<Json>(
              '/chat/start-dm/$id/',
              data: {'user_id': people.single.id},
            ),
    );
    return _parse(() => _row(detail));
  }

  @override
  Future<void> respond(ChatRequest request, {required bool accept}) async {
    final action = accept ? 'accept' : 'decline';
    accountPayload(
      await _network.post<Json>(
        '/chat/$action-chat-request/${Uri.encodeComponent(request.id)}/',
      ),
    );
  }

  @override
  Future<List<ChatMessage>> messages(String conversationId) async {
    final body = accountPayload(
      await _network.get<Json>(
        '/chat/list-messages/${Uri.encodeComponent(conversationId)}/',
        queryParameters: {'order': 'desc', 'page': 1, 'page_size': 50},
      ),
    );
    return _parse(
      () => [
        for (final m in _items(body)) _message(m),
      ].reversed.toList(growable: false),
    );
  }

  @override
  Future<ChatMessage> send(String conversationId, String text) async {
    final body = accountPayload(
      await _network.post<Json>(
        '/chat/send-message/${Uri.encodeComponent(conversationId)}/',
        data: FormData.fromMap({'body': text.trim()}),
      ),
    );
    return _parse(() => _message(body['message'] as Json));
  }

  @override
  Future<void> markRead(String conversationId, String messageId) async {
    accountPayload(
      await _network.post<Json>(
        '/chat/mark-read/${Uri.encodeComponent(conversationId)}/',
        data: {'message_id': messageId},
      ),
    );
  }

  @override
  Future<ChatMessage> toggleHeart(ChatMessage message) async {
    final body = accountPayload(
      await _network.post<Json>(
        '/chat/toggle-reaction/${Uri.encodeComponent(message.id)}/',
        data: {'emoji': heart},
      ),
    );
    return _parse(() => _message(body));
  }

  // ----- Mapping -----

  static List<Json> _items(Json page) =>
      (page['items'] as List).cast<Json>().toList(growable: false);

  static String _name(Json? person) => [
    person?['first_name'],
    person?['last_name'],
  ].whereType<String>().join(' ').trim();

  static String _initials(String name) => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  /// One of the prototype's avatar tints, stable for an id.
  static String _color(String id) =>
      'a${id.codeUnits.fold(0, (a, b) => a + b) % 8 + 1}';

  ChatRow _row(Json item) {
    final kind = item['kind'] as String;
    final peer = item['peer'] as Json?;
    final group = item['group'] as Json?;
    final task = item['task'] as Json?;
    final title = item['title'] as String? ?? '';
    final name = switch (kind) {
      'dm' => _name(peer),
      'channel' when group != null => '${group['name']} › $title',
      'task' when task?['reference'] is String =>
        '${task!['reference']} · $title',
      _ =>
        title.isNotEmpty
            ? title
            : [
                for (final p in (item['member_preview'] as List? ?? const []))
                  _name(p as Json).split(' ').first,
              ].join(', '),
    };
    final last = item['last_message'] as Json?;
    final mentions = item['mention_count'] as int? ?? 0;
    final unread = item['unread_count'] as int? ?? 0;
    return ChatRow(
      id: item['id'] as String,
      initials: kind == 'channel'
          ? (group?['glyph'] as String? ?? _initials(name))
          : _initials(name),
      color: kind == 'channel' && group?['color'] is String
          ? group!['color'] as String
          : _color(peer?['id'] as String? ?? item['id'] as String),
      name: name,
      preview: last?['preview'] as String? ?? '',
      badge: mentions > 0 ? '@' : (unread > 0 ? '$unread' : ''),
      at: DateTime.tryParse(
        last?['created_at'] as String? ?? item['updated_at'] as String? ?? '',
      )?.toLocal(),
    );
  }

  ChatRequest _request(Json item) {
    final conversation = item['conversation'] as Json;
    final requester = item['requester'] as Json;
    final name = _name(requester);
    return ChatRequest(
      id: conversation['id'] as String,
      row: ChatRow(
        id: conversation['id'] as String,
        initials: _initials(name),
        color: _color(requester['id'] as String),
        name: name,
      ),
      role: 'chat.labels.external',
      detail: requester['job_title'] as String? ?? requester['email'] as String,
    );
  }

  ChatMessage _message(Json m) {
    final sender = m['sender'] as Json?;
    final type = m['type'] as String;
    final hearts = (m['reactions'] as List? ?? const [])
        .cast<Json>()
        .where((r) => r['emoji'] == heart)
        .firstOrNull;
    final body = m['body'] as String?;
    return ChatMessage(
      id: m['id'] as String,
      body: switch (type) {
        'task' => body ?? (m['task'] as Json?)?['title'] as String? ?? '',
        'birthday' => body?.isNotEmpty == true ? body! : '🎂',
        'system' =>
          body ?? (m['system_event'] as String? ?? '').replaceAll('_', ' '),
        _ => body ?? '',
      },
      sender: _name(sender),
      mine: sender != null && sender['id'] == me,
      system: type == 'system',
      at: DateTime.parse(m['created_at'] as String).toLocal(),
      hearts: hearts?['count'] as int? ?? 0,
      hearted: hearts?['reacted_by_me'] as bool? ?? false,
    );
  }

  static T _parse<T>(T Function() read) {
    try {
      return read();
    } on TypeError {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    } on FormatException {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
  }
}
