import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../data/chat_directory.dart';
import '../data/chat_repository.dart';

/// A server conversation's messages, oldest first. It marks the newest
/// message read and polls for new ones while open.
final chatThreadProvider = AsyncNotifierProvider.autoDispose
    .family<ChatThread, List<ChatMessage>, String>(
      ChatThread.new,
      retry: (_, _) => null,
    );

class ChatThread extends AsyncNotifier<List<ChatMessage>> {
  ChatThread(this.conversationId);
  final String conversationId;
  String? _readUpTo;

  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  @override
  Future<List<ChatMessage>> build() async {
    final repository = ref.watch(chatRepositoryProvider);
    if (repository.threadPolling case final every?) {
      final timer = Timer.periodic(every, (_) => _poll());
      ref.onDispose(timer.cancel);
    }
    final messages = await _session(() => repository.messages(conversationId));
    unawaited(_markRead(messages));
    return messages;
  }

  Future<void> _poll() async {
    final current = state.value;
    if (current == null || state.isLoading) return;
    try {
      final latest = await _repository.messages(conversationId);
      if (!ref.mounted) return;
      state = AsyncData(_merge(current, latest));
      unawaited(_markRead(latest));
    } catch (_) {
      // The next poll tries again; a lasting failure shows on reopen.
    }
  }

  /// Keeps older loaded messages and takes the server's copy of the rest.
  static List<ChatMessage> _merge(
    List<ChatMessage> current,
    List<ChatMessage> latest,
  ) {
    final ids = {for (final m in latest) m.id};
    return [...current.where((m) => !ids.contains(m.id)), ...latest]
      ..sort((a, b) => a.at.compareTo(b.at));
  }

  Future<void> _markRead(List<ChatMessage> messages) async {
    final newest = messages.lastOrNull?.id;
    if (newest == null || newest == _readUpTo) return;
    _readUpTo = newest;
    try {
      await _repository.markRead(conversationId, newest);
      if (ref.mounted) ref.invalidate(chatDirectoryProvider);
    } catch (_) {
      _readUpTo = null;
    }
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    final sent = await _session(() => _repository.send(conversationId, text));
    final current = state.value ?? const [];
    if (!ref.mounted) return;
    state = AsyncData(_merge(current, [sent]));
    _readUpTo = sent.id;
    ref.invalidate(chatDirectoryProvider);
  }

  Future<void> toggleHeart(ChatMessage message) async {
    final updated = await _session(() => _repository.toggleHeart(message));
    final current = state.value;
    if (!ref.mounted || current == null) return;
    state = AsyncData([
      for (final m in current) m.id == updated.id ? updated : m,
    ]);
  }

  Future<T> _session<T>(Future<T> Function() operation) async {
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
