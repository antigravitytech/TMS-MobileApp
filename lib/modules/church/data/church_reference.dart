import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_entry.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Prefix for the prototype's Church records, so they can be refreshed.
const churchRefPrefix = 'church-ref-';

/// The prototype church's name.
const churchReferenceName = 'Victory Chapel — Ikeja';

/// Victory Chapel's services, giving, units, prayer requests, first-timers
/// and notices, dated around [today].
List<WorkspaceRecord> churchReference(DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  DateTime at(int offset, [int hour = 9, int minute = 0]) =>
      DateTime(day.year, day.month, day.day + offset, hour, minute);
  var n = 0;
  WorkspaceRecord r(
    WorkspaceSection section,
    String title, {
    String person = '',
    String group = '',
    String notes = '',
    DateTime? date,
    int amount = 0,
    int paid = 0,
    WorkspaceStatus status = WorkspaceStatus.todo,
    Map<String, String> fields = const {},
    List<WorkspaceEntry> entries = const [],
  }) => WorkspaceRecord(
    id: '$churchRefPrefix${n++}',
    section: section,
    title: title,
    person: person,
    group: group,
    notes: notes,
    date: date,
    amount: amount,
    paid: paid,
    status: status,
    points: 0,
    fields: fields,
    entries: entries,
  );
  WorkspaceEntry gift(String who, String how, int naira, int daysAgo) =>
      WorkspaceEntry(
        kind: EntryKind.payment,
        date: at(-daysAgo, 10),
        name: who,
        method: how,
        amount: naira * 100,
      );
  return [
    r(WorkspaceSection.congregation, 'Congregation', fields: {'size': '260'}),
    // Past services carry their attendance for the trend chart.
    for (final (offset, title, total) in [
      (-11, 'Sunday worship service', 519),
      (-8, 'Midweek Bible study', 139),
      (-4, 'Sunday worship service', 549),
    ])
      r(
        WorkspaceSection.services,
        title,
        date: at(offset, title.startsWith('Sunday') ? 8 : 18),
        status: WorkspaceStatus.done,
        fields: {
          'attendance': '$total',
          if (title.startsWith('Sunday')) 'sunday': 'true',
        },
      ),
    r(
      WorkspaceSection.services,
      'Midweek Bible study',
      person: 'Deacon Emeka',
      group: 'Hall B',
      date: at(0, 18),
      notes: '“The book of James” · James 3',
      fields: {
        'serve':
            'Ibrahim|Opening prayer\nDayo|Worship\nChinwe|Reading\n'
            'Ade|Notices\nGrace|Ushers\nEmeka|Teaching',
        'men': '38',
        'women': '70',
        'children': '0',
        'online': '31',
      },
    ),
    r(
      WorkspaceSection.services,
      'Sunday worship service',
      date: at(3, 8),
      notes: 'Grace for the race',
    ),
    r(
      WorkspaceSection.services,
      'Night of praise',
      date: at(8, 21),
      notes: 'overnight worship',
    ),
    r(
      WorkspaceSection.services,
      'Harvest thanksgiving',
      date: at(19, 9),
      notes: 'Bringing in the sheaves',
      fields: {'highlight': 'true'},
    ),
    r(
      WorkspaceSection.giving,
      'Tithes',
      paid: 34700000,
      fields: {'kind': 'tithes'},
      entries: [
        gift('Dayo Coker', 'transfer', 40000, 2),
        gift('Ibrahim Musa', 'transfer', 85000, 1),
      ],
    ),
    r(
      WorkspaceSection.giving,
      'Offerings',
      paid: 110000000,
      fields: {'kind': 'offerings'},
      entries: [gift('', 'cash', 312500, 1)],
    ),
    r(
      WorkspaceSection.giving,
      'Building fund',
      notes: 'The new 1,000-seat auditorium.',
      amount: 2500000000,
      paid: 75000000,
      entries: [gift('Chinwe Eke', 'transfer', 250000, 3)],
    ),
    r(
      WorkspaceSection.giving,
      'Welfare',
      notes: 'Food, rent and hospital bills for members in need.',
      amount: 150000000,
      paid: 4500000,
    ),
    r(
      WorkspaceSection.giving,
      'Missions',
      notes: 'Support for our missionaries in Kebbi.',
      amount: 300000000,
      paid: 12000000,
    ),
    r(
      WorkspaceSection.giving,
      'Burial support — Okafor family',
      notes: 'Let us stand with Deacon Okafor’s family. By 5 Dec.',
      amount: 80000000,
      paid: 21000000,
    ),
    for (final (name, schedule, me, what, urgent, members, next) in [
      (
        'Ushering',
        'Sundays · 7:15 am',
        'serve',
        'Welcomes people, seats them and takes the offering.',
        'All ushers at 7:15 am sharp on Sunday for harvest preparations.',
        'Chinwe\nAde\nEmeka',
        'Sun · Main door · Chinwe',
      ),
      (
        'Children’s church',
        'Saturdays · 4 pm',
        'lead',
        'Sunday school and care for under-12s.',
        '',
        'Ade\nIbrahim',
        'Sun · Teach ages 6–9 · Ade',
      ),
      (
        'Choir',
        'Thursdays · 6 pm',
        '',
        'Leads worship on Sundays and special services.',
        'Rehearsal moved to Friday 6 pm this week. Wear white on Sunday.',
        'Dayo\nChinwe\nGrace',
        'Sun · Lead the opening hymn · Dayo',
      ),
      (
        'Media',
        'Sundays · 7 am',
        '',
        'Sound, projection, livestream and photos.',
        '',
        'Grace\nEmeka',
        'Sun · Livestream · Grace',
      ),
      (
        'Welfare',
        'First Saturday · 10 am',
        '',
        'Visits the sick, supports families in need.',
        '',
        'Emeka\nDayo',
        'Sat · Hospital visit, Mama Ibe · Emeka',
      ),
      (
        'Evangelism',
        'Saturdays · 9 am',
        '',
        'Outreach and follow-up of new converts.',
        '',
        'Ibrahim\nChinwe',
        '',
      ),
    ])
      r(
        WorkspaceSection.units,
        name,
        notes: what,
        fields: {
          'when': schedule,
          'me': me,
          'urgent': urgent,
          'members': members,
          'next': next,
        },
      ),
    for (final (who, offset, text, praying, private) in [
      (
        'Emeka',
        -1,
        'Healing for my mother, Mama Ibe, who is in hospital.',
        3,
        false,
      ),
      ('Chinwe', 0, 'Job interview on Monday. I need favour.', 2, false),
      (
        'Ade',
        0,
        'Journey mercies. Travelling to Abuja for the weekend.',
        1,
        false,
      ),
      ('Grace', -4, 'Please pray for my marriage.', 1, true),
      ('', -6, 'Admission into university for my son.', 2, false),
    ])
      r(
        WorkspaceSection.prayers,
        text,
        person: who,
        date: at(offset, 8),
        fields: {
          'praying': '$praying',
          'private': '$private',
          'anonymous': '${who.isEmpty}',
        },
      ),
    for (final (name, offset, who, stage) in [
      ('Daniel Musa', 0, '', 0),
      ('Chiamaka Obi', 0, 'Dayo', 1),
      ('Tunde Afolabi', -8, 'Chinwe', 2),
      ('Esther Nwankwo', -8, 'Emeka', 3),
      ('Samuel Ojo', -15, 'Chinwe', 4),
      ('Blessing Uche', -22, 'Dayo', 1),
    ])
      r(
        WorkspaceSection.firstTimers,
        name,
        date: at(offset),
        status: stage == 4 ? WorkspaceStatus.done : WorkspaceStatus.pending,
        fields: {'stage': '$stage', 'followsUp': who},
      ),
    r(
      WorkspaceSection.notices,
      'Harvest thanksgiving is on the 15th. Units, submit your lists by '
      'Friday.',
      date: at(-1, 17),
      fields: {'read': '140'},
    ),
  ];
}
