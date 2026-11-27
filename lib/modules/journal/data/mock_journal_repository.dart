part of 'journal_repository.dart';

/// The prototype's notes. New notes and pins last for the session.
class MockJournalRepository implements JournalRepository {
  var _next = 0;

  late final List<JournalNote> _notes = () {
    final now = DateTime.now();
    JournalNote note(
      String id,
      String title,
      String body,
      String color, {
      bool pinned = false,
      DateTime? remindAt,
    }) => JournalNote(
      id: id,
      title: title,
      body: body,
      color: color,
      pinned: pinned,
      remindAt: remindAt,
      updatedAt: now,
    );
    return [
      note(
        'mock-1',
        'Hiring plan',
        'Check in with Ibrahim about the backend shortlist.',
        'violet',
        pinned: true,
      ),
      note(
        'mock-2',
        'Portal review',
        'Bring the severity ranking and clips to standup.',
        'lime',
      ),
      note(
        'mock-3',
        'Tunde’s birthday',
        'Cake at lunch. Bring the card.',
        'rose',
        remindAt: DateTime(now.year, now.month, now.day + 1, 9),
      ),
      note(
        'mock-4',
        'Sprint 14 retro',
        'Ask for feedback on the review queue.',
        'sky',
      ),
    ];
  }();

  @override
  Future<List<JournalNote>> notes() async => List.of(_notes);

  @override
  Future<JournalNote> create(NoteDraft draft) async {
    final note = JournalNote(
      id: 'mock-new-${_next++}',
      title: draft.title,
      body: draft.body,
      color: draft.color,
      remindAt: draft.remindAt,
      updatedAt: DateTime.now(),
    );
    _notes.insert(0, note);
    return note;
  }

  @override
  Future<JournalNote> pin(JournalNote note, bool pinned) async {
    final updated = note.pin(pinned);
    final i = _notes.indexWhere((n) => n.id == note.id);
    if (i >= 0) _notes[i] = updated;
    return updated;
  }
}
