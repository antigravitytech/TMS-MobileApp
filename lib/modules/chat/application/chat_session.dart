import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_directory.dart';

class ChatSession {
  const ChatSession({
    this.selected,
    this.contacts = const [],
    this.groups = const [],
    this.messages = const {},
    this.typing = const {},
    this.replied = const {},
    this.requestHandled = false,
  });
  final ChatRow? selected;
  final List<ChatRow> contacts, groups;
  final Map<String, List<String>> messages;
  final Set<String> typing, replied;
  final bool requestHandled;
  ChatSession copyWith({
    ChatRow? selected,
    bool clearSelection = false,
    List<ChatRow>? contacts,
    List<ChatRow>? groups,
    Map<String, List<String>>? messages,
    Set<String>? typing,
    Set<String>? replied,
    bool? requestHandled,
  }) => ChatSession(
    selected: clearSelection ? null : selected ?? this.selected,
    contacts: contacts ?? this.contacts,
    groups: groups ?? this.groups,
    messages: messages ?? this.messages,
    typing: typing ?? this.typing,
    replied: replied ?? this.replied,
    requestHandled: requestHandled ?? this.requestHandled,
  );
}

final chatSessionProvider =
    NotifierProvider.family<ChatSessionController, ChatSession, String>(
      ChatSessionController.new,
    );

class ChatSessionController extends Notifier<ChatSession> {
  ChatSessionController(this.workspace);
  final String workspace;
  final _timers = <String, Timer>{};
  @override
  ChatSession build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
    });
    return const ChatSession();
  }

  void openDefault() => state = state.copyWith(clearSelection: true);
  void open(ChatRow row) => state = state.copyWith(selected: row);
  void resolveRequest(ChatRow? accepted) => state = state.copyWith(
    requestHandled: true,
    contacts: [?accepted, ...state.contacts],
  );
  void create(ChatRow row, {required bool group}) {
    final rows = group ? state.groups : state.contacts;
    final next = [row, ...rows.where((r) => r.name != row.name)];
    state = state.copyWith(
      selected: row,
      groups: group ? next : null,
      contacts: group ? null : next,
    );
  }

  void send(String peer, String text, {required bool demoReply}) {
    if (text.trim().isEmpty) return;
    state = state.copyWith(
      messages: {
        ...state.messages,
        peer: [...?state.messages[peer], text.trim()],
      },
      typing: {...state.typing, if (demoReply) peer},
      replied: {...state.replied}..remove(peer),
    );
    if (!demoReply) return;
    _timers.remove(peer)?.cancel();
    _timers[peer] = Timer(const Duration(milliseconds: 1600), () {
      _timers.remove(peer);
      state = state.copyWith(
        typing: {...state.typing}..remove(peer),
        replied: {...state.replied, peer},
      );
    });
  }
}
