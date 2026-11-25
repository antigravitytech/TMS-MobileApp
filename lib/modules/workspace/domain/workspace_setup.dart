enum IndividualOccupation {
  designer,
  consultant,
  tutor,
  trader,
  developer,
  other,
}

enum HouseholdRole { coHead, child, relative, staff, security, driver }

class WorkspaceSetup {
  const WorkspaceSetup({
    this.occupation,
    this.crest = 0,
    this.withClients = true,
    this.members = const [],
    this.occasion = '',
    this.date,
  });
  final IndividualOccupation? occupation;
  final int crest;
  final bool withClients;
  final List<({String name, HouseholdRole role})> members;
  final String occasion;
  final DateTime? date;
}
