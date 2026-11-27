import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_models.dart';
import 'chat_repository.dart';

export '../domain/chat_models.dart';

/// The Chat inbox for the active workspace. Live inboxes refresh on the
/// repository's polling interval.
final chatDirectoryProvider = FutureProvider<ChatDirectory>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  if (repository.inboxPolling case final every?) {
    final timer = Timer(every, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return repository.inbox();
}, retry: (_, _) => null);
