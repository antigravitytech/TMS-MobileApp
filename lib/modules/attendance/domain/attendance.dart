/// The server's `DayStatus`.
enum DayStatus {
  early('early'),
  onTime('on_time'),
  late('late'),
  absent('absent'),
  notClockedIn('not_clocked_in'),
  holiday('holiday'),
  offDay('off_day'),
  exempt('exempt'),
  upcoming('upcoming');

  const DayStatus(this.code);
  final String code;
  static DayStatus parse(String? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => notClockedIn);

  /// Clocked in that day.
  bool get present => this == early || this == onTime || this == late;
}

/// One clock-in and (once out) clock-out.
class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.clockIn,
    required this.status,
    this.clockOut,
    this.minutesWorked,
    this.place = '',
  });
  final DateTime date, clockIn;
  final DateTime? clockOut;

  /// How the clock-in compared with the schedule.
  final DayStatus status;
  final int? minutesWorked;
  final String place;
}

/// Today for the signed-in person.
class AttendanceToday {
  const AttendanceToday({
    required this.date,
    required this.status,
    required this.enabled,
    this.record,
    this.place = '',
    this.window = const AttendanceWindow('09:00', '09:00', '17:00'),
    this.holiday,
  });
  final DateTime date;
  final DayStatus status;

  /// False when the workspace has switched attendance off.
  final bool enabled;
  final AttendanceRecord? record;

  /// The main workplace location's name, and its centre for weather.
  final String place;
  final AttendanceWindow window;
  final String? holiday;

  bool get clockedIn => record != null && record!.clockOut == null;
  bool get clockedOut => record?.clockOut != null;
}

/// The arrival window and leaving time, as local `HH:mm`.
class AttendanceWindow {
  const AttendanceWindow(
    this.start,
    this.until,
    this.end, {
    this.lat,
    this.lng,
  });
  final String start, until, end;

  /// The workplace's centre, used to ask for the weather.
  final double? lat, lng;
}

/// How this month is going.
class AttendanceStats {
  const AttendanceStats({
    required this.early,
    required this.onTime,
    required this.late,
    required this.absent,
    required this.punctuality,
    required this.minutesWorked,
    required this.days,
    this.avgIn,
    this.avgOut,
    this.lateLimit,
  });
  final int early, onTime, late, absent, punctuality, minutesWorked;
  final String? avgIn, avgOut;

  /// Lates allowed in the period, or null when lateness isn't tracked.
  final int? lateLimit;

  /// Every day from the start of the month, oldest first.
  final List<(DateTime, DayStatus)> days;
}

/// A person on the team board.
class BoardEntry {
  const BoardEntry({
    required this.name,
    required this.status,
    this.jobTitle = '',
    this.record,
  });
  final String name, jobTitle;
  final DayStatus status;
  final AttendanceRecord? record;
}

/// Temperature and a WMO weather code.
typedef Weather = ({int celsius, int code});

/// The server refused a clock-in or clock-out and said why, for example
/// "You're 1.2 km from Head office."
class AttendanceRefused implements Exception {
  const AttendanceRefused(this.detail);
  final String detail;
  @override
  String toString() => detail;
}
