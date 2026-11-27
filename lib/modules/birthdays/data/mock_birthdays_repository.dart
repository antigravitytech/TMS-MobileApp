part of 'birthdays_repository.dart';

/// The prototype's birthdays, dated from today. Cards and "wished" marks are
/// kept in the shared preview state so other screens see them.
class MockBirthdaysRepository implements BirthdaysRepository {
  const MockBirthdaysRepository(this._preview);

  final WorkspacePreview _preview;

  static const _members = [
    ('tb', 'Tunde Bakare', 'Tech Team · colleague', 0),
    ('ae', 'Amaka Eze', 'Colleague', 3),
    ('dm', 'David Mensah', 'Colleague', 9),
    ('na', 'Ngozi Adeyemi', 'Colleague', 21),
    ('sj', 'Sarah Johnson', 'Design · colleague', 38),
    ('fa', 'Folake Adebayo', 'Finance · colleague', 45),
    ('im', 'Ibrahim Musa', 'Operations · colleague', 66),
    ('ko', 'Kemi Ola', 'Sales · colleague', 80),
    ('so', 'Sola Obi', 'Tech Team · colleague', 140),
    ('ub', 'Uche Bello', 'Support · colleague', 200),
  ];

  static const _entries = [
    ('mb', 'Mama Bisi', 'family', 0, 64, 'Loves ofada rice'),
    ('co', 'Chidi Okeke', 'friend', 3, 36, ''),
    ('ga', 'Grandpa Ade', 'family', 52, 80, ''),
    ('tk', 'Tolu Kalu', 'client', 95, null, ''),
    ('pa', 'Pastor Ade', 'church', 160, null, ''),
  ];

  static String _day(int daysAway) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day + daysAway);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.month)}-${two(date.day)}';
  }

  @override
  Future<BirthdayCalendar> load(String workspaceId) async => BirthdayCalendar(
    members: [
      for (final (id, name, title, away) in _members)
        BirthdayPerson(
          id: 'mock-$id',
          name: name,
          jobTitle: title,
          day: _day(away),
          daysAway: away,
          iWished: _preview.birthdayCards.contains(name),
        ),
    ],
    entries: [
      for (final (id, name, relation, away, turning, note) in _entries)
        BirthdayEntry(
          id: 'mock-$id',
          name: name,
          day: _day(away),
          relation: relation,
          daysAway: away,
          turning: turning,
          note: note,
          celebrated: _preview.birthdayCards.contains(name),
        ),
    ],
    mineIsToday: true,
    wishesReceived: 3,
  );

  @override
  Future<void> sendWish(
    BirthdayPerson person, {
    required String message,
    required String theme,
    required String sticker,
  }) async => _preview.sendCard(person.name);

  @override
  Future<BirthdayEntry> celebrate(BirthdayEntry entry) async {
    _preview.sendCard(entry.name);
    return BirthdayEntry(
      id: entry.id,
      name: entry.name,
      day: entry.day,
      relation: entry.relation,
      daysAway: entry.daysAway,
      note: entry.note,
      turning: entry.turning,
      celebrated: true,
    );
  }
}
