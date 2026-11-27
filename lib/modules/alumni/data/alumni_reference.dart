import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Prefix for the prototype's Alumni records, so they can be refreshed.
const alumniRefPrefix = 'alumni-ref-';

/// The prototype association's name.
const alumniReferenceName = 'Class of 2006 Reunion';

/// The Class of 2006: dues, committees, a poll, a notice and classmates,
/// dated around [today].
List<WorkspaceRecord> alumniReference(DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  DateTime at(int offset, [int hour = 9]) =>
      DateTime(day.year, day.month, day.day + offset, hour);
  var n = 0;
  WorkspaceRecord r(
    WorkspaceSection section,
    String title, {
    String person = '',
    String notes = '',
    DateTime? date,
    int amount = 0,
    int paid = 0,
    Map<String, String> fields = const {},
    Map<String, bool> todos = const {},
    List<String> options = const [],
  }) => WorkspaceRecord(
    id: '$alumniRefPrefix${n++}',
    section: section,
    title: title,
    person: person,
    notes: notes,
    date: date,
    amount: amount,
    paid: paid,
    points: 0,
    fields: fields,
    todos: todos,
    options: options,
  );
  return [
    // The class itself: size, reunion and the dues target.
    r(
      WorkspaceSection.directory,
      'Class of 2006',
      date: at(37, 12),
      amount: 600000000,
      fields: {'meta': 'true', 'size': '112', 'event': '20th Anniversary'},
    ),
    for (final (name, paid, pledge) in [
      ('Dayo Coker', 100000, 100000),
      ('Chinwe Eke', 50000, 100000),
      ('Ibrahim Musa', 250000, 250000),
      ('Bola A.', 0, 100000),
      ('Kemi O.', 150000, 150000),
      ('Uche N.', 100000, 100000),
      ('Segun T.', 0, 50000),
    ])
      r(
        WorkspaceSection.dues,
        name,
        person: name,
        amount: pledge * 100,
        paid: paid * 100,
      ),
    for (final (name, lead, members, todos) in [
      (
        'Venue',
        'Dayo Coker',
        'Dayo Coker',
        ['Book reunion venue', 'Confirm caterer'],
      ),
      (
        'Programme',
        'Chinwe Eke',
        'Chinwe Eke\nDayo Coker',
        ['Draft run-of-show', 'Invite guest speaker'],
      ),
      ('Media', '', 'Chinwe Eke\nTolu A.', ['Photographer shortlist']),
      ('Welfare', '', 'Tolu A.', <String>[]),
      (
        'Finance',
        'Dayo Coker',
        'Dayo Coker\nNkem U.',
        ['Collect dues', 'Open event account'],
      ),
      (
        'Souvenirs',
        '',
        'Ibrahim Musa\nDayo Coker',
        ['Souvenir T-shirts', 'Aso-ebi orders'],
      ),
    ])
      r(
        WorkspaceSection.committees,
        name,
        person: lead,
        fields: {'members': members},
        todos: {for (final t in todos) t: false},
      ),
    r(
      WorkspaceSection.poll,
      'Aso-ebi colour',
      options: const ['Emerald green', 'Wine', 'Gold'],
      fields: {'votes': '3,1,0', 'byMe': 'true'},
    ),
    r(
      WorkspaceSection.notices,
      'Venue shortlist is out. Vote by Friday!',
      date: at(-1, 17),
      fields: {'read': '58'},
    ),
    for (final (name, about, activity) in [
      ('Dayo Coker', 'Treasurer · Lagos · Exco', 0),
      ('Chinwe Eke', 'Secretary · Abuja · Exco', 0),
      ('Bola A.', 'Doctor · London', 1),
      ('Uche N.', 'Engineer · Port Harcourt', 0),
    ])
      r(
        WorkspaceSection.directory,
        name,
        notes: about,
        fields: {'activity': '$activity'},
      ),
  ];
}
