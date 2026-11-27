part of 'profile_repository.dart';

/// The reference profile, kept in the preview so other screens agree.
class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository(this._preview);

  final WorkspacePreview _preview;

  static const _statuses = {
    'profile.available': Presence.available,
    'profile.in_a_meeting': Presence.meeting,
    'profile.focusing': Presence.focusing,
    'profile.out_of_office': Presence.away,
  };

  @override
  Future<ProfileSummary> summary() async => ProfileSummary(
    firstName: _preview.firstName,
    lastName: _preview.lastName,
    jobTitle: _preview.jobTitle,
    department: 'Engineering',
    presence: _statuses[_preview.status] ?? Presence.away,
    role: 'member',
    lineManager: true,
    projectManager: true,
    teamLead: true,
    reportsTo: const ProfilePerson(id: '', name: 'Ibrahim Musa'),
    directReports: const [
      ProfilePerson(id: '', name: 'Tunde Bakare'),
      ProfilePerson(id: '', name: 'Amaka Eze'),
      ProfilePerson(id: '', name: 'David Musa'),
      ProfilePerson(id: '', name: 'Sade Johnson'),
    ],
    directReportCount: 4,
    team: 'Tech Team',
    points: 640,
    level: 2,
    streak: 4,
    bestStreak: 11,
    earned: const {Badge.firstTime, Badge.weekStreak, Badge.early},
    streakHistory: true,
  );

  @override
  Future<Presence> presence() async =>
      _statuses[_preview.status] ?? Presence.away;

  @override
  Future<Presence> setPresence(Presence presence) async {
    _preview.setStatus(
      _statuses.entries.firstWhere((e) => e.value == presence).key,
    );
    return presence;
  }
}
