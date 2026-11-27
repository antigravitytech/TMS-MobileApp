import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Prefix for the prototype's Individual records, so they can be refreshed.
const individualRefPrefix = 'ind-ref-';

/// The prototype's Individual workspace (Studio Kemi), dated around [today].
List<WorkspaceRecord> individualReference(DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  DateTime at(int offset, [int hour = 9]) =>
      DateTime(day.year, day.month, day.day + offset, hour);
  WorkspaceRecord r(
    String id,
    WorkspaceSection section,
    String title, {
    String person = '',
    String notes = '',
    DateTime? date,
    int amount = 0,
    int paid = 0,
    int duration = 0,
    bool flagged = false,
    WorkspaceStatus status = WorkspaceStatus.todo,
    Map<String, String> fields = const {},
    Map<String, bool> todos = const {},
    List<InvoiceLine> lines = const [],
  }) => WorkspaceRecord(
    id: '$individualRefPrefix$id',
    section: section,
    title: title,
    person: person,
    notes: notes,
    date: date,
    amount: amount,
    paid: paid,
    duration: duration,
    flagged: flagged,
    status: status,
    points: 0,
    fields: fields,
    todos: todos,
    invoiceLines: lines,
  );
  return [
    for (final (id, name, what, stage, avatar) in [
      ('ue', 'Unique Engineering', 'Website and brand refresh', 'active', '5'),
      ('np', 'Nexora Properties', 'Monthly content retainer', 'active', '2'),
      ('ks', 'KD Squares', 'Proposal sent', 'lead', '3'),
      ('ade', 'Mrs Ade', 'Interior mood board', 'past', '4'),
    ])
      r(
        'client-$id',
        WorkspaceSection.clients,
        name,
        notes: what,
        fields: {'stage': stage, 'avatar': avatar},
      ),
    for (final (id, name, client, meta, stage, amount) in [
      (
        'kd',
        'Brand guide for KD Squares',
        'KD Squares',
        '₦1.2m · 3 weeks',
        'sent',
        120000000,
      ),
      (
        'nexora',
        'Retainer renewal — Nexora',
        'Nexora Properties',
        '₦400k a month',
        'todo',
        40000000,
      ),
      ('ade', 'Logo pack — Mrs Ade', 'Mrs Ade', '', 'accepted', 0),
    ])
      r(
        'proposal-$id',
        WorkspaceSection.proposals,
        name,
        person: client,
        amount: amount,
        date: at(stage == 'accepted' ? -9 : (id == 'kd' ? 3 : 9)),
        status: stage == 'accepted'
            ? WorkspaceStatus.done
            : stage == 'sent'
            ? WorkspaceStatus.inProgress
            : WorkspaceStatus.todo,
        fields: {'stage': stage, 'meta': meta},
      ),
    for (final (number, client, amount, paid, offset) in [
      ('INV-204', 'Unique Engineering', 850000, 850000, -13),
      ('INV-205', 'Nexora Properties', 400000, 0, 2),
      ('INV-198', 'Mrs Ade', 120000, 60000, -6),
      ('INV-206', 'Unique Engineering', 650000, 0, 13),
    ])
      r(
        'invoice-${number.toLowerCase()}',
        WorkspaceSection.invoices,
        number,
        person: client,
        amount: amount * 100,
        paid: paid * 100,
        date: at(offset),
        lines: [InvoiceLine(number, 1, amount * 100)],
      ),
    for (final (i, (name, client, offset, minutes, billable)) in [
      ('Homepage layout', 'Unique Engineering', -1, 210, true),
      ('Content calendar', 'Nexora Properties', -1, 120, true),
      ('Client call', 'Unique Engineering', 0, 60, true),
      ('Bookkeeping', 'Admin', 0, 90, false),
    ].indexed)
      r(
        'time-$i',
        WorkspaceSection.time,
        name,
        person: client,
        date: at(offset),
        duration: minutes,
        flagged: billable,
      ),
    r(
      'gig-brand',
      WorkspaceSection.gigs,
      'Brand Refresh',
      person: 'Unique Engineering',
      status: WorkspaceStatus.inProgress,
      date: at(16),
      fields: {
        'health': 'risk',
        'mode': 'simple',
        'next': 'Moodboard',
        'promised': at(3).toIso8601String(),
        'forecast': at(5).toIso8601String(),
        'lateDays': '2',
        'progress': '35',
        'accepted': '0',
        'm0': at(-4).toIso8601String(),
        'm1': at(3).toIso8601String(),
        'm2': at(16).toIso8601String(),
      },
      todos: {
        'Kick-off call': true,
        'Moodboard': false,
        'Final brand pack': false,
      },
    ),
    r(
      'task-domain',
      WorkspaceSection.tasks,
      'Renew domain and email hosting',
      date: at(1),
      fields: {'project': 'Standalone', 'key': 'SK-14', 'priority': 'low'},
    ),
  ];
}
