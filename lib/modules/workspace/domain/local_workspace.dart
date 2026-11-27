import 'workspace_entry.dart';
import 'workspace_kind.dart';

class InvoiceLine {
  const InvoiceLine(this.description, this.quantity, this.rate);

  factory InvoiceLine.fromJson(Map<String, dynamic> json) => InvoiceLine(
    json['description'] as String,
    json['quantity'] as int,
    json['rate'] as int,
  );

  final String description;
  final int quantity;
  final int rate;

  int get total => quantity * rate;

  Map<String, Object> toJson() => {
    'description': description,
    'quantity': quantity,
    'rate': rate,
  };
}

class WorkspaceRecord {
  const WorkspaceRecord({
    required this.id,
    required this.section,
    required this.title,
    this.notes = '',
    this.person = '',
    this.group = '',
    this.date,
    this.amount = 0,
    this.paid = 0,
    this.duration = 0,
    this.status = WorkspaceStatus.todo,
    this.requiresReview = false,
    this.flagged = false,
    this.options = const [],
    this.vote,
    this.invoiceLines = const [],
    this.points = 1,
    this.entries = const [],
    this.fields = const {},
    this.todos = const {},
  });

  factory WorkspaceRecord.fromJson(Map<String, dynamic> json) =>
      WorkspaceRecord(
        id: json['id'] as String,
        section: WorkspaceSection.values.byName(json['section'] as String),
        title: json['title'] as String,
        notes: json['notes'] as String? ?? '',
        person: json['person'] as String? ?? '',
        group: json['group'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        amount: json['amount'] as int? ?? 0,
        paid: json['paid'] as int? ?? 0,
        duration: json['duration'] as int? ?? 0,
        status: WorkspaceStatus.values.byName(
          json['status'] as String? ?? WorkspaceStatus.todo.name,
        ),
        requiresReview: json['requiresReview'] as bool? ?? false,
        flagged: json['flagged'] as bool? ?? false,
        options: List<String>.from(json['options'] as List? ?? const []),
        vote: json['vote'] as int?,
        entries: [
          for (final e in json['entries'] as List? ?? const [])
            WorkspaceEntry.fromJson(e as Map<String, dynamic>),
        ],
        points: json['points'] as int? ?? 1,
        fields: Map<String, String>.from(json['fields'] as Map? ?? const {}),
        todos: Map<String, bool>.from(json['todos'] as Map? ?? const {}),
        invoiceLines: [
          for (final line in json['invoiceLines'] as List? ?? const [])
            InvoiceLine.fromJson(line as Map<String, dynamic>),
        ],
      );

  final String id;
  final WorkspaceSection section;
  final String title;
  final String notes;
  final String person;
  final String group;
  final DateTime? date;
  // Monetary amounts are stored in kobo.
  final int amount;
  final int paid;
  final int duration;
  final WorkspaceStatus status;
  final bool requiresReview;
  final bool flagged;
  final List<String> options;
  final int? vote;
  final List<InvoiceLine> invoiceLines;
  final int points;
  final List<WorkspaceEntry> entries;

  int pledgeBalance(int index) =>
      entries[index].amount -
      entries
          .where((e) => e.kind == EntryKind.payment && e.pledgeIndex == index)
          .fold<int>(0, (n, e) => n + e.amount);
  final Map<String, String> fields;
  final Map<String, bool> todos;

  int get outstanding => (amount - paid).clamp(0, amount);

  WorkspaceRecord copyWith({
    String? id,
    String? notes,
    int? paid,
    List<WorkspaceEntry>? entries,
    Map<String, String>? fields,
    String? group,
    String? person,
    DateTime? date,
    Map<String, bool>? todos,
    WorkspaceStatus? status,
    bool? flagged,
    int? vote,
  }) => WorkspaceRecord(
    id: id ?? this.id,
    section: section,
    title: title,
    notes: notes ?? this.notes,
    person: person ?? this.person,
    group: group ?? this.group,
    date: date ?? this.date,
    amount: amount,
    paid: paid ?? this.paid,
    duration: duration,
    status: status ?? this.status,
    requiresReview: requiresReview,
    flagged: flagged ?? this.flagged,
    options: options,
    vote: vote ?? this.vote,
    invoiceLines: invoiceLines,
    fields: fields ?? this.fields,
    points: points,
    entries: entries ?? this.entries,
    todos: todos ?? this.todos,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'section': section.name,
    'title': title,
    'notes': notes,
    'person': person,
    'group': group,
    'date': date?.toIso8601String(),
    'amount': amount,
    'paid': paid,
    'duration': duration,
    'status': status.name,
    'requiresReview': requiresReview,
    'flagged': flagged,
    'options': options,
    'vote': vote,
    'points': points,
    'entries': [for (final e in entries) e.toJson()],
    'fields': fields,
    'todos': todos,
    'invoiceLines': invoiceLines.map((line) => line.toJson()).toList(),
  };
}

class PointsAlreadySpent implements Exception {
  const PointsAlreadySpent();
}

class LocalWorkspace {
  const LocalWorkspace({
    required this.id,
    required this.kind,
    this.name = '',
    this.crest = 0,
    this.occupation = '',
    this.withClients = true,
    this.hourlyRate = 1500000,
    this.occasion = '',
    this.eventDate,
    this.eventVenue = '',
    this.eventCapacity = 0,
    this.eventBudget = 0,
    this.records = const [],
    this.redeemedPoints = const {},
  });

