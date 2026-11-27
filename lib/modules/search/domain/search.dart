import '../../projects/domain/project.dart';
import '../../tasks/domain/task.dart';

/// Someone in the workspace who matched a search.
class SearchPerson {
  const SearchPerson({
    required this.id,
    required this.name,
    this.jobTitle = '',
    this.team = '',
    this.detailKey,
  });
  final String id, name, jobTitle, team;

  /// Reference copy shown instead of job title and team, in mock mode.
  final String? detailKey;
}

/// A task or project match with optional reference copy for its detail line.
typedef SearchTask = ({TaskItem task, String? detailKey});
typedef SearchProject = ({ProjectItem project, String? detailKey});

class SearchResults {
  const SearchResults({
    this.tasks = const [],
    this.projects = const [],
    this.people = const [],
  });
  final List<SearchTask> tasks;
  final List<SearchProject> projects;
  final List<SearchPerson> people;

  bool get isEmpty => tasks.isEmpty && projects.isEmpty && people.isEmpty;
}
