import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/chat/application/chat_thread.dart';
import 'package:sabi_pipu_tms/modules/chat/data/chat_directory.dart';
import 'package:sabi_pipu_tms/modules/chat/data/chat_repository.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mock chat reads the fixtures without the network', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(c.read(chatRepositoryProvider), isA<MockChatRepository>());
    final inbox = await c.read(chatDirectoryProvider.future);
    expect(inbox.recent, isNotEmpty);
    expect(inbox.request?.row.name, 'Leo Martins');
    final found = await c
        .read(chatRepositoryProvider)
        .searchPeople(inbox, 'amaka');
    expect(found.single.name, 'Amaka Eze');
  });

  group('live chat', () {
    late _ChatTransport transport;
    late ProviderContainer c;

    setUp(() {
      transport = _ChatTransport();
      final workspace = AccountWorkspace.fromJson({
        'id': 'ws',
        'name': 'Fixture Company',
        'kind': 'business',
        'approval_status': 'approved',
      });
      c = ProviderContainer.test(
        overrides: [
          environmentProvider.overrideWithValue(
            const AppEnvironment(source: DataSource.live),
          ),
          networkCallsRepositoryProvider.overrideWithValue(transport),
          activeLiveWorkspaceProvider.overrideWithValue(workspace),
        ],
      );
      c
          .read(accountSessionProvider.notifier)
          .update(
            const Account(
              id: 'me',
              email: 'me@example.test',
              firstName: 'Ari',
              lastName: 'Lee',
              verified: true,
            ),
          );
    });

    test('the inbox splits pinned, task, chat and channel rows', () async {
      final inbox = await c.read(chatRepositoryProvider).inbox();
      expect(inbox.name, 'Fixture Company');
      expect(inbox.pinned?.name, 'Tech Team › General');
      expect(inbox.tasks.single.name, 'TK-1 · Fix login');
      expect(inbox.recent.map((r) => (r.name, r.badge)), [
        ('Tunde Bakare', '2'),
        ('Launch room', '@'),
      ]);
      expect(inbox.groups.single.name, 'Design › Reviews');
      expect(inbox.request?.id, 'req-1');
      expect(inbox.recent.first.preview, 'Morning');
    });

    test('new chats, requests and people search use the API', () async {
      final repo = c.read(chatRepositoryProvider);
      final inbox = await repo.inbox();
      final people = await repo.searchPeople(inbox, 'zara');
      expect(transport.queries.last, {'q': 'zara', 'page_size': 20});
      expect(people.single.id, 'zara');
      expect(await repo.searchPeople(inbox, 'z'), isEmpty);

      final dm = await repo.start(inbox, people, group: false);
      expect(dm.id, 'dm-zara');
      expect(transport.writes.last.$1, '/chat/start-dm/ws/');
      expect(transport.writes.last.$2, {'user_id': 'zara'});
      await repo.start(inbox, [...people, ...people], group: true, title: ' ');
      expect(transport.writes.last.$1, '/chat/create-conversation/ws/');
      expect(transport.writes.last.$2, {
        'kind': 'group',
        'member_ids': ['zara', 'zara'],
      });

      await repo.respond(inbox.request!, accept: true);
      expect(transport.writes.last.$1, '/chat/accept-chat-request/req-1/');
    });

    test('a thread loads oldest first, marks read, sends and hearts', () async {
      final sub = c.listen(chatThreadProvider('c1'), (_, _) {});
      addTearDown(sub.close);
      final messages = await c.read(chatThreadProvider('c1').future);
      expect(messages.map((m) => (m.body, m.mine)), [
        ('Morning', false),
        ('Hi Tunde', true),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(transport.writes.first.$1, '/chat/mark-read/c1/');
      expect(transport.writes.first.$2, {'message_id': 'm2'});

      final thread = c.read(chatThreadProvider('c1').notifier);
      await thread.send('  Ready?  ');
      final (path, form) = transport.writes.firstWhere(
        (w) => w.$1.startsWith('/chat/send-message/'),
      );
      expect(path, '/chat/send-message/c1/');
      expect(
        {for (final f in (form as FormData).fields) f.key: f.value},
        {'body': 'Ready?'},
      );
      expect(c.read(chatThreadProvider('c1')).value!.last.body, 'Ready?');

      await thread.toggleHeart(messages.first);
      expect(transport.writes.last.$2, {'emoji': '❤️'});
      expect(c.read(chatThreadProvider('c1')).value!.first.hearted, isTrue);
    });
  });
}

Map<String, dynamic> _person(String id, String first, String last) => {
  'id': id,
  'email': '$id@example.test',
  'first_name': first,
  'last_name': last,
  'photo': null,
  'job_title': 'Engineer',
};

Map<String, dynamic> _conversation(
  String id,
  String kind, {
  String? title,
  Map<String, dynamic>? peer,
  Map<String, dynamic>? group,
  Map<String, dynamic>? task,
  bool pinned = false,
  int unread = 0,
  int mentions = 0,
}) => {
  'id': id,
  'kind': kind,
  'title': title,
  'peer': peer,
  'group': group,
  'task': task,
  'member_preview': <Object>[],
  'is_pinned': pinned,
  'unread_count': unread,
  'mention_count': mentions,
  'last_message': {'preview': 'Morning', 'created_at': '2026-11-27T10:00:00Z'},
  'updated_at': '2026-11-27T10:00:00Z',
};

Map<String, dynamic> _message(
  String id,
  String body,
  String sender, {
  bool hearted = false,
}) => {
  'id': id,
  'type': 'text',
  'body': body,
  'sender': _person(sender, sender == 'me' ? 'Ari' : 'Tunde', 'Lee'),
  'reactions': [
    if (hearted) {'emoji': '❤️', 'count': 1, 'reacted_by_me': true},
  ],
  'created_at': '2026-11-27T10:0${id.substring(1)}:00Z',
};

class _ChatTransport implements NetworkCallsRepository {
  final writes = <(String, Object?)>[];
  final queries = <Map<String, dynamic>?>[];

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
    queries.add(queryParameters);
    final body = switch (path) {
      '/chat/list-conversations/ws/' => {
        'items': [
          _conversation(
            'p1',
            'channel',
            title: 'General',
            group: {'name': 'Tech Team', 'glyph': 'TT', 'color': '#66c0c0'},
            pinned: true,
          ),
          _conversation(
            't1',
            'task',
            title: 'Fix login',
            task: {'reference': 'TK-1'},
          ),
          _conversation(
            'c1',
            'dm',
            peer: _person('tunde', 'Tunde', 'Bakare'),
            unread: 2,
          ),
          _conversation('g1', 'group', title: 'Launch room', mentions: 1),
          _conversation(
            'ch2',
            'channel',
            title: 'Reviews',
            group: {'name': 'Design', 'glyph': 'DS', 'color': '#9184d9'},
          ),
        ],
      },
      '/chat/list-chat-requests/' => {
        'items': [
          {
            'conversation': {'id': 'req-1'},
            'requester': _person('leo', 'Leo', 'Martins'),
          },
        ],
      },
      '/chat/search-people/ws/' => {
        'items': [_person('zara', 'Zara', 'Khan')],
      },
      '/chat/list-messages/c1/' => {
        // Newest first, as the API returns with order=desc.
        'items': [
          _message('m2', 'Hi Tunde', 'me'),
          _message('m1', 'Morning', 'tunde'),
        ],
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
    final Object body;
    if (path.startsWith('/chat/send-message/')) {
      body = {
        'message': _message('m3', 'Ready?', 'me'),
        'channel_message': null,
      };
    } else if (path.startsWith('/chat/toggle-reaction/')) {
      body = _message('m1', 'Morning', 'tunde', hearted: true);
    } else if (path == '/chat/start-dm/ws/') {
      body = _conversation(
        'dm-zara',
        'dm',
        peer: _person('zara', 'Zara', 'Khan'),
      );
    } else if (path == '/chat/create-conversation/ws/') {
      body = _conversation('g2', 'group', title: 'Zara, Zara');
    } else {
      body = {'id': 'ok'};
    }
    return ApiResponse<T>.success(body as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
