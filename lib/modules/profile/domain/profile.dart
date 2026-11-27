/// What I'm doing right now, as colleagues see it.
enum Presence {
  available('available'),
  meeting('meeting'),
  focusing('dnd'),
  away('leave');

  const Presence(this.api);

  /// The value the server stores.
  final String api;

  /// Reads a server presence; anything this app can't set reads as away.
  static Presence fromApi(String? value) => switch (value) {
    'available' => available,
    'meeting' || 'busy' => meeting,
    'dnd' => focusing,
    _ => away,
  };
}

/// The badges the workspace awards, in the order they're shown.
enum Badge { firstTime, weekStreak, early, zeroOverdue, century }

/// A colleague shown on my profile.
class ProfilePerson {
  const ProfilePerson({required this.id, required this.name});
  final String id, name;
}

/// Everything my profile page shows, loaded once.
class ProfileSummary {
  const ProfileSummary({
    required this.firstName,
    required this.lastName,
    required this.jobTitle,
    required this.department,
    required this.presence,
    required this.role,
    required this.lineManager,
    required this.projectManager,
    required this.teamLead,
    required this.reportsTo,
    required this.directReports,
    required this.directReportCount,
    required this.team,
    required this.points,
    required this.level,
    required this.streak,
    required this.earned,
    this.bestStreak,
    this.streakHistory = false,
  });

  final String firstName, lastName, jobTitle, department;
  final Presence presence;

  /// `owner`, `admin` or `member`.
  final String role;
  final bool lineManager, projectManager, teamLead;
  final ProfilePerson? reportsTo;
  final List<ProfilePerson> directReports;
  final int directReportCount;

  /// My first team's name, if I'm on one.
  final String? team;
  final int points, level, streak;
  final Set<Badge> earned;

  /// Not available from the server; null hides it.
  final int? bestStreak;

  /// Whether a day-by-day streak history is available to draw.
  final bool streakHistory;

  ProfileSummary withPresence(Presence value) => ProfileSummary(
    firstName: firstName,
    lastName: lastName,
    jobTitle: jobTitle,
    department: department,
    presence: value,
    role: role,
    lineManager: lineManager,
    projectManager: projectManager,
    teamLead: teamLead,
    reportsTo: reportsTo,
    directReports: directReports,
    directReportCount: directReportCount,
    team: team,
    points: points,
    level: level,
    streak: streak,
    earned: earned,
    bestStreak: bestStreak,
    streakHistory: streakHistory,
  );
}

/// Matches a server badge key to one this app draws.
Badge? badgeFromKey(String key) => switch (key) {
  _ when key.startsWith('first_time') => Badge.firstTime,
  _ when key.contains('streak') => Badge.weekStreak,
  _ when key.contains('early') => Badge.early,
  _ when key.contains('overdue') => Badge.zeroOverdue,
  _ when key.contains('100') => Badge.century,
  _ => null,
};
