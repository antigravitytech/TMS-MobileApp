part of 'profile_repository.dart';

typedef _Json = Map<String, dynamic>;

/// My profile from `/people`, `/gamification` and the signed-in account.
class LiveProfileRepository implements ProfileRepository {
  const LiveProfileRepository(this._network, {this.workspace, this.account});

  final NetworkCallsRepository _network;
  final AccountWorkspace? workspace;
  final Account? account;

  String get _ws {
    final id = workspace?.id;
    if (id == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    return Uri.encodeComponent(id);
  }

  String get _me {
    final id = account?.id;
    if (id == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    return Uri.encodeComponent(id);
  }

  Future<T> _get<T>(String path) async =>
      accountPayload(await _network.get<T>(path));

  @override
  Future<ProfileSummary> summary() async {
    final ws = _ws, me = _me, mine = account!;
    final (person, context, game, statuses) = await (
      _get<_Json>('/people/get-person/$ws/$me/'),
      _get<_Json>('/people/my-context/$ws/'),
      _get<_Json>('/gamification/get-profile/$ws/$me/'),
      _get<List<dynamic>>('/people/list-statuses/$ws/'),
    ).wait;
    return _parse(() {
      final teams = (person['teams'] as List? ?? const []).cast<_Json>();
      final reports = (person['direct_reports'] as List? ?? const [])
          .cast<_Json>();
      return ProfileSummary(
        firstName: person['first_name'] as String? ?? mine.firstName,
        lastName: person['last_name'] as String? ?? mine.lastName,
        jobTitle: person['job_title'] as String? ?? mine.jobTitle,
        department: person['department'] as String? ?? '',
        presence: _myPresence(statuses, mine.id),
        role: context['role'] as String? ?? 'member',
        lineManager: context['is_line_manager'] as bool? ?? false,
        projectManager: context['is_project_manager'] as bool? ?? false,
        teamLead: context['is_team_lead'] as bool? ?? false,
        reportsTo: switch (person['reports_to']) {
          final _Json m => _person(m),
          _ => null,
        },
        directReports: [for (final r in reports) _person(r)],
        directReportCount:
            (person['direct_report_count'] as num?)?.toInt() ?? reports.length,
        team: teams.firstOrNull?['name'] as String?,
        points: (game['points'] as num).toInt(),
        level: (game['level'] as num).toInt(),
        streak: (game['streak'] as num).toInt(),
        earned: {
          for (final b in (game['badges'] as List? ?? const []).cast<_Json>())
            if (b['earned'] == true) ?badgeFromKey(b['key'] as String? ?? ''),
        },
      );
    });
  }

  @override
  Future<Presence> presence() async {
    final mine = account?.id;
    if (mine == null) {
      throw const AccountFailure(NetworkFailureType.unauthorized);
    }
    final rows = await _get<List<dynamic>>('/people/list-statuses/$_ws/');
    return _parse(() => _myPresence(rows, mine));
  }

  static Presence _myPresence(List<dynamic> rows, String me) =>
      Presence.fromApi(
        rows
                    .cast<_Json>()
                    .where((r) => r['user_id'] == me)
                    .firstOrNull?['presence']
                as String? ??
            'available',
      );

  @override
  Future<Presence> setPresence(Presence presence) async {
    final row = accountPayload(
      await _network.put<_Json>(
        '/people/set-status/$_ws/',
        data: {'presence': presence.api},
      ),
    );
    return _parse(() => Presence.fromApi(row['presence'] as String?));
  }

  static ProfilePerson _person(_Json m) => ProfilePerson(
    id: m['id'] as String? ?? '',
    name: [
      m['first_name'],
      m['last_name'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(' '),
  );

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
