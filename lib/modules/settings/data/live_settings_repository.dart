part of 'settings_repository.dart';

typedef _Json = Map<String, dynamic>;

/// Workspace notification preferences and my account's appearance.
class LiveSettingsRepository implements SettingsRepository {
  const LiveSettingsRepository(this._network, {this.workspace});

  final NetworkCallsRepository _network;
  final AccountWorkspace? workspace;

  /// The server events each workspace-backed switch stands for.
  static const serverNotices = {
    'reviews_mentions': ['submitted', 'returned', 'approved', 'mention'],
    'daily_report_reminder': ['reminder'],
  };

  String get _ws {
    final id = workspace?.id;
    if (id == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    return Uri.encodeComponent(id);
  }

  Future<Map<String, ({bool inApp, bool email})>> _events() async {
    final body = accountPayload(
      await _network.get<_Json>('/notification/get-preferences/$_ws/'),
    );
    return _parse(
      () => {
        for (final e in (body['events'] as List).cast<_Json>())
          e['event'] as String: (
            inApp: e['in_app'] as bool,
            email: e['email'] as bool,
          ),
      },
    );
  }

  @override
  Future<Map<String, bool>> notices() async {
    final events = await _events();
    return {
      for (final key in settingsNotices)
        key: switch (serverNotices[key]) {
          final group? => group.any((e) => events[e]?.inApp ?? false),
          null => DeviceNotices.read(key),
        },
    };
  }

  @override
  Future<void> setNotice(String key, bool on) async {
    final group = serverNotices[key];
    if (group == null) return DeviceNotices.write(key, on);
    final current = await _events();
    accountPayload(
      await _network.put<_Json>(
        '/notification/update-preferences/$_ws/',
        data: {
          'events': [
            for (final event in group)
              {
                'event': event,
                'in_app': on,
                'email': current[event]?.email ?? false,
              },
          ],
        },
      ),
    );
  }

  @override
  Future<Account> saveAppearance({String? theme, String? language}) async {
    final body = accountPayload(
      await _network.patch<_Json>(
        '/auth/update-profile-json/',
        data: {'theme': ?theme, 'language': ?language},
      ),
    );
    return _parse(() => Account.fromJson(body));
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
