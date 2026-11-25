enum EntryKind { payment, pledge, duty, notice, followUp }

class WorkspaceEntry {
  const WorkspaceEntry({
    required this.kind,
    required this.date,
    this.name = '',
    this.note = '',
    this.amount = 0,
    this.method = '',
    this.pledgeIndex,
  });
  final EntryKind kind;
  final DateTime date;
  final String name, note, method;
  final int amount;
  final int? pledgeIndex;

  factory WorkspaceEntry.fromJson(Map<String, dynamic> json) => WorkspaceEntry(
    kind: EntryKind.values.byName(json['kind'] as String),
    date: DateTime.parse(json['date'] as String),
    name: json['name'] as String? ?? '',
    note: json['note'] as String? ?? '',
    amount: json['amount'] as int? ?? 0,
    method: json['method'] as String? ?? '',
    pledgeIndex: json['pledgeIndex'] as int?,
  );
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'date': date.toIso8601String(),
    'name': name,
    'note': note,
    'amount': amount,
    'method': method,
    'pledgeIndex': pledgeIndex,
  };
}