  factory LocalWorkspace.fromJson(Map<String, dynamic> json) => LocalWorkspace(
    id: json['id'] as String,
    kind: WorkspaceKind.values.byName(json['kind'] as String),
    name: json['name'] as String? ?? '',
    crest: json['crest'] as int? ?? 0,
    occupation: json['occupation'] as String? ?? '',
    withClients: json['withClients'] as bool? ?? true,
    hourlyRate: json['hourlyRate'] as int? ?? 1500000,
    occasion: json['occasion'] as String? ?? '',
    eventDate: DateTime.tryParse(json['eventDate'] as String? ?? ''),
    eventVenue: json['eventVenue'] as String? ?? '',
    eventCapacity: json['eventCapacity'] as int? ?? 0,
    eventBudget: json['eventBudget'] as int? ?? 0,
    redeemedPoints: Map<String, int>.from(
      json['redeemedPoints'] as Map? ?? const {},
    ),
    records: [
      for (final record in json['records'] as List)
        WorkspaceRecord.fromJson(record as Map<String, dynamic>),
    ],
  );

  final String id;
  final WorkspaceKind kind;
  final String name, occupation, occasion;
  final int crest;
  final bool withClients;
  final int hourlyRate;
  final DateTime? eventDate;
  final String eventVenue;
  final int eventCapacity;
  final int eventBudget;
  final List<WorkspaceRecord> records;
  final Map<String, int> redeemedPoints;

  Iterable<WorkspaceRecord> items(WorkspaceSection section) =>
      records.where((record) => record.section == section);

  int availablePoints(String person) {
    final earned = records
        .where(
          (r) =>
              r.section.view == WorkspaceView.review &&
              r.status == WorkspaceStatus.done &&
              r.person == person,
        )
        .fold(0, (sum, r) => sum + r.points);
    return earned - (redeemedPoints[person] ?? 0);
  }

  LocalWorkspace copyWith({
    String? name,
    int? hourlyRate,
    DateTime? eventDate,
    String? eventVenue,
    int? eventCapacity,
    int? eventBudget,
    List<WorkspaceRecord>? records,
    Map<String, int>? redeemedPoints,
  }) => LocalWorkspace(
    id: id,
    kind: kind,
    name: name ?? this.name,
    hourlyRate: hourlyRate ?? this.hourlyRate,
    crest: crest,
    occupation: occupation,
    withClients: withClients,
    occasion: occasion,
    eventDate: eventDate ?? this.eventDate,
    eventVenue: eventVenue ?? this.eventVenue,
    eventCapacity: eventCapacity ?? this.eventCapacity,
    eventBudget: eventBudget ?? this.eventBudget,
    records: records ?? this.records,
    redeemedPoints: redeemedPoints ?? this.redeemedPoints,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'occupation': occupation,
    'crest': crest,
    'withClients': withClients,
    'hourlyRate': hourlyRate,
    'occasion': occasion,
    'eventDate': eventDate?.toIso8601String(),
    'eventVenue': eventVenue,
    'eventCapacity': eventCapacity,
    'eventBudget': eventBudget,
    'redeemedPoints': redeemedPoints,
    'records': records.map((record) => record.toJson()).toList(),
  };
}

class WorkspaceDirectory {
  const WorkspaceDirectory({
    required this.workspaces,
    required this.activeId,
    this.nextId = 1,
  });

  factory WorkspaceDirectory.fromJson(Map<String, dynamic> json) =>
      WorkspaceDirectory(
        workspaces: [
          for (final entry in json['workspaces'] as List)
            LocalWorkspace.fromJson(entry as Map<String, dynamic>),
        ],
        activeId: json['activeId'] as String,
        nextId: json['nextId'] as int,
      );

  static const companyId = 'business';
  final List<LocalWorkspace> workspaces;
  final String activeId;
  final int nextId;

  LocalWorkspace? get active {
    for (final entry in workspaces) {
      if (entry.id == activeId) return entry;
    }
    return null;
  }

  WorkspaceDirectory copyWith({
    List<LocalWorkspace>? workspaces,
    String? activeId,
    int? nextId,
  }) => WorkspaceDirectory(
    workspaces: workspaces ?? this.workspaces,
    activeId: activeId ?? this.activeId,
    nextId: nextId ?? this.nextId,
  );

  Map<String, Object> toJson() => {
    'activeId': activeId,
    'nextId': nextId,
    'workspaces': workspaces.map((space) => space.toJson()).toList(),
  };
}
