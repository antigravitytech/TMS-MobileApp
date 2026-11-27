class TeamItem {
  const TeamItem({
    required this.id,
    required this.name,
    required this.lead,
    required this.color,
    required this.memberCount,
    this.progress = 0,
  });
  final String id, name, lead;

  /// `#rrggbb`.
  final String color;
  final int memberCount;

  /// Percent of team tasks completed in the last seven days.
  final int progress;
}

class TeamMember {
  const TeamMember({
    required this.userId,
    required this.name,
    required this.lead,
    this.title = '',
    this.open = 0,
  });
  final String userId, name, title;
  final bool lead;

  /// Tasks in progress.
  final int open;
}

/// The teams screen: the workspace's name and its teams.
class TeamDirectory {
  const TeamDirectory(this.workspace, this.teams);
  final String workspace;
  final List<TeamItem> teams;
}
