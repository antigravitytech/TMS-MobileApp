/// A workspace member with a shared birthday (`BirthdayPerson` in the API).
/// Only the month and day are ever known for other people.
class BirthdayPerson {
  const BirthdayPerson({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.day,
    required this.daysAway,
    this.iWished = false,
    this.wishCount = 0,
  });

  factory BirthdayPerson.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return BirthdayPerson(
      id: user['id'] as String,
      name: [
        user['first_name'],
        user['last_name'],
      ].whereType<String>().join(' ').trim(),
      jobTitle: json['job_title'] as String? ?? '',
      day: json['day'] as String,
      daysAway: json['days_away'] as int,
      iWished: json['i_wished'] as bool? ?? false,
      wishCount: json['wish_count'] as int? ?? 0,
    );
  }

  final String id, name, jobTitle;

  /// `MM-DD`.
  final String day;
  final int daysAway, wishCount;

  /// Whether I've sent them a card today.
  final bool iWished;

  bool get isToday => daysAway == 0;

  BirthdayPerson wished() => BirthdayPerson(
    id: id,
    name: name,
    jobTitle: jobTitle,
    day: day,
    daysAway: daysAway,
    iWished: true,
    wishCount: iWished ? wishCount : wishCount + 1,
  );
}

/// A birthday added by hand for someone without an account (calendar entry).
class BirthdayEntry {
  const BirthdayEntry({
    required this.id,
    required this.name,
    required this.day,
    required this.relation,
    required this.daysAway,
    this.note = '',
    this.turning,
    this.celebrated = false,
  });

  factory BirthdayEntry.fromJson(Map<String, dynamic> json) => BirthdayEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    day: json['day'] as String,
    relation: json['relation'] as String? ?? 'other',
    daysAway: json['days_away'] as int,
    note: json['note'] as String? ?? '',
    turning: json['turning'] as int?,
    celebrated: json['celebrated'] as bool? ?? false,
  );

  final String id, name, day, note;

  /// `family`, `friend`, `colleague`, `client`, `church` or `other`.
  final String relation;
  final int daysAway;
  final int? turning;

  /// Marked as wished this year.
  final bool celebrated;

  bool get isToday => daysAway == 0;
}

/// Everything the Birthdays screen shows.
class BirthdayCalendar {
  const BirthdayCalendar({
    required this.members,
    required this.entries,
    required this.mineIsToday,
    required this.wishesReceived,
  });

  final List<BirthdayPerson> members;
  final List<BirthdayEntry> entries;

  /// My own birthday is today, and how many people sent me a card.
  final bool mineIsToday;
  final int wishesReceived;

  BirthdayCalendar copyWith({
    List<BirthdayPerson>? members,
    List<BirthdayEntry>? entries,
  }) => BirthdayCalendar(
    members: members ?? this.members,
    entries: entries ?? this.entries,
    mineIsToday: mineIsToday,
    wishesReceived: wishesReceived,
  );
}

/// The card styles the sheet offers, as API `theme` and `sticker` values.
const birthdayCardStyles = [
  (theme: 'confetti', sticker: 'party'),
  (theme: 'cake', sticker: 'cake'),
  (theme: 'bloom', sticker: 'heart'),
  (theme: 'fireworks', sticker: 'sparkles'),
  (theme: 'sparkle', sticker: 'bouquet'),
];
