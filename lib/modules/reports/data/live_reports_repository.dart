part of 'reports_repository.dart';

typedef _Json = Map<String, dynamic>;

/// Daily reports over `/routine` and performance over `/report`.
class LiveReportsRepository implements ReportsRepository {
  const LiveReportsRepository(this._network, {this.workspace});

  final NetworkCallsRepository _network;
  final AccountWorkspace? workspace;

  String get _ws {
    final id = workspace?.id;
    if (id == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    return Uri.encodeComponent(id);
  }

  Future<T> _get<T>(String path, [Map<String, dynamic>? query]) async =>
      accountPayload(await _network.get<T>(path, queryParameters: query));

  static String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Future<DailyReport?> dailyReport() async {
    final body = await _get<Object>('/routine/list-my-routines/$_ws/');
    final routines = _parse(() => _rows(body));
    final mine = _parse(
      () => routines
          .where((r) => (r['routine'] as _Json)['kind'] == 'report')
          .firstOrNull,
    );
    if (mine == null) return null;
    final routine = mine['routine'] as _Json;
    final occurrence = mine['current_occurrence'] as _Json? ?? const {};
    // The list doesn't carry the questions, so fetch this one routine.
    final detail = await _get<_Json>(
      '/routine/get-routine/${Uri.encodeComponent(routine['id'] as String)}/',
    );
    return _parse(
      () => DailyReport(
        routineId: routine['id'] as String,
        title: routine['title'] as String? ?? '',
        dueTime: routine['due_time'] as String? ?? '',
        date: occurrence['date'] as String? ?? _today,
        canLog: occurrence['can_log'] == true,
        sent: occurrence['log'] != null,
        fields: [
          for (final f in (detail['fields'] as List).cast<_Json>())
            ReportField(
              id: f['id'] as String,
              label: f['label'] as String? ?? '',
              type: f['field_type'] as String? ?? 'long',
              required: f['required'] == true,
              options: (f['options'] as List? ?? const [])
                  .whereType<String>()
                  .toList(),
            ),
        ],
      ),
    );
  }

  @override
  Future<void> send(DailyReport report, Map<String, Object> answers) async {
    accountPayload(
      await _network.post<Object?>(
        '/routine/submit-log/${Uri.encodeComponent(report.routineId)}/',
        data: {'occurrence_date': report.date, 'answers': answers},
      ),
    );
  }

  @override
  Future<TeamReports?> team() async {
    final ws = _ws;
    final [status, summaries] = await Future.wait([
      _get<List<dynamic>>('/routine/team-status/$ws/', {
        'occurrence_date': _today,
      }),
      _get<List<dynamic>>('/routine/list-summaries/$ws/', {'days': 1}),
    ]);
    return _parse(() {
      final routine = status.cast<_Json>().firstOrNull;
      if (routine == null) return null;
      final byUser = {
        for (final s in summaries.cast<_Json>())
          if (s['date'] == _today) s['user_id'] as String: s,
      };
      return TeamReports(
        title: (routine['routine'] as _Json)['title'] as String? ?? '',
        people: [
          for (final m in (routine['members'] as List).cast<_Json>())
            () {
              final user = m['user'] as _Json;
              final summary = byUser[user['id']];
              return TeamReport(
                name: [
                  user['first_name'],
                  user['last_name'],
                ].whereType<String>().join(' ').trim(),
                sent: m['logged'] == true,
                late: m['late'] == true,
                done: summary?['done'] as String? ?? '',
                blockers: summary?['blockers'] as String? ?? '',
              );
            }(),
        ],
      );
    });
  }

  @override
  Future<Performance> performance({
    required bool team,
    required ReportPeriod period,
  }) async {
    final o = await _get<_Json>('/report/get-overview/$_ws/', {
      'scope': team ? 'team' : 'me',
      'preset': period.preset,
    });
    return _parse(() {
      final p = o['period'] as _Json;
      return Performance(
        from: DateTime.parse(p['date_from'] as String),
        to: DateTime.parse(p['date_to'] as String),
        metrics: [
          for (final m in (o['metrics'] as List).cast<_Json>())
            PerfMetric(
              m['key'] as String,
              m['value'] as num? ?? 0,
              m['delta'] as num? ?? 0,
              unit: m['unit'] as String? ?? '',
            ),
        ],
        weekly: [
          for (final w in (o['weekly'] as List? ?? const []).cast<_Json>())
            (
              w['label'] as String? ?? '',
              w['completed'] as int? ?? 0,
              w['returned'] as int? ?? 0,
            ),
        ],
        attention: [
          for (final a in (o['attention'] as List? ?? const []).cast<_Json>())
            (
              '${a['reference'] ?? ''} · ${a['title'] ?? ''}',
              a['meta'] as String? ?? '',
            ),
        ],
      );
    });
  }

  /// A plain array, or the `items` of a page.
  static List<_Json> _rows(Object body) =>
      (body is Map ? body['items'] as List : body as List).cast<_Json>();

  static T _parse<T>(T Function() read) {
    try {
      return read();
    } on TypeError {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    } on FormatException {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
  }
}
