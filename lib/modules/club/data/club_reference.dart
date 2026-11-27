import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Prefix for the prototype's Club records, so they can be refreshed.
const clubRefPrefix = 'club-ref-';

/// The prototype club's name.
const clubReferenceName = 'Ikoyi Sunday League FC';

/// The club's season, sessions, fees, attendance and a notice, dated around
/// [today].
List<WorkspaceRecord> clubReference(DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  DateTime at(int offset, [int hour = 9]) =>
      DateTime(day.year, day.month, day.day + offset, hour);
  var n = 0;
  WorkspaceRecord r(
    WorkspaceSection section,
    String title, {
    String person = '',
    String group = '',
    DateTime? date,
    int amount = 0,
    int paid = 0,
    Map<String, String> fields = const {},
  }) => WorkspaceRecord(
    id: '$clubRefPrefix${n++}',
    section: section,
    title: title,
    person: person,
    group: group,
    date: date,
    amount: amount,
    paid: paid,
    points: 0,
    fields: fields,
  );
  return [
    // The season: its opener, members and the fees target.
    r(
      WorkspaceSection.notices,
      'Season opener',
      date: at(10, 16),
      amount: 96000000,
      fields: {'meta': 'true', 'size': '32'},
    ),
    r(
      WorkspaceSection.sessions,
      'Saturday training',
      group: 'Oval pitch',
      person: 'Coach Femi',
      date: at(1, 7),
      fields: {'tags': 'Bring both kits'},
    ),
    r(
      WorkspaceSection.sessions,
      'Friendly vs Lekki FC',
      group: 'Away',
      date: at(10, 16),
      fields: {'tags': 'Bus leaves 2pm\nCaptain'},
    ),
    r(
      WorkspaceSection.sessions,
      'Monthly social',
      group: 'Clubhouse',
      date: at(17, 19),
      fields: {'tags': 'Families welcome'},
    ),
    for (final (name, short, paid) in [
      ('Tunde Bakare', 'TB', 60000),
      ('Chidi Okeke', 'CO', 30000),
      ('Musa Bello', 'MB', 0),
      ('Kenny Eze', 'KE', 60000),
    ])
      r(
        WorkspaceSection.fees,
        name,
        amount: 6000000,
        paid: paid * 100,
        fields: {'short': short},
      ),
    for (final (name, role, mark) in [
      ('Tunde Bakare', 'Striker', 0),
      ('Chidi Okeke', 'Midfield', 0),
      ('Musa Bello', 'Goalkeeper', 1),
      ('Kenny Eze', 'Defence', 2),
    ])
      r(
        WorkspaceSection.attendance,
        name,
        person: role,
        group: 'Saturday training',
        fields: {'mark': '$mark'},
      ),
    r(
      WorkspaceSection.notices,
      'New kits arrive next week. Pay the balance of your fees to collect.',
      date: at(-4),
      fields: {'read': '18'},
    ),
  ];
}
