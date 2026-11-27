enum ProjectHealth {
  offTrack('off_track'),
  atRisk('at_risk'),
  onTrack('on_track');

  const ProjectHealth(this.code);
  final String code;
  static ProjectHealth parse(String code) =>
      values.firstWhere((h) => h.code == code, orElse: () => onTrack);
}

/// The next milestone a project has promised.
class ProjectMilestone {
  const ProjectMilestone(this.name, this.due, {this.forecast});
  final String name;
  final DateTime due;

  /// When it's now expected, when the plan has a forecast.
  final DateTime? forecast;

  /// Working days (Monday to Friday) it is past [due]; 0 when not late.
  int workingDaysLate(DateTime today) {
    var day = DateTime(due.year, due.month, due.day);
    final end = DateTime(today.year, today.month, today.day);
    var late = 0;
    while (day.isBefore(end)) {
      day = day.add(const Duration(days: 1));
      if (day.weekday <= DateTime.friday) late++;
    }
    return late;
  }
}

class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.name,
    required this.health,
    required this.owner,
    this.mode,
    this.progress = 0,
    this.accepted = 0,
    this.milestone,
  });
  final String id, name, owner;
  final ProjectHealth health;

  /// The plan's mode (`Simple`, `Intermediate`, `Advanced`) when known.
  final String? mode;

  /// Percent of tasks done, and of finished tasks accepted first time.
  final int progress, accepted;
  final ProjectMilestone? milestone;
}
