import '../../../core/network/api_response.dart';
import '../../authentication/domain/account.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import 'live_dashboard_data.dart';

LocalWorkspace projectLiveWorkspace(LiveHomeData data) {
  final workspace = data.workspace;
  final kindName = workspace.kind == 'specials'
      ? workspace.subtype
      : workspace.kind;
  final kind = WorkspaceKind.values
      .where((kind) => kind.name == kindName)
      .firstOrNull;
  if (kind == null) {
    throw const AccountFailure(NetworkFailureType.invalidResponse);
  }

  final records = <WorkspaceRecord>[];
  for (final module in data.modules) {
    final key = switch (module['key']) {
      'firsttimers' => 'firstTimers',
      'runsheet' => 'programme',
      final name => name,
    };
    final section = kind.sections
        .where((section) => section.name == key)
        .firstOrNull;
    if (section == null) continue;
    for (final row in dashboardRows(module['items'])) {
      _add(records, section, row);
    }
    for (final column in dashboardRows(module['columns'])) {
      _add(records, section, column);
    }
    final question = dashboardText(module['question']);
    if (question.isNotEmpty) {
      final options = dashboardRows(module['options']);
      records.add(
        WorkspaceRecord(
          id: 'poll-${section.name}',
          section: section,
          title: question,
          options: options
              .map(
                (option) => dashboardText(
                  option['label'],
                  dashboardText(option['text']),
                ),
              )
              .toList(),
          fields: {
            for (final (index, option) in options.indexed)
              'votes$index':
                  '${dashboardInteger(option['votes'] ?? option['count'])}',
          },
        ),
      );
    }
  }

  void replace(String key, WorkspaceSection section) {
    if (data.failed.contains(key)) return;
    records.removeWhere((record) => record.section == section);
    for (final row in data.rows(key)) {
      _add(records, section, row);
    }
  }

  if (kind == WorkspaceKind.individual) {
    replace('projects', WorkspaceSection.gigs);
    replace('tasks', WorkspaceSection.tasks);
  }
  if (kind == WorkspaceKind.family) {
    replace('school', WorkspaceSection.school);
    final family = data.object('family');
    for (final row in dashboardRows(family['errands'])) {
      _add(records, WorkspaceSection.errands, row);
    }
    for (final row in dashboardRows(family['rewards'])) {
      _add(records, WorkspaceSection.rewards, row);
    }
    for (final poll in data.rows('polls')) {
      final title = dashboardText(poll['question']);
      if (poll['id'] is! String || title.isEmpty) continue;
      records.add(
        WorkspaceRecord(
          id: poll['id'] as String,
          section: WorkspaceSection.poll,
          title: title,
          options: dashboardRows(poll['options'])
              .map((option) => dashboardText(option['label']))
              .where((label) => label.isNotEmpty)
              .toList(),
        ),
      );
    }
  }

  final church = data.object('church');
  if (kind == WorkspaceKind.church && church.isNotEmpty) {
    const sections = {
      'services': WorkspaceSection.services,
      'funds': WorkspaceSection.giving,
      'units': WorkspaceSection.units,
      'prayers': WorkspaceSection.prayers,
      'first_timers': WorkspaceSection.firstTimers,
    };
    records.removeWhere((record) => sections.containsValue(record.section));
    final giving = dashboardRows(church['giving']);
    for (final section in sections.entries) {
      for (final row in dashboardRows(church[section.key])) {
        final paid = section.key == 'funds'
            ? giving
                  .where((gift) => gift['fund_id'] == row['id'])
                  .fold(
                    0,
                    (total, gift) => total + dashboardKobo(gift['amount']),
                  )
            : null;
        _add(records, section.value, row, paid: paid);
      }
    }
  }

  final event = data.object('event');
  if (kind == WorkspaceKind.event) {
    replace('guests', WorkspaceSection.guests);
    replace('vendors', WorkspaceSection.vendors);
    replace('programme', WorkspaceSection.programme);
    for (final table in dashboardRows(event['tables'])) {
      _add(records, WorkspaceSection.seating, table);
    }
  }
  final setup = dashboardObject(data.object('workspace')['setup']);
  final timeModule = data.modules
      .where((module) => module['key'] == 'time')
      .firstOrNull;
  return LocalWorkspace(
    id: workspace.id,
    kind: kind,
    name: dashboardText(
      event['name'],
      dashboardText(church['name'], data.name),
    ),
    occasion: dashboardText(setup['event_name']),
    eventDate: dashboardDate(event['date'] ?? setup['event_date']),
    eventVenue: dashboardText(event['venue']),
    eventCapacity: dashboardInteger(event['capacity']),
    eventBudget: dashboardKobo(event['budget']),
    hourlyRate: dashboardKobo(timeModule?['rate']),
    records: List.unmodifiable(records),
  );
}

