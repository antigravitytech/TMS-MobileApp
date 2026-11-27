import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/journal/application/journal_controller.dart';
import 'package:sabi_pipu_tms/modules/journal/data/journal_repository.dart';

void main() {
  test('mock journal writes and pins without the network', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(c.read(journalRepositoryProvider), isA<MockJournalRepository>());
    final sub = c.listen(journalProvider, (_, _) {});
    addTearDown(sub.close);
    final notes = await c.read(journalProvider.future);
    expect(notes.first.pinned, isTrue);
    await c.read(journalProvider.notifier).create((
      title: 'Idea',
      body: 'Write it down',
      color: 'amber',
      remindAt: null,
    ));
    // Pinned notes stay first.
    expect(c.read(journalProvider).requireValue[1].title, 'Idea');
    final idea = c.read(journalProvider).requireValue[1];
    await c.read(journalProvider.notifier).togglePin(idea);
    expect(c.read(journalProvider).requireValue.first.title, 'Idea');
  });

  group('live journal', () {
    late _Transport transport;
    late ProviderContainer c;

    setUp(() {
      transport = _Transport();
      c = ProviderContainer.test(
        overrides: [
          environmentProvider.overrideWithValue(
            const AppEnvironment(source: DataSource.live),
          ),
          networkCallsRepositoryProvider.overrideWithValue(transport),
          activeLiveWorkspaceProvider.overrideWithValue(
            AccountWorkspace.fromJson({
              'id': 'ws',
              'name': 'Acme',
              'kind': 'business',
              'approval_status': 'approved',
            }),
          ),
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

    test('lists active notes and maps colours and reminders', () async {
      final notes = await c.read(journalRepositoryProvider).notes();
      expect(transport.query, {'state': 'active', 'page_size': 100});
      expect(notes.map((n) => (n.title, n.color, n.remindAt != null)), [
        ('Call the supplier', 'rose', true),
        ('Old', 'slate', false),
      ]);
    });

    test('create and pin replace with the server copy', () async {
      final sub = c.listen(journalProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(journalProvider.future);
      final at = DateTime.utc(2030, 1, 2, 9);
      await c.read(journalProvider.notifier).create((
        title: 'New',
        body: '',
        color: 'sky',
        remindAt: at,
      ));
      expect(transport.write?.$1, '/note/create-note/ws/');
      expect(transport.write?.$2, {
        'title': 'New',
        'body': '',
        'color': 'sky',
        'remind_at': '2030-01-02T09:00:00.000Z',
      });
      final old = c
          .read(journalProvider)
          .requireValue
          .firstWhere((n) => n.title == 'Old');
      await c.read(journalProvider.notifier).togglePin(old);
      expect(transport.write?.$1, '/note/pin-note/n2/');
      expect(transport.write?.$2, {'pinned': true});
      expect(c.read(journalProvider).requireValue.first.title, 'Old');
    });
  });
}

Map<String, dynamic> _note(
  String id,
  String title,
  String color, {
  bool pinned = false,
  String? remindAt,
  String reminder = 'none',
}) => {
  'id': id,
  'title': title,
  'body': '',
  'color': color,
  'pinned': pinned,
  'remind_at': remindAt,
  'reminder_state': reminder,
  'updated_at': '2026-11-27T09:00:00Z',
};

class _Transport implements NetworkCallsRepository {
  Map<String, dynamic>? query;
  (String, Object?)? write;

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
    expect(path, '/note/list-notes/ws/');
    query = queryParameters;
    return ApiResponse<T>.success(
      <String, dynamic>{
            'items': [
              _note(
                'n1',
                'Call the supplier',
                'rose',
                remindAt: '2030-01-01T09:00:00Z',
                reminder: 'scheduled',
              ),
              // Teal shows as slate; a done reminder is hidden.
              _note(
                'n2',
                'Old',
                'teal',
                remindAt: '2026-01-01T09:00:00Z',
                reminder: 'done',
              ),
            ],
          }
          as T,
    );
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
    write = (path, data);
    final body = path.contains('pin-note')
        ? _note('n2', 'Old', 'teal', pinned: true)
        : _note('n3', 'New', 'sky', remindAt: '2030-01-02T09:00:00Z');
    return ApiResponse<T>.success(body as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
