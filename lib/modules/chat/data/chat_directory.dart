import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/workspace_kind.dart';

typedef Json = Map<String, dynamic>;

class ChatRow {
  const ChatRow({
    required this.initials,
    required this.color,
    required this.name,
    this.preview = '',
    this.time = '',
    this.badge = '',
    this.online = false,
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
  final String initials, color, name, preview, time, badge;
  final bool online;
}

class ChatContact {
  const ChatContact(
    this.initials,
    this.color,
    this.name,
    this.role,
    this.online,
  );
  factory ChatContact.fromList(List row) => ChatContact(
    row[0],
    row[1],
    row[2],
    row.length > 3 ? row[3] : '',
    row.length <= 4 || row[4] == 1,
  );
  final String initials, color, name, role;
  final bool online;
  ChatRow get row =>
      ChatRow(initials: initials, color: color, name: name, online: online);
}

class ChatDirectory {
  ChatDirectory(this.workspace, this.kind, Json? data)
    : name = data?['name'] ?? '',
      filters = List<String>.from(data?['filters'] ?? const []),
      section = data?['section'] ?? '',
      pinned = data == null ? null : ChatRow.fromJson(data['pinned']),
      task = List<String>.from(data?['task'] ?? const []),
      recent = _rows(data?['recent']),
      groups = _rows(data?['groups']),
      people = _people(data?['people']),
      online = _people(data?['online']),
      request = List<String>.from(data?['request'] ?? const []),
      example = data == null ? null : ChatExample(data['thread']);
  final String workspace, name, section;
  final WorkspaceKind kind;
  final ChatRow? pinned;
  final List<String> filters, task, request;
  final List<ChatRow> groups, recent;
  final List<ChatContact> people, online;
  final ChatExample? example;
  static List<ChatRow> _rows(List? rows) => [
    for (final row in rows ?? []) ChatRow.fromJson(row),
  ];
  static List<ChatContact> _people(List? rows) => [
    for (final row in rows ?? []) ChatContact.fromList(row),
  ];
}

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

final _chatFixtures = FutureProvider<Json>(
  (ref) async =>
      jsonDecode(
            await rootBundle.loadString('assets/fixtures/workspace_chats.json'),
          )
          as Json,
);
final chatDirectoryProvider = FutureProvider<ChatDirectory>((ref) async {
  final directory = ref.watch(localWorkspacesProvider.future);
  final fixtures = await ref.watch(_chatFixtures.future);
  final workspace = (await directory).active;
  final kind = workspace?.kind ?? WorkspaceKind.business;
  final id = workspace?.id ?? kind.name;
  return ChatDirectory(id, kind, id == kind.name ? fixtures[kind.name] : null);
});
