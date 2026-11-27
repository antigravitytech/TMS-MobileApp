import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/birthdays/application/birthdays_controller.dart';
import 'package:sabi_pipu_tms/modules/birthdays/data/birthdays_repository.dart';

void main() {
  test('mock birthdays load and update without the network', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(c.read(birthdaysRepositoryProvider), isA<MockBirthdaysRepository>());
    final sub = c.listen(birthdaysProvider, (_, _) {});
    addTearDown(sub.close);
    final calendar = await c.read(birthdaysProvider.future);
    expect(calendar.mineIsToday, isTrue);
    final tunde = calendar.members.firstWhere((p) => p.isToday);
    expect(tunde.name, 'Tunde Bakare');
    final bisi = calendar.entries.firstWhere((e) => e.isToday);

    final controller = c.read(birthdaysProvider.notifier);
    await controller.sendWish(tunde, message: 'Have a great day', style: 1);
    await controller.celebrate(bisi);
    final after = c.read(birthdaysProvider).requireValue;
    expect(after.members.firstWhere((p) => p.id == tunde.id).iWished, isTrue);
    expect(after.entries.firstWhere((e) => e.id == bisi.id).celebrated, isTrue);
  });

  group('live birthdays', () {
    late _BirthdayTransport transport;
    late ProviderContainer c;

    setUp(() {
      transport = _BirthdayTransport();
      c = ProviderContainer.test(
        overrides: [
          environmentProvider.overrideWithValue(
            const AppEnvironment(source: DataSource.live),
          ),
          networkCallsRepositoryProvider.overrideWithValue(transport),
          birthdayWorkspaceProvider.overrideWithValue('fixture-workspace'),
        ],
      );
      c
          .read(accountSessionProvider.notifier)
          .update(
            const Account(
              id: 'fixture-me',
              email: 'member@example.test',
              firstName: 'Ari',
              lastName: 'Lee',
              verified: true,
            ),
          );
    });

    test('reads the calendar and feed, and leaves me out', () async {
      final sub = c.listen(birthdaysProvider, (_, _) {});
      addTearDown(sub.close);
      final calendar = await c.read(birthdaysProvider.future);
      expect(transport.reads, {
        '/birthday/get-calendar/fixture-workspace/',
        '/birthday/get-feed/fixture-workspace/',
      });
      expect(calendar.members.map((p) => p.name), ['Chioma Okafor']);
      expect(calendar.entries.single.name, 'Mama Bisi');
      expect((calendar.mineIsToday, calendar.wishesReceived), (true, 2));
    });

    test('sends a card and marks an entry as wished', () async {
      final sub = c.listen(birthdaysProvider, (_, _) {});
      addTearDown(sub.close);
      final calendar = await c.read(birthdaysProvider.future);
      final controller = c.read(birthdaysProvider.notifier);

      await controller.sendWish(
        calendar.members.single,
        message: '  Happy birthday!  ',
        style: 1,
      );
      expect(transport.writes.first.$1, '/birthday/send-wish/fixture-chioma/');
      expect(transport.writes.first.$2, {
        'message': 'Happy birthday!',
        'theme': 'cake',
        'sticker': 'cake',
      });
      await controller.celebrate(calendar.entries.single);
      expect(transport.writes.last.$1, '/birthday/celebrate-entry/entry-1/');

      final after = c.read(birthdaysProvider).requireValue;
      expect(after.members.single.iWished, isTrue);
      expect(after.members.single.wishCount, 5);
      expect(after.entries.single.celebrated, isTrue);
    });

    test('a broken response is an error, never mock data', () async {
      transport.broken = true;
      final sub = c.listen(birthdaysProvider, (_, _) {});
      addTearDown(sub.close);
      await expectLater(
        c.read(birthdaysProvider.future),
        throwsA(isA<AccountFailure>()),
      );
    });
  });
}

Map<String, dynamic> _person(String id, String first, int away) => {
  'user': {
    'id': id,
    'email': '$id@example.test',
    'first_name': first,
    'last_name': first == 'Ari' ? 'Lee' : 'Okafor',
    'photo': null,
  },
  'job_title': 'Finance Manager',
  'day': '11-27',
  'is_today': away == 0,
  'days_away': away,
  'i_wished': false,
  'wish_count': 4,
  'conversation_id': null,
};

Map<String, dynamic> _entry({bool celebrated = false}) => {
  'id': 'entry-1',
  'name': 'Mama Bisi',
  'day': '11-27',
  'year': 1962,
  'relation': 'family',
  'note': 'Loves ofada rice',
  'remind_days': 3,
  'is_mine': true,
  'is_today': true,
  'days_away': 0,
  'turning': 64,
  'celebrated': celebrated,
};

class _BirthdayTransport implements NetworkCallsRepository {
  final reads = <String>{};
  final writes = <(String, Object?)>[];
  var broken = false;

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    void Function(int, int)? onReceiveProgress,
  }) async {
    expect(withToken, isTrue);
    reads.add(path);
    final body = switch (path) {
      '/birthday/get-calendar/fixture-workspace/' => {
        'members': broken
            ? 'oops'
            : [
                _person('fixture-me', 'Ari', 0),
                _person('fixture-chioma', 'Chioma', 0),
              ],
        'entries': [_entry()],
        'mine_set': true,
      },
      '/birthday/get-feed/fixture-workspace/' => {
        'today': <Object>[],
        'upcoming': <Object>[],
        'mine_is_today': true,
        'wishes_received': 2,
      },
      _ => fail('Unexpected read $path'),
    };
    return ApiResponse<T>.success(body as T);
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    ResponseType? responseType,
  }) async {
    expect(withToken, isTrue);
    writes.add((path, data));
    final body = path.startsWith('/birthday/celebrate-entry/')
        ? _entry(celebrated: true)
        : {'conversation_id': 'dm-1', 'message_id': 'm-1'};
    return ApiResponse<T>.success(body as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
