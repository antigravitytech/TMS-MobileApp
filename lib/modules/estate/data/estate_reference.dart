import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Prefix for the prototype's Estate records, so they can be refreshed.
const estateRefPrefix = 'estate-ref-';

/// The prototype estate's name.
const estateReferenceName = 'Palm Grove Estate';

/// Palm Grove Estate: levies, gate passes, facility issues, notices and a
/// poll, dated around [today].
List<WorkspaceRecord> estateReference(DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  DateTime at(int offset, [int hour = 9, int minute = 0]) =>
      DateTime(day.year, day.month, day.day + offset, hour, minute);
  var n = 0;
  WorkspaceRecord r(
    WorkspaceSection section,
    String title, {
    String person = '',
    String notes = '',
    DateTime? date,
    int amount = 0,
    int paid = 0,
    WorkspaceStatus status = WorkspaceStatus.todo,
    Map<String, String> fields = const {},
    List<String> options = const [],
    int? vote,
  }) => WorkspaceRecord(
    id: '$estateRefPrefix${n++}',
    section: section,
    title: title,
    person: person,
    notes: notes,
    date: date,
    amount: amount,
    paid: paid,
    status: status,
    points: 0,
    fields: fields,
    options: options,
    vote: vote,
  );
  return [
    // The estate itself: houses, the AGM and the levy target.
    r(
      WorkspaceSection.notices,
      'Palm Grove Estate',
      date: at(11, 10),
      amount: 360000000,
      fields: {
        'meta': 'true',
        'size': '64',
        'event': 'Residents’ AGM',
        'venue': 'clubhouse',
      },
    ),
    for (final (name, short, paid, levy) in [
      ('House 1 · Okafor', 'H1', 120000, 120000),
      ('House 2 · Bello', 'H2', 60000, 120000),
      ('House 3 · Adeyemi', 'H3', 0, 120000),
      ('House 4 · Eze', 'H4', 120000, 120000),
      ('House 5 · Musa', 'H5', 0, 120000),
      ('Block B · Flat 3', 'B3', 80000, 80000),
    ])
      r(
        WorkspaceSection.levies,
        name,
        amount: levy * 100,
        paid: paid * 100,
        fields: {'short': short},
      ),
    for (final (who, offset, hour, minute, code) in [
      ('Mr Okon (plumber) → House 3', 0, 14, 0, '4821'),
      ('DHL delivery → House 1', 0, 11, 30, '1937'),
      ('Party guests (12) → House 5', 1, 16, 0, '7710'),
    ])
      r(
        WorkspaceSection.passes,
        who,
        date: at(offset, hour, minute),
        fields: {'accessCode': code},
      ),
    for (final (title, notes, stage) in [
      (
        'Street light out — Close 2',
        'Electrician · reported by House 4 · due in 1 day',
        1,
      ),
      ('Gate motor making noise', 'Facility manager · due in 4 days', 0),
      (
        'Drainage blocked near House 5',
        'Facility manager · cleared yesterday',
        2,
      ),
    ])
      r(
        WorkspaceSection.issues,
        title,
        notes: notes,
        status: stage == 2 ? WorkspaceStatus.done : WorkspaceStatus.todo,
        fields: {'stage': '$stage'},
      ),
    r(
      WorkspaceSection.notices,
      'Water will be off on Thursday, 9am–1pm, for tank cleaning.',
      date: at(0, 8),
      fields: {'read': '41'},
    ),
    r(
      WorkspaceSection.notices,
      'AGM at the clubhouse. Bring your levy receipt.',
      date: at(-4, 18),
      fields: {'read': '52'},
    ),
    r(
      WorkspaceSection.poll,
      'Upgrade the gate to card access?',
      person: 'Ibrahim',
      options: const ['Yes', 'No', 'Not now'],
      vote: 1,
      fields: {'votes': '3,0,1'},
    ),
  ];
}
