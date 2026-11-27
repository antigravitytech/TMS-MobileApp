import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import '../../individual/data/individual_reference.dart';
import '../../alumni/data/alumni_reference.dart';
import '../../church/data/church_reference.dart';
import '../../estate/data/estate_reference.dart';
import '../../club/data/club_reference.dart';
import '../../committee/data/committee_reference.dart';
import '../../event/data/event_reference.dart';

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
    WorkspaceKind.individual => individualReference(today),
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
    WorkspaceKind.event => eventReference(today),
    WorkspaceKind.church => churchReference(today),
    WorkspaceKind.alumni => alumniReference(today),
    WorkspaceKind.estate => estateReference(today),
    WorkspaceKind.committee => committeeReference(today),
    WorkspaceKind.club => clubReference(today),
    WorkspaceKind.business => <WorkspaceRecord>[],
  };
  return LocalWorkspace(
    id: kind.name,
    kind: kind,
    name: switch (kind) {
      WorkspaceKind.individual => 'Studio Kemi',
      WorkspaceKind.church => churchReferenceName,
      WorkspaceKind.alumni => alumniReferenceName,
      WorkspaceKind.estate => estateReferenceName,
      WorkspaceKind.event => eventReferenceName,
      WorkspaceKind.committee => committeeReferenceName,
      WorkspaceKind.club => clubReferenceName,
      _ => '',
    },
    records: records,
    eventDate: kind == WorkspaceKind.event ? at(eventReferenceDays, 14) : null,
    eventVenue: kind == WorkspaceKind.event ? eventReferenceVenue : '',
    eventCapacity: kind == WorkspaceKind.event ? eventReferenceCapacity : 0,
    eventBudget: kind == WorkspaceKind.event ? eventReferenceBudget : 0,
  );
}
