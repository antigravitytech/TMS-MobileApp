part of 'attendance_repository.dart';

/// The prototype's attendance, dated around today. Clocking in and out is
/// kept in the shared preview state.
class MockAttendanceRepository implements AttendanceRepository {
  const MockAttendanceRepository(this._preview);
  final WorkspacePreview _preview;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _at(DateTime day, int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  /// Past weekdays this month with the design's mix of statuses.
  static List<(DateTime, DayStatus)> get _days {
    final first = DateTime(_today.year, _today.month);
    return [
      for (
        var d = first;
        d.isBefore(_today);
        d = d.add(const Duration(days: 1))
      )
        if (d.weekday <= DateTime.friday)
          (
            d,
            switch (d.day % 9) {
              3 => DayStatus.early,
              8 => DayStatus.absent,
              5 => DayStatus.late,
              _ => DayStatus.onTime,
            },
          ),
    ];
  }

  @override
  Future<AttendanceToday> today() async {
    final now = DateTime.now();
    final record = _preview.clockedIn || _preview.clockedOut
        ? AttendanceRecord(
            date: _today,
            clockIn: _at(_today, 8, 52),
            status: DayStatus.early,
            clockOut: _preview.clockedOut ? now : null,
            place: 'Head office',
          )
        : null;
    return AttendanceToday(
      date: _today,
      status: record?.status ?? DayStatus.notClockedIn,
      enabled: true,
      record: record,
      place: 'Head office',
      window: const AttendanceWindow('09:00', '09:30', '17:00'),
    );
  }

  @override
  Future<AttendanceStats> month() async {
    final days = _days;
    int count(DayStatus s) => days.where((d) => d.$2 == s).length;
    final expected = days.length;
    return AttendanceStats(
      early: count(DayStatus.early),
      onTime: count(DayStatus.onTime),
      late: count(DayStatus.late),
      absent: count(DayStatus.absent),
      punctuality: expected == 0
          ? 100
          : ((count(DayStatus.early) + count(DayStatus.onTime)) /
                    expected *
                    100)
                .round(),
      minutesWorked: 6559,
      avgIn: '09:01',
      avgOut: '17:25',
      lateLimit: 5,
      days: days,
    );
  }

  @override
  Future<List<AttendanceRecord>> history() async => [
    for (final (day, status) in _days.reversed)
      if (status.present)
        AttendanceRecord(
          date: day,
          clockIn: _at(
            day,
            status == DayStatus.late ? 9 : 8,
            status == DayStatus.late ? 41 : 52,
          ),
          clockOut: _at(day, 17, 25),
          status: status,
          minutesWorked: status == DayStatus.late ? 474 : 513,
          place: 'Head office',
        ),
  ];

  @override
  Future<List<BoardEntry>> board() async => [
    BoardEntry(
      name: 'Tunde Bakare',
      status: DayStatus.early,
      record: AttendanceRecord(
        date: _today,
        clockIn: _at(_today, 8, 41),
        status: DayStatus.early,
        place: 'Head office',
      ),
    ),
    BoardEntry(
      name: 'David Mensah',
      status: DayStatus.onTime,
      record: AttendanceRecord(
        date: _today,
        clockIn: _at(_today, 9, 12),
        status: DayStatus.onTime,
        place: 'Remote',
      ),
    ),
    BoardEntry(
      name: 'Amaka Eze',
      status: DayStatus.late,
      record: AttendanceRecord(
        date: _today,
        clockIn: _at(_today, 9, 38),
        status: DayStatus.late,
        place: 'Head office',
      ),
    ),
    const BoardEntry(name: 'Sarah Johnson', status: DayStatus.notClockedIn),
  ];

  @override
  Future<Weather?> weather(AttendanceToday today) async =>
      (celsius: 29, code: 2);

  @override
  Future<AttendanceToday> clockIn() async {
    // The design shows a short location check before clocking in.
    await Future<void>.delayed(const Duration(milliseconds: 1050));
    _preview.setAttendance(inOffice: true);
    return today();
  }

  @override
  Future<AttendanceToday> clockOut() async {
    _preview.setAttendance(inOffice: false);
    return today();
  }
}
