import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

LocalWorkspace familyReference() {
  WorkspaceRecord r(
    String id,
    WorkspaceSection section,
    String title, {
    String person = '',
    String notes = '',
    WorkspaceStatus status = WorkspaceStatus.todo,
    int amount = 0,
    int points = 0,
    int paid = 0,
    DateTime? date,
    Map<String, String> fields = const {},
  }) => WorkspaceRecord(
    id: 'family-ref-$id',
    section: section,
    title: title,
    person: person,
    notes: notes,
    status: status,
    amount: amount,
    paid: paid,
    points: points,
    date: date,
    fields: fields,
  );
  return LocalWorkspace(
    id: 'family',
    kind: WorkspaceKind.family,
    name: 'The Ibrahim Family',
    records: [
      for (final (id, name, role, points) in [
        ('im', 'Ibrahim Musa', 'head', 0),
        ('fi', 'Funmi Ibrahim', 'cohead', 0),
        ('ti', 'Tobi Ibrahim', 'child', 165),
        ('ai', 'Ada Ibrahim', 'child', 40),
        ('bo', 'Bisi Ola', 'cook', 25),
        ('km', 'Kwame Mensah', 'driver', 10),
        ('sg', 'Sule Garba', 'security', 0),
      ])
        r(
          'member-$id',
          WorkspaceSection.household,
          name,
          fields: {'householdRole': role, 'displayPoints': '$points'},
        ),

      r(
        'points',
        WorkspaceSection.chores,
        'Completed chores',
        person: 'Tobi',
        status: WorkspaceStatus.done,
        points: 140,
        fields: {'ledger': 'true'},
      ),
      for (final (person, points) in [('Ada', 30), ('Bisi', 25), ('Kwame', 10)])
        r(
          'points-${person.toLowerCase()}',
          WorkspaceSection.chores,
          'Completed chores',
          person: person,
          status: WorkspaceStatus.done,
          points: points,
          fields: {'ledger': 'true'},
        ),
      for (final (i, (name, person, points, due, status)) in [
        (
          'Wash the plates after dinner',
          'Tobi',
          10,
          'Today',
          WorkspaceStatus.todo,
        ),
        ('Water the garden', 'Tobi', 5, 'Today', WorkspaceStatus.todo),
        ('Iron school uniforms', 'Bisi', 0, 'Tomorrow', WorkspaceStatus.todo),
        ('Wash the car', 'Kwame', 0, 'Fri, 27 Nov', WorkspaceStatus.inProgress),
        ('Tidy your room', 'Ada', 10, 'Yesterday', WorkspaceStatus.done),
      ].indexed)
        r(
          'chore$i',
          WorkspaceSection.chores,
          name,
          person: person,
          points: points,
          status: status,
          fields: {'due': due},
        ),
      r(
        'fractions',
        WorkspaceSection.school,
        'Check Tobi’s Fractions worksheet, page 14',
        person: 'Tobi',
        notes: 'Tobi sent a photo',
        status: WorkspaceStatus.submitted,
      ),
      r(
        'bill',
        WorkspaceSection.bills,
        'Pay Estate service charge · ₦60,000',
        notes: 'due Mon, 30 Nov',
        amount: 6000000,
        fields: {
          'billName': 'Estate service charge',
          'billKind': 'home',
          'due': 'Due Mon, 30 Nov',
          'dueOn': '2026-11-30',
        },
      ),
      r(
        'bill-power',
        WorkspaceSection.bills,
        'Electricity (prepaid)',
        amount: 4500000,
        paid: 4500000,
        fields: {'billKind': 'power', 'due': 'Due Sun, 22 Nov'},
      ),
      r(
        'bill-tv',
        WorkspaceSection.bills,
        'DSTV',
        amount: 2400000,
        paid: 2400000,
        fields: {'billKind': 'tv', 'due': 'Due Sun, 15 Nov'},
      ),
      r(
        'redo',
        WorkspaceSection.school,
        'Ada is redoing “Spelling list — 20 words”',
        person: 'Ada',
        notes: '“Do the last five again, neatly.”',
        status: WorkspaceStatus.returned,
      ),
      for (final (id, name, notes, store, status) in [
        (
          'tomatoes',
          'Tomatoes',
          '1 basket · for Sunday stew',
          'Mile 12',
          WorkspaceStatus.todo,
        ),
        ('rice', 'Rice', '50kg bag', 'Mile 12', WorkspaceStatus.todo),
        (
          'detergent',
          'Detergent',
          'Big size',
          'Shoprite',
          WorkspaceStatus.todo,
        ),
        ('bread', 'Bread', '2 loaves', '', WorkspaceStatus.done),
      ])
        r(
          id,
          WorkspaceSection.shopping,
          name,
          notes: notes,
          status: status,
          fields: {'store': store},
        ),
      r(
        'reward1',
        WorkspaceSection.rewards,
        'Screen time · 1 hour',
        points: 50,
      ),
      r(
        'reward2',
        WorkspaceSection.rewards,
        'Ice cream outing',
        points: 120,
        fields: {'rewardKind': 'treat'},
      ),
      r(
        'reward4',
        WorkspaceSection.rewards,
        'Choose Saturday’s movie',
        points: 150,
        fields: {'rewardKind': 'movie'},
      ),
      r(
        'reward3',
        WorkspaceSection.rewards,
        'New football',
        points: 300,
        fields: {'rewardKind': 'sport'},
      ),
      r(
        'errand1',
        WorkspaceSection.errands,
        'Carry Madam to the market by 10 · tomatoes and rice',
        person: 'Kwame',
        fields: {
          'issued': '20000',
          'spent': '17500',
          'changeReceived': 'false',
        },
      ),
      r(
        'errand2',
        WorkspaceSection.errands,
        'Market run — Mile 12',
        person: 'Bisi',
        fields: {'issued': '85000'},
      ),
      r(
        'visitor1',
        WorkspaceSection.visitors,
        'Aunty Ngozi',
        notes: 'Staying for lunch',
        date: _today(16),
        status: WorkspaceStatus.pending,
      ),
      r(
        'visitor2',
        WorkspaceSection.visitors,
        'Gas delivery',
        notes: 'Two 12.5kg cylinders',
        date: _today(10),
        status: WorkspaceStatus.confirmed,
      ),
      r(
        'event1',
        WorkspaceSection.school,
        'Excursion consent form',
        person: 'Tobi',
        notes: 'form to sign',
        date: DateTime(2026, 11, 27),
      ),
      r(
        'event2',
        WorkspaceSection.plans,
        'PTA meeting',
        notes: '10:00 am',
        date: DateTime(2026, 11, 28),
      ),
      r(
        'event3',
        WorkspaceSection.school,
        'Maths test — chapters 4 and 5',
        person: 'Tobi',
        date: DateTime(2026, 11, 30),
      ),
      r(
        'event4',
        WorkspaceSection.school,
        'Inter-house sports',
        person: 'Ada',
        notes: 'wear house colour',
        date: DateTime(2026, 12, 4),
      ),
      r(
        'event5',
        WorkspaceSection.bills,
        'Second term fees',
        notes: '₦650,000',
        date: DateTime(2026, 12, 7),
        amount: 65000000,
        paid: 30000000,
        fields: {
          'billName': 'School fees — Tobi (2nd term)',
          'billKind': 'school',
          'due': 'Due Mon, 7 Dec · balance due',
        },
      ),
    ],
  );
}

/// Today at [hour], for visits expected later in the day.
DateTime _today(int hour) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour);
}
