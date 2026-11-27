import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Prefix for the prototype's Event records, so they can be refreshed.
const eventRefPrefix = 'event-ref-';

/// The prototype event and its venue, capacity and budget (kobo).
const eventReferenceName = 'Chinwe & Dayo’s Wedding';
const eventReferenceVenue = 'Eko Hall';
const eventReferenceCapacity = 300;
const eventReferenceBudget = 650000000;

/// Days from today to the wedding.
const eventReferenceDays = 29;

/// The wedding's guests, tables, vendors and run of show, dated around
/// [today].
List<WorkspaceRecord> eventReference(DateTime today) {
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
    int duration = 0,
    WorkspaceStatus status = WorkspaceStatus.todo,
    Map<String, String> fields = const {},
  }) => WorkspaceRecord(
    id: '$eventRefPrefix${n++}',
    section: section,
    title: title,
    person: person,
    group: group,
    notes: notes,
    date: date,
    amount: amount,
    paid: paid,
    duration: duration,
    status: status,
    points: 0,
    fields: fields,
  );
  return [
    // Who's hosting, what the day is and its style.
    r(
      WorkspaceSection.notices,
      'The wedding',
      fields: {
        'meta': 'true',
        'hosts': 'Chinwe & Dayo',
        'style': 'Traditional · aso-ebi colours: emerald and gold',
        'rsvpBy': at(13).toIso8601String(),
      },
    ),
    for (final (name, short, seats, shape, x, y) in [
      ('High table', 'HT', 10, 'long', 50, 22),
      ('Table 1', 'T1', 8, 'round', 20, 55),
      ('Table 2', 'T2', 8, 'round', 50, 58),
      ('Table 3', 'T3', 8, 'round', 80, 55),
      ('Family table', 'FT', 12, 'long', 50, 84),
    ])
      r(
        WorkspaceSection.seating,
        name,
        duration: seats,
        fields: {'shape': shape, 'px': '$x', 'py': '$y', 'short': short},
      ),
    for (final (name, side, party, status, meal, table) in [
      (
        'Mr & Mrs Eke',
        'Bride’s family',
        2,
        WorkspaceStatus.confirmed,
        'Jollof & chicken',
        'High table',
      ),
      (
        'Chinwe Eke',
        'Friends',
        1,
        WorkspaceStatus.confirmed,
        'Vegetarian fried rice',
        'Table 1',
      ),
      ('Dayo Coker', 'Groom’s family', 3, WorkspaceStatus.maybe, '', ''),
      (
        'Uncle Ben & family',
        'Bride’s family',
        4,
        WorkspaceStatus.pending,
        '',
        '',
      ),
      ('Kemi Ogun', 'Colleagues', 1, WorkspaceStatus.declined, '', ''),
      (
        'Pastor Femi Adebayo',
        'Church',
        2,
        WorkspaceStatus.confirmed,
        '',
        'High table',
      ),
      (
        'Ngozi & Tunde Bakare',
        'Friends',
        2,
        WorkspaceStatus.confirmed,
        'Pounded yam & egusi',
        'Table 1',
      ),
      ('Aunty Bisi', 'Groom’s family', 1, WorkspaceStatus.notInvited, '', ''),
      ('The Mensah family', 'Colleagues', 3, WorkspaceStatus.pending, '', ''),
      ('Ifeoma Nwosu', 'Church', 1, WorkspaceStatus.confirmed, '', 'Table 2'),
    ])
      r(
        WorkspaceSection.guests,
        name,
        group: table,
        duration: party,
        status: status,
        fields: {'side': side, 'meal': meal},
      ),
    for (final (name, kind, stage, cost, paid, offset, note) in [
      ('Cakes by Ada', 'Cake', 'enquiry', 0, 0, null, 'No quote yet'),
      (
        'DJ Spinall & MC Kunle',
        'DJ & music',
        'quoted',
        400000,
        0,
        null,
        'Arrives 12:30 pm',
      ),
      (
        'Mama Tolu’s Kitchen',
        'Catering · Mama Tolu',
        'booked',
        1800000,
        900000,
        4,
        '',
      ),
      ('Petals Decor', 'Decor', 'booked', 650000, 200000, 6, ''),
      ('Lens Studio', 'Photo & video', 'booked', 550000, 275000, 8, ''),
      (
        'Eko Hall',
        'Venue · Mrs Adeyemi',
        'booked',
        1500000,
        1500000,
        null,
        'Arrives 10:00 am',
      ),
    ])
      r(
        WorkspaceSection.vendors,
        name,
        amount: cost * 100,
        paid: paid * 100,
        date: offset == null ? null : at(offset),
        notes: note,
        fields: {'vendorCategory': kind, 'stage': stage},
      ),
    for (final (h, m, minutes, name, place, part) in [
      (8, 0, 240, 'Vendors set up', 'Eko Hall · Petals Decor', 'before'),
      (14, 0, 45, 'Guests arrive · small chops', 'Main hall · Ushers', ''),
      (14, 45, 15, 'Couple’s grand entrance', 'MC Kunle', 'reception'),
      (15, 0, 10, 'Opening prayer', 'Pastor Femi', ''),
      (15, 10, 50, 'Lunch is served', 'Mama Tolu’s Kitchen', ''),
      (16, 0, 30, 'Toasts & cutting the cake', 'MC Kunle', ''),
      (16, 30, 45, 'First dance & spraying', 'Dance floor · DJ Spinall', ''),
      (17, 15, 30, 'Group photos by family', 'Garden · Lens Studio', ''),
      (
        17,
        45,
        15,
        'Vote of thanks · couple departs',
        'Bride’s father',
        'after',
      ),
      (18, 0, 90, 'Pack down', 'Petals Decor', ''),
    ])
      r(
        WorkspaceSection.programme,
        name,
        notes: place,
        date: at(eventReferenceDays, h, m),
        duration: minutes,
        fields: {'part': part},
      ),
    for (final (title, who, due, done) in [
      ('Confirm final head count with caterer', 'Chinwe', 5, false),
      ('Collect aso-ebi from the tailor', 'Dayo', 3, true),
      ('Print programmes and place cards', 'Chinwe', 9, false),
      ('Book the photographer’s second shooter', 'Dayo', 7, false),
    ])
      r(
        WorkspaceSection.prep,
        title,
        person: who,
        date: at(due),
        status: done ? WorkspaceStatus.done : WorkspaceStatus.todo,
      ),
    for (final (text, ago, read) in [
      ('RSVPs close in 13 days. Chase anyone who hasn’t replied.', 1, 9),
      ('Aso-ebi pickup is this Saturday at the tailor’s shop.', 3, 14),
    ])
      r(
        WorkspaceSection.notices,
        text,
        date: at(-ago),
        fields: {'read': '$read'},
      ),
  ];
}
