part of 'projects_repository.dart';

typedef _Json = Map<String, dynamic>;

/// Projects over the `/project` API. The list carries every figure the
/// cards need, so no project is fetched one by one.
class LiveProjectsRepository implements ProjectsRepository {
  const LiveProjectsRepository(this._network, {this.workspace});

  final NetworkCallsRepository _network;
  final AccountWorkspace? workspace;

  String get _ws {
    final id = workspace?.id;
    if (id == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    return Uri.encodeComponent(id);
  }

  @override
  Future<List<ProjectItem>> list() async {
    final page = accountPayload(
      await _network.get<_Json>(
        '/project/list-projects/$_ws/',
        queryParameters: {'page_size': 100},
      ),
    );
    return _parse(
      () => [for (final p in (page['items'] as List).cast<_Json>()) _item(p)],
    );
  }

  @override
  Future<ProjectItem> create(String name) async {
    final body = accountPayload(
      await _network.post<_Json>(
        '/project/create-project/$_ws/',
        data: {'name': name.trim()},
      ),
    );
    return _parse(() => _item(body));
  }

  static ProjectItem _item(_Json p) {
    final owner = p['owner'] as _Json?;
    final stats = p['stats'] as _Json? ?? const {};
    final next = p['next_milestone'] as _Json?;
    final due = DateTime.tryParse(next?['due_date'] as String? ?? '');
    return ProjectItem(
      id: p['id'] as String,
      name: p['name'] as String,
      health: ProjectHealth.parse(p['health'] as String? ?? ''),
      owner: [
        owner?['first_name'],
        owner?['last_name'],
      ].whereType<String>().join(' ').trim(),
      progress: (stats['progress'] as num? ?? 0).round(),
      accepted: (stats['first_time_right_rate'] as num? ?? 0).round(),
      milestone: next == null || due == null
          ? null
          : ProjectMilestone(next['name'] as String, due),
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

/// A project from the API, for screens that already hold project JSON.
ProjectItem projectItemFromJson(Map<String, dynamic> p) =>
    LiveProjectsRepository._item(p);
