import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../data/journal_repository.dart';
import '../domain/note.dart';

/// My notes. Writing and pinning update the list without reloading it.
final journalProvider =
    AsyncNotifierProvider.autoDispose<JournalController, List<JournalNote>>(
      JournalController.new,
      retry: (_, _) => null,
    );

class JournalController extends AsyncNotifier<List<JournalNote>> {
  JournalRepository get _repository => ref.read(journalRepositoryProvider);

  @override
  Future<List<JournalNote>> build() =>
      guardSession(ref, () => ref.watch(journalRepositoryProvider).notes());

  Future<void> create(NoteDraft draft) async {
    final note = await guardSession(ref, () => _repository.create(draft));
    if (ref.mounted) _set([note, ...?state.value]);
  }

  Future<void> togglePin(JournalNote note) async {
    final updated = await guardSession(
      ref,
      () => _repository.pin(note, !note.pinned),
    );
    if (!ref.mounted) return;
    _set([
      for (final n in state.value ?? const <JournalNote>[])
        n.id == updated.id ? updated : n,
    ]);
  }

  /// Pinned first, then most recently changed, as the server orders them.
  void _set(List<JournalNote> notes) => state = AsyncData(
    notes..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    }),
  );
}
