part of 'search_repository.dart';

/// The reference results, matched by name, ID and their reference wording.
class MockSearchRepository implements SearchRepository {
  const MockSearchRepository(this._tasks);

  final TasksRepository _tasks;

  static const _taskCopy = {
    'TK-190': ('search.hiring_subtitle', 'in progress today'),
    'TK-142': ('search.webhook_subtitle', 'submitted round 2'),
  };

  static const _people = [
    (
      SearchPerson(
        id: '',
        name: 'Tunde Bakare',
        detailKey: 'search.tunde_subtitle',
      ),
      'tech team online',
    ),
    (
      SearchPerson(
        id: '',
        name: 'Ibrahim Musa',
        detailKey: 'search.ibrahim_subtitle',
      ),
      'your line manager',
    ),
  ];

  static final _projects = [
    (
      (
        project: const ProjectItem(
          id: 'portal',
          name: 'Customer Portal Revamp',
          health: ProjectHealth.offTrack,
          owner: '',
          progress: 36,
          accepted: 0,
        ),
        detailKey: 'search.portal_subtitle',
      ),
      'off track 36%',
    ),
    (
      (
        project: const ProjectItem(
          id: 'mobile',
          name: 'Mobile App Launch',
          health: ProjectHealth.atRisk,
          owner: '',
          progress: 25,
          accepted: 0,
        ),
        detailKey: 'search.mobile_subtitle',
      ),
      'at risk 25%',
    ),
  ];

  @override
  List<String> get suggestedRecent => const ['webhook', 'Tunde', 'TK-190'];

  @override
  Future<List<SearchProject>> featured() async => [
    for (final (p, _) in _projects) p,
  ];

  @override
  Future<SearchResults> search(String query) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return const SearchResults();
    bool hit(String text) => text.toLowerCase().contains(term);
    final tasks = (await _tasks.list(TaskScope.all)).tasks;
    return SearchResults(
      tasks: [
        for (final t in tasks)
          if (_taskCopy[t.reference] case (
            final key,
            final words,
          ) when hit('${t.title} ${t.reference} $words'))
            (task: t, detailKey: key),
      ],
      projects: [
        for (final (p, words) in _projects)
          if (hit('${p.project.name} $words')) p,
      ],
      people: [
        for (final (p, words) in _people)
          if (hit('${p.name} $words')) p,
      ],
    );
  }
}
