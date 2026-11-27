import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Prefix for the prototype's Committee records, so they can be refreshed.
const committeeRefPrefix = 'committee-ref-';

/// The prototype committee's name.
const committeeReferenceName = 'Harvest Planning Committee';

/// The committee's term, meetings, action items, minutes and a decision,
/// dated around [today].
List<WorkspaceRecord> committeeReference(DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  DateTime at(int offset, [int hour = 9]) =>
      DateTime(day.year, day.month, day.day + offset, hour);
  var n = 0;
  WorkspaceRecord r(
    WorkspaceSection section,
    String title, {
    String person = '',
    String group = '',
    String notes = '',
    DateTime? date,
    WorkspaceStatus status = WorkspaceStatus.todo,
    Map<String, String> fields = const {},
    List<String> options = const [],
    int? vote,
  }) => WorkspaceRecord(
    id: '$committeeRefPrefix${n++}',
    section: section,
    title: title,
    person: person,
    group: group,
    notes: notes,
    date: date,
    status: status,
    points: 0,
    fields: fields,
    options: options,
    vote: vote,
  );
  return [
    // The term itself: when it ends and how many members.
    r(
      WorkspaceSection.meetings,
      'Term ends',
      date: at(59, 12),
      fields: {'meta': 'true', 'size': '12'},
    ),
    r(
      WorkspaceSection.meetings,
      'Monthly meeting',
      person: 'Chair',
      group: 'Board room',
      date: at(3, 17),
      fields: {'tags': 'Agenda: budget\nVenue'},
    ),
    r(
      WorkspaceSection.meetings,
      'Sub-committee: finance',
      person: 'Treasurer',
      group: 'Online',
      date: at(8, 12),
      fields: {'tags': 'Agenda: dues\nAccount'},
    ),
    for (final (title, notes, stage) in [
      (
        'Get three venue quotes',
        'Owner: Chinwe · from last meeting · due in 2 days',
        1,
      ),
      ('Draft the budget', 'Owner: Dayo · due in 4 days', 0),
      ('Send minutes to members', 'Owner: Chinwe · due yesterday', 2),
      ('Book speaker', 'No owner yet · due in a week', 0),
    ])
      r(
        WorkspaceSection.actions,
        title,
        notes: notes,
        status: stage == 2 ? WorkspaceStatus.done : WorkspaceStatus.todo,
        fields: {'stage': '$stage'},
      ),
    r(
      WorkspaceSection.minutes,
      'Monthly meeting',
      person: 'Chinwe',
      date: at(-11, 17),
      notes:
          'Budget approved in principle.\n'
          'Venue shortlist cut to three: Eko Hall, Civic Centre, Church hall.\n'
          'Chinwe to get quotes by Saturday.\n'
          'Next meeting in 4 days.',
      fields: {'read': '9'},
    ),
    r(
      WorkspaceSection.decisions,
      'Which venue should we book?',
      person: 'Ibrahim',
      options: const ['Eko Hall', 'Civic Centre', 'Church hall'],
      vote: 1,
      fields: {'votes': '3,0,1'},
    ),
  ];
}
