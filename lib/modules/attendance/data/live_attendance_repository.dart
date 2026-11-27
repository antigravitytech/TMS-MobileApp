part of 'attendance_repository.dart';

typedef _Json = Map<String, dynamic>;

/// Attendance over the `/attendance` API for the signed-in workspace.
class LiveAttendanceRepository implements AttendanceRepository {
  const LiveAttendanceRepository(
    this._network,
    this._location, {
    this.workspace,
  });

  final NetworkCallsRepository _network;
  final LocationService _location;
  final AccountWorkspace? workspace;

  String get _ws {
    final id = workspace?.id;
    if (id == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    return Uri.encodeComponent(id);
  }

  Future<T> _get<T>(String path, [Map<String, dynamic>? query]) async =>
      accountPayload(await _network.get<T>(path, queryParameters: query));

  @override
  Future<AttendanceToday> today() async =>
      _parse(_today, await _get<_Json>('/attendance/get-today/$_ws/'));

  @override
  Future<AttendanceStats> month() async {
    final s = await _get<_Json>('/attendance/get-stats/$_ws/', {
      'period': 'month',
    });
    return _parse((_) {
      return AttendanceStats(
        early: s['early'] as int,
        onTime: s['on_time'] as int,
        late: s['late'] as int,
        absent: s['absent'] as int,
        punctuality: s['punctuality'] as int,
        minutesWorked: s['minutes_worked'] as int? ?? 0,
        avgIn: s['avg_clock_in'] as String?,
        avgOut: s['avg_clock_out'] as String?,
        lateLimit: s['late_limit'] as int?,
        days: [
          for (final d in (s['days'] as List).cast<_Json>())
            (
              DateTime.parse(d['date'] as String),
              DayStatus.parse(d['status'] as String?),
            ),
        ],
      );
    }, s);
  }

  @override
  Future<List<AttendanceRecord>> history() async {
    final page = await _get<_Json>('/attendance/list-records/$_ws/', {
      'page_size': 30,
    });
    return _parse(
      (p) => [for (final r in (p['items'] as List).cast<_Json>()) _record(r)],
      page,
    );
  }

  @override
  Future<List<BoardEntry>> board() async {
    final rows = await _get<List<dynamic>>('/attendance/list-board/$_ws/');
    return _parse(
      (_) => [
        for (final e in rows.cast<_Json>())
          BoardEntry(
            name: _name(e['user']),
            jobTitle: e['job_title'] as String? ?? '',
            status: DayStatus.parse(e['status'] as String?),
            record: e['record'] == null ? null : _record(e['record'] as _Json),
          ),
      ],
      const <String, dynamic>{},
    );
  }

  @override
  Future<Weather?> weather(AttendanceToday today) async {
    final (lat, lng) = (today.window.lat, today.window.lng);
    if (lat == null || lng == null) return null;
    // Weather is optional: hide it when the provider is unavailable.
    final response = await _network.get<_Json>(
      '/attendance/get-weather/$_ws/',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    final w = response.data;
    if (!response.hasData || w == null) return null;
    final t = w['temperature_c'], c = w['code'];
    return t is num && c is num ? (celsius: t.round(), code: c.toInt()) : null;
  }

  @override
  Future<AttendanceToday> clockIn() => _clock('clock-in');

  @override
  Future<AttendanceToday> clockOut() => _clock('clock-out');

  Future<AttendanceToday> _clock(String action) async {
    final ws = _ws;
    final position = await _location.current();
    final response = await _network.post<_Json>(
      '/attendance/$action/$ws/',
      data: {
        'lat': position?.lat,
        'lng': position?.lng,
        'accuracy_m': position?.accuracy.round(),
      },
    );
    // 403 and 409 carry a sentence meant for the person; show it as is.
    final detail = response.response?.data;
    if (!response.isSuccess &&
        (response.statusCode == 403 || response.statusCode == 409) &&
        detail is Map &&
        detail['detail'] is String) {
      throw AttendanceRefused(detail['detail'] as String);
    }
    return _parse(_today, accountPayload(response));
  }

  // ----- Mapping -----

  static AttendanceToday _today(_Json t) {
    final schedule = t['schedule'] as _Json? ?? const {};
    final locations = (t['locations'] as List? ?? const []).cast<_Json>();
    final center = locations.firstOrNull?['center'] as _Json?;
    return AttendanceToday(
      date: DateTime.parse(t['date'] as String),
      status: DayStatus.parse(t['status'] as String?),
      enabled: t['enabled'] as bool? ?? true,
      record: t['record'] == null ? null : _record(t['record'] as _Json),
      place: locations.firstOrNull?['name'] as String? ?? '',
      holiday: (t['holiday'] as _Json?)?['name'] as String?,
      window: AttendanceWindow(
        schedule['start'] as String? ?? '09:00',
        schedule['start_until'] as String? ??
            schedule['start'] as String? ??
            '09:00',
        schedule['end'] as String? ?? '17:00',
        lat: (center?['lat'] as num?)?.toDouble(),
        lng: (center?['lng'] as num?)?.toDouble(),
      ),
    );
  }

  static AttendanceRecord _record(_Json r) => AttendanceRecord(
    date: DateTime.parse(r['date'] as String),
    clockIn: DateTime.parse(r['clock_in_at'] as String).toLocal(),
    clockOut: DateTime.tryParse(r['clock_out_at'] as String? ?? '')?.toLocal(),
    status: DayStatus.parse(r['in_status'] as String?),
    minutesWorked: r['minutes_worked'] as int?,
    place: r['place'] as String? ?? '',
  );

  static String _name(Object? person) => person is _Json
      ? [
          person['first_name'],
          person['last_name'],
        ].whereType<String>().join(' ').trim()
      : '';

  static T _parse<T>(T Function(_Json) read, _Json body) {
    try {
      return read(body);
    } on TypeError {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    } on FormatException {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
  }
}
