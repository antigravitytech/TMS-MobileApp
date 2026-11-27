part of 'birthdays_repository.dart';

class LiveBirthdaysRepository implements BirthdaysRepository {
  const LiveBirthdaysRepository(this._network);

  final NetworkCallsRepository _network;

  @override
  Future<BirthdayCalendar> load(String workspaceId) async {
    final id = Uri.encodeComponent(workspaceId);
    final [calendar, feed] = await Future.wait([
      _network.get<Map<String, dynamic>>('/birthday/get-calendar/$id/'),
      _network.get<Map<String, dynamic>>('/birthday/get-feed/$id/'),
    ]);
    final days = accountPayload(calendar);
    final mine = accountPayload(feed);
    return _parse(
      () => BirthdayCalendar(
        members: (days['members'] as List)
            .cast<Map<String, dynamic>>()
            .map(BirthdayPerson.fromJson)
            .toList(growable: false),
        entries: (days['entries'] as List)
            .cast<Map<String, dynamic>>()
            .map(BirthdayEntry.fromJson)
            .toList(growable: false),
        mineIsToday: mine['mine_is_today'] as bool,
        wishesReceived: mine['wishes_received'] as int,
      ),
    );
  }

  @override
  Future<void> sendWish(
    BirthdayPerson person, {
    required String message,
    required String theme,
    required String sticker,
  }) async {
    accountPayload(
      await _network.post<Map<String, dynamic>>(
        '/birthday/send-wish/${Uri.encodeComponent(person.id)}/',
        data: {'message': message.trim(), 'theme': theme, 'sticker': sticker},
      ),
    );
  }

  @override
  Future<BirthdayEntry> celebrate(BirthdayEntry entry) async {
    final body = accountPayload(
      await _network.post<Map<String, dynamic>>(
        '/birthday/celebrate-entry/${Uri.encodeComponent(entry.id)}/',
      ),
    );
    return _parse(() => BirthdayEntry.fromJson(body));
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
