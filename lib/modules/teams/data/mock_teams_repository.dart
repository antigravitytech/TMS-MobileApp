part of 'teams_repository.dart';

/// The prototype's two teams. The signed-in preview user leads Tech Team.
class MockTeamsRepository implements TeamsRepository {
  const MockTeamsRepository(this._preview);
  final WorkspacePreview _preview;

  String get _me => '${_preview.firstName} ${_preview.lastName}';

  @override
  Future<TeamDirectory> teams() async => TeamDirectory(_preview.workspace, [
    TeamItem(
      id: 'mock-tech',
      name: 'Tech Team',
      lead: _me,
      color: '#c4bdf6',
      memberCount: 5,
      progress: 8,
    ),
    const TeamItem(
      id: 'mock-compliance',
      name: 'Compliance',
      lead: 'Ngozi Adeyemi',
      color: '#5fd3c4',
      memberCount: 3,
    ),
  ]);

  @override
  Future<List<TeamMember>> members(TeamItem team) async =>
      team.id == 'mock-tech'
      ? [
          TeamMember(
            userId: 'mock-me',
            name: _me,
            lead: true,
            title: _preview.jobTitle,
            open: 2,
          ),
          const TeamMember(
            userId: 'mock-tb',
            name: 'Tunde Bakare',
            lead: false,
            open: 4,
          ),
          const TeamMember(
            userId: 'mock-ae',
            name: 'Amaka Eze',
            lead: false,
            open: 3,
          ),
          const TeamMember(
            userId: 'mock-sj',
            name: 'Sarah Johnson',
            lead: false,
            open: 2,
          ),
          const TeamMember(
            userId: 'mock-dm',
            name: 'David Mensah',
            lead: false,
            open: 2,
          ),
        ]
      : const [
          TeamMember(
            userId: 'mock-na',
            name: 'Ngozi Adeyemi',
            lead: true,
            open: 1,
          ),
          TeamMember(userId: 'mock-dm', name: 'David Mensah', lead: false),
          TeamMember(
            userId: 'mock-sj',
            name: 'Sarah Johnson',
            lead: false,
            open: 1,
          ),
        ];
}