void _add(
  List<WorkspaceRecord> records,
  WorkspaceSection section,
  DashboardJson row, {
  int? paid,
}) {
  final id = dashboardText(row['id']);
  final title = dashboardText(
    row['title'],
    dashboardText(
      row['name'],
      dashboardText(row['text'], dashboardText(row['task'])),
    ),
  );
  if (id.isEmpty || title.isEmpty) return;
  final date = dashboardDate(
    row['date'] ??
        row['due_date'] ??
        row['first_visit'] ??
        row['due'] ??
        row['next_due'],
  );
  if (date == null &&
      const {
        WorkspaceSection.services,
        WorkspaceSection.meetings,
        WorkspaceSection.sessions,
      }.contains(section)) {
    return;
  }
  final attendance = dashboardObject(row['attendance']);
  records.add(
    WorkspaceRecord(
      id: id,
      section: section,
      title: title,
      date: date,
      notes: dashboardText(
        row['note'],
        dashboardText(row['description'], dashboardText(row['notes'])),
      ),
      person: dashboardText(
        row['owner'],
        dashboardText(row['lead'], dashboardText(row['client'])),
      ),
      group: dashboardText(row['group']),
      amount: dashboardKobo(row['amount'] ?? row['target'] ?? row['quote']),
      paid:
          paid ??
          (row['payments'] is List
              ? dashboardRows(row['payments']).fold(
                  0,
                  (total, payment) => total + dashboardKobo(payment['amount']),
                )
              : dashboardKobo(row['paid'] ?? row['paid_amount'])),
      duration: section == WorkspaceSection.time
          ? ((row['hours'] as num? ?? 0) * 60).round()
          : dashboardInteger(
              row['attending_count'] ?? row['party_size'] ?? row['seats'],
            ),
      flagged: row['billable'] == true,
      points: dashboardInteger(row['cost'] ?? row['points']),
      status: switch (row['rsvp'] ?? row['status'] ?? row['state']) {
        'attending' || 'yes' || 'confirmed' => WorkspaceStatus.confirmed,
        'no' || 'not_attending' || 'declined' => WorkspaceStatus.declined,
        'maybe' => WorkspaceStatus.maybe,
        'invited' || 'pending' => WorkspaceStatus.pending,
        'submitted' => WorkspaceStatus.submitted,
        'returned' => WorkspaceStatus.returned,
        'done' ||
        'completed' ||
        'resolved' ||
        'answered' => WorkspaceStatus.done,
        'doing' || 'in_progress' => WorkspaceStatus.inProgress,
        _ when section == WorkspaceSection.guests => WorkspaceStatus.notInvited,
        _ => WorkspaceStatus.todo,
      },
      fields: {
        if (row['stage'] case final String stage)
          'stage': stage == 'contacted' ? 'called' : stage,
        if (row['kind'] case final String kind) 'kind': kind,
        if (row['status'] case final String status)
          'stage': dashboardText(row['stage'], status),
        if (row['due'] case final String due) 'due': due,
        if ((row['time'] ?? row['start']) case final String time) 'time': time,
        if (row['checked_in_at'] != null) 'checkedIn': 'true',
        if (attendance.isNotEmpty)
          'attendance':
              '${attendance.values.fold(0, (total, value) => total + dashboardInteger(value))}',
      },
    ),
  );
}

int dashboardKobo(Object? value) {
  final match = RegExp(
    r'^(-?)(\d+)(?:\.(\d+))?$',
  ).firstMatch(value?.toString() ?? '');
  if (match == null) return 0;
  final whole = int.tryParse(match[2]!) ?? 0;
  final cents = int.parse((match[3] ?? '').padRight(2, '0').substring(0, 2));
  return (whole * 100 + cents) * (match[1] == '-' ? -1 : 1);
}
