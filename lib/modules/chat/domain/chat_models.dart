import '../../workspace/domain/workspace_kind.dart';

typedef Json = Map<String, dynamic>;

/// A conversation in the inbox (or a person to open one with).
///
/// Mock rows carry ready-made display strings. Live rows also carry the
/// conversation [id] and the time of the last message in [at].
class ChatRow {
  const ChatRow({
    required this.initials,
    required this.color,
    required this.name,
    this.preview = '',
    this.time = '',
    this.badge = '',
    this.online = false,
    this.id = '',
    this.at,
  });
  factory ChatRow.fromJson(Json row) => ChatRow(
    initials: row['initials'],
    color: row['color'],
    name: row['name'],
    preview: row['preview'],
    time: row['time'],
    badge: row['badge'],
    online: row['online'],
  );
  final String initials, color, name, preview, time;

  /// An unread count, or `@` when someone mentioned me.
  final String badge;
  final bool online;

  /// The server conversation id; empty for the prototype's local threads.
  final String id;
  final DateTime? at;
}

/// Someone who can be messaged.
class ChatContact {
  const ChatContact(
    this.initials,
    this.color,
    this.name,
    this.role,
    this.online, {
    this.id = '',
  });
  factory ChatContact.fromList(List row) => ChatContact(
    row[0],
    row[1],
    row[2],
    row.length > 3 ? row[3] : '',
    row.length <= 4 || row[4] == 1,
  );
  final String initials, color, name, role, id;
  final bool online;
  ChatRow get row =>
      ChatRow(initials: initials, color: color, name: name, online: online);
}

/// An incoming chat request from someone outside the workspace.
class ChatRequest {
  const ChatRequest({
    required this.row,
    required this.role,
    required this.detail,
    this.id = '',
    this.note = 'chat.request_note',
    this.accepted = 'chat.request_accepted',
  });

  /// Conversation id of the pending request.
  final String id;
  final ChatRow row;

  /// A copy key in the prototype, the requester's job title when live.
  final String role;
  final String detail;

  /// Copy keys: the privacy note under the buttons and the accepted toast
  /// (which may use `{name}`).
  final String note, accepted;
}

/// A message in a server conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    required this.sender,
    required this.mine,
    required this.at,
    this.system = false,
    this.hearts = 0,
    this.hearted = false,
  });
  final String id, body, sender;
  final bool mine, system, hearted;
  final DateTime at;

  /// How many ❤️ reactions, and whether one is mine.
  final int hearts;
}

/// Everything the Chat inbox shows.
class ChatDirectory {
  ChatDirectory(this.workspace, this.kind, Json? data)
    : name = data?['name'] ?? '',
      filters = List<String>.from(data?['filters'] ?? const []),
      section = data?['section'] ?? '',
      pinned = data == null ? null : ChatRow.fromJson(data['pinned']),
      tasks = [
        if (data?['task'] case [
          final String title,
          final String preview,
          final String time,
        ])
          ChatRow(
            initials: '',
            color: 'a3',
            name: title,
            preview: preview,
            time: time,
            badge: '@',
          ),
      ],
      recent = _rows(data?['recent']),
      groups = _rows(data?['groups']),
      people = _people(data?['people']),
      online = _people(data?['online']),
      request = switch (data?['request']) {
        [
          final String initials,
          final String color,
          final String name,
          final String role,
          final String detail,
          final String note,
          final String accepted,
        ] =>
          ChatRequest(
            row: ChatRow(initials: initials, color: color, name: name),
            role: role,
            detail: detail,
            note: note,
            accepted: accepted,
          ),
        _ => null,
      },
      example = data == null ? null : ChatExample(data['thread']);

  /// A server inbox.
  ChatDirectory.live({
    required this.workspace,
    required this.name,
    required this.pinned,
    required this.tasks,
    required this.recent,
    required this.groups,
    required this.request,
  }) : kind = WorkspaceKind.business,
       filters = const [
         'chat.labels.all',
         'chat.labels.unread',
         'chat.labels.mentions',
       ],
       section = 'chat.labels.task_conversations',
       people = const [],
       online = const [],
       example = null;

  final String workspace, name, section;
  final WorkspaceKind kind;
  final ChatRow? pinned;
  final List<String> filters;
  final List<ChatRow> tasks, groups, recent;
  final List<ChatContact> people, online;
  final ChatRequest? request;
  final ChatExample? example;
  static List<ChatRow> _rows(List? rows) => [
    for (final row in rows ?? []) ChatRow.fromJson(row),
  ];
  static List<ChatContact> _people(List? rows) => [
    for (final row in rows ?? []) ChatContact.fromList(row),
  ];
}

/// The prototype's sample thread.
class ChatExample {
  ChatExample(Json json)
    : peer = ChatContact.fromList(json['peer']),
      intro = json['intro'],
      mine = json['mine'],
      reply = json['reply'],
      voice = json['voice'],
      card = List<String>.from(json['card']);
  final ChatContact peer;
  final String intro, mine, reply, voice;
  final List<String> card;
}
