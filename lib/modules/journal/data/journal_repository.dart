import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../domain/note.dart';

part 'live_journal_repository.dart';
part 'mock_journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) return MockJournalRepository();
  return LiveJournalRepository(
    ref.watch(networkCallsRepositoryProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
  );
});

abstract class JournalRepository {
  /// My active notes, pinned first then most recently changed.
  Future<List<JournalNote>> notes();
  Future<JournalNote> create(NoteDraft draft);
  Future<JournalNote> pin(JournalNote note, bool pinned);
}
