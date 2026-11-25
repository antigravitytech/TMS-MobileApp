import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';

/// Example records for the sign-in screen's explicit demo entry points.
LocalWorkspace demoWorkspace(WorkspaceKind kind, DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  DateTime at(int offset, [int hour = 9]) =>
      DateTime(day.year, day.month, day.day + offset, hour);
  var index = 0;
  WorkspaceRecord item(
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
    int points = 1,
    bool review = false,
    bool flagged = false,
    Map<String, String> fields = const {},
    Map<String, bool> todos = const {},
    List<String> options = const [],
    List<InvoiceLine> lines = const [],
  }) => WorkspaceRecord(
    id: 'demo-${kind.name}-${index++}',
    section: section,
    title: title,
    person: person,
    group: group,
    notes: notes,
    date: date,
    amount: amount,
    paid: paid,
    status: status,
    points: points,
    requiresReview: review,
    duration: duration,
    flagged: flagged,
    fields: fields,
    todos: todos,
    options: options,
    invoiceLines: lines,
  );
  final records = switch (kind) {
    WorkspaceKind.individual => [
      item(
        WorkspaceSection.gigs,
        'Studio identity',
        person: 'Juniper Studio',
        date: at(3),
        status: WorkspaceStatus.inProgress,
      ),
      item(
        WorkspaceSection.clients,
        'Juniper Studio',
        group: 'Brand design',
        status: WorkspaceStatus.confirmed,
      ),
      for (final (number, client, amount, paid, offset) in [
        ('INV-204', 'Unique Engineering', 850000, 850000, -12),
        ('INV-205', 'Nexora Properties', 400000, 0, 3),
        ('INV-198', 'Mrs Ade', 120000, 60000, -5),
        ('INV-206', 'Unique Engineering', 650000, 0, 14),
      ])
        item(
          WorkspaceSection.invoices,
          number,
          person: client,
          amount: amount * 100,
          paid: paid * 100,
          date: at(offset),
          lines: [InvoiceLine(number, 1, amount * 100)],
        ),
      item(
        WorkspaceSection.time,
        'Creative direction',
        person: 'Juniper Studio',
        date: at(0),
        duration: 150,
        flagged: true,
      ),
      item(
        WorkspaceSection.proposals,
        'Launch campaign',
        person: 'Fieldwork Co.',
        date: at(2),
        amount: 25000000,
        status: WorkspaceStatus.inProgress,
        fields: {
          'documentBody':
              'Scope of work\nCampaign identity, launch artwork and handover.',
        },
      ),
    ],
    WorkspaceKind.family => [
      item(
        WorkspaceSection.household,
        'Tomi',
        fields: {'householdRole': 'child'},
      ),
      item(
        WorkspaceSection.household,
        'Sam',
        fields: {'householdRole': 'driver'},
      ),
      item(
        WorkspaceSection.chores,
        'Water the plants',
        person: 'Tomi',
        date: at(0),
        points: 5,
        status: WorkspaceStatus.done,
      ),
      item(
        WorkspaceSection.chores,
        'Set the table',
        person: 'Tomi',
        date: at(0),
        points: 5,
      ),
      item(
        WorkspaceSection.school,
        'Reading journal',
        person: 'Tomi',
        group: 'homework',
        date: at(0),
        review: true,
        points: 10,
        status: WorkspaceStatus.submitted,
      ),
      item(WorkspaceSection.shopping, 'Tomatoes and rice'),
      item(WorkspaceSection.bills, 'Electricity', amount: 2500000, date: at(2)),
      item(
        WorkspaceSection.errands,
        'Grocery run',
        person: 'Sam',
        fields: {'issued': '20000', 'spent': '16500'},
      ),
      item(
        WorkspaceSection.plans,
        'Sunday lunch',
        date: at(3, 13),
        group: 'At home',
      ),
      item(
        WorkspaceSection.visitors,
        'Garden delivery',
        date: at(0),
        status: WorkspaceStatus.pending,
      ),
      item(WorkspaceSection.rewards, 'Choose movie night', points: 10),
    ],
    WorkspaceKind.event => [
      item(
        WorkspaceSection.guests,
        'Ari & Jo',
        duration: 2,
        status: WorkspaceStatus.confirmed,
        group: 'Garden',
        fields: {'meal': 'Jollof rice'},
      ),
      item(
        WorkspaceSection.guests,
        'Taylor',
        duration: 1,
        status: WorkspaceStatus.pending,
      ),
      item(
        WorkspaceSection.vendors,
        'Garden Kitchen',
        amount: 45000000,
        paid: 15000000,
        date: at(8),
        fields: {'vendorCategory': 'Catering'},
      ),
      item(
        WorkspaceSection.programme,
        'Guest arrival',
        date: at(21, 14),
        duration: 30,
        person: 'Welcome team',
      ),
      item(
        WorkspaceSection.programme,
        'Ceremony',
        date: at(21, 15),
        duration: 60,
      ),
      item(WorkspaceSection.prep, 'Confirm final menu', date: at(9)),
      item(
        WorkspaceSection.notices,
        'Arrival and parking',
        notes: 'Please use the garden entrance.',
      ),
    ],
    WorkspaceKind.church => [
      item(
        WorkspaceSection.services,
        'Sunday worship',
        date: at(3, 9),
        group: 'Main hall',
        fields: {'theme': 'A thankful heart'},
      ),
      item(
        WorkspaceSection.giving,
        'Building fund',
        amount: 100000000,
        paid: 37500000,
      ),
      item(
        WorkspaceSection.units,
        'Welcome team',
        person: 'Rae',
        fields: {'members': 'Rae\nTobi'},
        todos: {'Prepare welcome packs': false},
      ),
      item(WorkspaceSection.prayers, 'Safe travels for the youth team'),
      item(
        WorkspaceSection.firstTimers,
        'Robin',
        status: WorkspaceStatus.pending,
        fields: {'followsUp': 'Rae'},
      ),
      item(
        WorkspaceSection.notices,
        'Choir rehearsal',
        notes: 'Saturday at 4 pm in the main hall.',
      ),
    ],
    WorkspaceKind.alumni => [
      item(
        WorkspaceSection.dues,
        'Reunion pledge · Morgan',
        amount: 4000000,
        paid: 2000000,
      ),
      item(
        WorkspaceSection.committees,
        'Reunion planning',
        person: 'Morgan',
        fields: {'members': 'Morgan\nLee'},
        todos: {'Confirm venue': false},
      ),
      item(
        WorkspaceSection.poll,
        'Which reunion day works?',
        options: ['Saturday', 'Sunday'],
      ),
      item(
        WorkspaceSection.directory,
        'Morgan',
        group: 'Class representative',
        status: WorkspaceStatus.confirmed,
      ),
      item(
        WorkspaceSection.notices,
        'Reunion planning is open',
        notes: 'Vote for the date that works for you.',
      ),
    ],
    WorkspaceKind.estate => [
      item(WorkspaceSection.levies, 'House 12', amount: 5000000, paid: 3500000),
      item(
        WorkspaceSection.passes,
        'Delivery to House 12',
        date: at(0, 15),
        group: 'North gate',
        fields: {'accessCode': 'DEMO-012'},
      ),
      item(
        WorkspaceSection.issues,
        'Streetlight near the gate',
        person: 'Maintenance',
      ),
      item(
        WorkspaceSection.notices,
        'Water tank cleaning',
        notes: 'The maintenance team will be on site on Saturday.',
      ),
      item(
        WorkspaceSection.poll,
        'Preferred meeting time',
        options: ['Morning', 'Evening'],
      ),
    ],
    WorkspaceKind.committee => [
      item(
        WorkspaceSection.meetings,
        'Planning meeting',
        date: at(2, 16),
        group: 'Meeting room',
      ),
      item(
        WorkspaceSection.actions,
        'Circulate draft budget',
        person: 'Alex',
        date: at(1),
      ),
      item(
        WorkspaceSection.minutes,
        'Planning minutes',
        notes: 'The team agreed to review the budget before the next meeting.',
      ),
      item(
        WorkspaceSection.decisions,
        'Approve the revised schedule?',
        options: ['Approve', 'Request changes'],
      ),
    ],
    WorkspaceKind.club => [
      item(
        WorkspaceSection.sessions,
        'Saturday training',
        date: at(2, 8),
        group: 'Sports ground',
      ),
      item(WorkspaceSection.fees, 'Taylor', amount: 1500000, paid: 1000000),
      item(
        WorkspaceSection.attendance,
        'Taylor',
        status: WorkspaceStatus.confirmed,
        fields: {'session': 'Saturday training'},
      ),
      item(
        WorkspaceSection.notices,
        'Training kit',
        notes: 'Bring water and your club shirt.',
      ),
    ],
    WorkspaceKind.business => <WorkspaceRecord>[],
  };
  return LocalWorkspace(
    id: kind.name,
    kind: kind,
    name: kind == WorkspaceKind.individual ? 'Studio Kemi' : '',
    records: records,
    eventDate: kind == WorkspaceKind.event ? at(21) : null,
    eventVenue: kind == WorkspaceKind.event ? 'Garden Hall' : '',
    eventCapacity: kind == WorkspaceKind.event ? 80 : 0,
    eventBudget: kind == WorkspaceKind.event ? 100000000 : 0,
  );
}
