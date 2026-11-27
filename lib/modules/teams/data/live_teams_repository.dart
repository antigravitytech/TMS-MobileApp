part of 'teams_repository.dart';

typedef _Json = Map<String, dynamic>;

/// Teams over the `/team` API.
class LiveTeamsRepository implements TeamsRepository {
  const LiveTeamsRepository(this._network, {this.workspace});

  final NetworkCallsRepository _network;
  final AccountWorkspace? workspace;

  @override
  Future<TeamDirectory> teams() async {
    final ws = workspace;
    if (ws == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    final page = accountPayload(
      await _network.get<_Json>(
        '/team/list-teams/${Uri.encodeComponent(ws.id)}/',
        queryParameters: {'page_size': 100},
      ),
    );
    return _parse(
      () => TeamDirectory(ws.name, [
        for (final t in (page['items'] as List).cast<_Json>())
          TeamItem(
            id: t['id'] as String,
            name: t['name'] as String,
            lead: _name(t['lead']),
            color: t['color'] as String? ?? '#6658c0',
            memberCount: t['member_count'] as int? ?? 0,
            progress: ((t['stats'] as _Json?)?['weekly_progress'] as num? ?? 0)
                .round(),
          ),
      ]),
    );
  }

  @override
  Future<List<TeamMember>> members(TeamItem team) async {
    final page = accountPayload(
      await _network.get<_Json>(
        '/team/list-members/${Uri.encodeComponent(team.id)}/',
        queryParameters: {'page_size': 100},
      ),
    );
    final members = _parse(
      () => [
        for (final m in (page['items'] as List).cast<_Json>())
          TeamMember(
            userId: (m['user'] as _Json)['id'] as String,
            name: _name(m['user']),
            lead: m['role'] == 'lead',
            open: m['in_progress_tasks'] as int? ?? 0,
          ),
      ],
    );
    // The lead first, as on the design.
    return [...members.where((m) => m.lead), ...members.where((m) => !m.lead)];
  }

  static String _name(Object? person) => person is _Json
      ? [
          person['first_name'],
          person['last_name'],
        ].whereType<String>().join(' ').trim()
      : '';

  static T _parse<T>(T Function() read) {
    try {
      return read();
    } on TypeError {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
  }
}
