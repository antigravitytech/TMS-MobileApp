part of 'search_repository.dart';

typedef _Json = Map<String, dynamic>;

/// Searches tasks, projects and people in parallel; the API has no single
/// search endpoint.
class LiveSearchRepository implements SearchRepository {
  const LiveSearchRepository(this._network, {this.workspace});

  final NetworkCallsRepository _network;
  final AccountWorkspace? workspace;

  /// Shorter queries aren't sent.
  static const minLength = 2;
  static const _pageSize = 5;

  String get _ws {
    final id = workspace?.id;
    if (id == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    return Uri.encodeComponent(id);
  }

  @override
  List<String> get suggestedRecent => const [];

  @override
  Future<List<SearchProject>> featured() async => const [];

  Future<List<_Json>> _rows(String path, String query) async {
    final body = accountPayload(
      await _network.get<Object>(
        path,
        queryParameters: {'search': query, 'page_size': _pageSize},
      ),
    );
    return _parse(
      () => switch (body) {
        final List list => list.cast<_Json>(),
        final Map map => (map['items'] as List).cast<_Json>(),
        _ => throw const FormatException(),
      },
    );
  }

  @override
  Future<SearchResults> search(String query) async {
    final term = query.trim();
    if (term.length < minLength) return const SearchResults();
    final ws = _ws;
    final (tasks, projects, people) = await (
      _rows('/task/list-tasks/$ws/', term),
      _rows('/project/list-projects/$ws/', term),
      _rows('/people/list-people/$ws/', term),
    ).wait;
    return _parse(
      () => SearchResults(
        tasks: [
          for (final t in tasks) (task: taskItemFromJson(t), detailKey: null),
        ],
        projects: [
          for (final p in projects)
            (project: projectItemFromJson(p), detailKey: null),
        ],
        people: [
          for (final p in people)
            // Pending invites have no account to message yet.
            if (p['status'] == 'active' && p['is_signup_request'] != true)
              SearchPerson(
                id: p['id'] as String,
                name: [
                  p['first_name'],
                  p['last_name'],
                ].whereType<String>().where((s) => s.isNotEmpty).join(' '),
                jobTitle: p['job_title'] as String? ?? '',
                team: (p['team'] as _Json?)?['name'] as String? ?? '',
              ),
        ],
      ),
    );
  }

  static T _parse<T>(T Function() read) {
    try {
      return read();
    } on TypeError {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    } on FormatException {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
  }
}
