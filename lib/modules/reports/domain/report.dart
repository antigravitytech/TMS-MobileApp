/// What a report field is for, matched from its label as the server does
/// for summaries: done, next/plan, or blockers.
enum ReportRole { done, plan, blockers, other }

class ReportField {
  const ReportField({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.options = const [],
  });
  final String id, label;

  /// `long`, `short`, `number`, `choice` or `rating`.
  final String type;
  final bool required;
  final List<String> options;

  ReportRole get role {
    final l = label.toLowerCase();
    if (l.contains('block')) return ReportRole.blockers;
    if (l.contains('next') || l.contains('plan') || l.contains('tomorrow')) {
      return ReportRole.plan;
    }
    if (l.contains('finish') || l.contains('done') || l.contains('did')) {
      return ReportRole.done;
    }
    return ReportRole.other;
  }
}

/// Today's daily report for the signed-in person.
class DailyReport {
  const DailyReport({
    required this.routineId,
    required this.title,
    required this.date,
    required this.fields,
    this.dueTime = '',
    this.reviewer = '',
    this.canLog = true,
    this.sent = false,
    this.draft = const {},
    this.projects = const [],
    this.points,
  });
  final String routineId, title, dueTime, reviewer;

  /// Points earned for an on-time report, when known.
  final int? points;

  /// The occurrence being reported, `yyyy-MM-dd`.
  final String date;
  final List<ReportField> fields;
  final bool canLog, sent;

  /// Answers to start from, by field id.
  final Map<String, String> draft;

  /// Projects the report can link to (the design's chips), when offered.
  final List<String> projects;

  DailyReport asSent() => DailyReport(
    routineId: routineId,
    title: title,
    date: date,
    fields: fields,
    dueTime: dueTime,
    reviewer: reviewer,
    canLog: false,
    sent: true,
    projects: projects,
    points: points,
  );
}

/// One person's report today on the Team tab.
class TeamReport {
  const TeamReport({
    required this.name,
    required this.sent,
    this.late = false,
    this.done = '',
    this.blockers = '',
    this.detail = '',
  });
  final String name;
  final bool sent, late;
  final String done, blockers;

  /// A line under the name, such as a monthly rate and streak.
  final String detail;
}

class TeamReports {
  const TeamReports({
    required this.title,
    required this.people,
    this.canNudge = false,
  });

  /// The routine's title, such as "Daily Status Update".
  final String title;
  final List<TeamReport> people;

  /// Whether reminders can be sent (no endpoint yet; prototype only).
  final bool canNudge;
  int get sent => people.where((p) => p.sent).length;
  int get blockers => people
      .where(
        (p) =>
            p.blockers.trim().isNotEmpty &&
            p.blockers.trim().toLowerCase() != 'none',
      )
      .length;
}

/// Overview presets, in the chips' order.
enum ReportPeriod {
  thisWeek('This Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  thisQuarter('This Quarter');

  const ReportPeriod(this.preset);
  final String preset;
}

class PerfMetric {
  const PerfMetric(
    this.key,
    this.value,
    this.delta, {
    this.unit = '',
    this.note,
  });
  final String key, unit;
  final num value, delta;

  /// A caption to show instead of the change, such as "Best: 11 days".
  final String? note;
}

class Performance {
  const Performance({
    required this.from,
    required this.to,
    required this.metrics,
    this.weekly = const [],
    this.attention = const [],
    this.level,
  });
  final DateTime from, to;

  /// Level, points and progress to the next level, when known.
  final ({int level, int points, int toNext, double progress})? level;
  final List<PerfMetric> metrics;

  /// Completed and returned per week, oldest first.
  final List<(String, int, int)> weekly;

  /// Tasks that need attention: title and why.
  final List<(String, String)> attention;

  PerfMetric? metric(String key) =>
      metrics.where((m) => m.key == key).firstOrNull;
}
