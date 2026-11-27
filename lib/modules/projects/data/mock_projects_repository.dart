part of 'projects_repository.dart';

/// The prototype's projects, with milestones dated around today. New
/// projects are kept for the session.
class MockProjectsRepository implements ProjectsRepository {
  MockProjectsRepository(this._me);

  final String _me;
  late final List<ProjectItem> _projects = _seed();
  var _next = 0;

  List<ProjectItem> _seed() {
    final now = DateTime.now();
    DateTime at(int days) => DateTime(now.year, now.month, now.day + days);
    return [
      ProjectItem(
        id: 'mock-portal',
        name: 'Customer Portal Revamp',
        health: ProjectHealth.offTrack,
        owner: _me,
        mode: 'Simple',
        progress: 36,
        milestone: ProjectMilestone('Discovery', at(-27), forecast: at(-1)),
      ),
      ProjectItem(
        id: 'mock-pos',
        name: 'POS rollout — Lagos, Abuja, Kano',
        health: ProjectHealth.offTrack,
        owner: 'Ibrahim Musa',
        mode: 'Advanced',
        progress: 40,
        accepted: 40,
        milestone: ProjectMilestone('Abuja live', at(-15), forecast: at(4)),
      ),
      ProjectItem(
        id: 'mock-app',
        name: 'Mobile App Launch',
        health: ProjectHealth.atRisk,
        owner: _me,
        mode: 'Simple',
        progress: 25,
        milestone: ProjectMilestone('Beta', at(-2)),
      ),
      ProjectItem(
        id: 'mock-hiring',
        name: 'Q4 hiring plan',
        health: ProjectHealth.atRisk,
        owner: _me,
        mode: 'Simple',
        progress: 62,
        milestone: ProjectMilestone('Discovery', at(3)),
      ),
    ];
  }

  @override
  Future<List<ProjectItem>> list() async => List.of(_projects);

  @override
  Future<ProjectItem> create(String name) async {
    final project = ProjectItem(
      id: 'mock-new-${_next++}',
      name: name.trim(),
      health: ProjectHealth.onTrack,
      owner: _me,
      mode: 'Simple',
    );
    _projects.add(project);
    return project;
  }
}
