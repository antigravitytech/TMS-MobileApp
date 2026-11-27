import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/visitors/application/visitors_controller.dart';
import 'package:sabi_pipu_tms/modules/visitors/data/visitors_repository.dart';
import 'package:sabi_pipu_tms/modules/visitors/domain/visit_pass.dart';

void main() {
  test('mock guests invite and answer without the network', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(c.read(visitorsRepositoryProvider), isA<MockVisitorsRepository>());
    final sub = c.listen(visitorsProvider, (_, _) {});
    addTearDown(sub.close);
    final passes = await c.read(visitorsProvider.future);
    final folake = passes.firstWhere((p) => p.needsAnswer);
    await c.read(visitorsProvider.notifier).answer(folake, GuestAnswer.hold);
    expect(
      c
          .read(visitorsProvider)
          .requireValue
          .firstWhere((p) => p.id == folake.id)
          .status,
      'on_hold',
    );
    final pass = await c.read(visitorsProvider.notifier).invite((
      name: 'Kemi Lawal',
      day: DateTime(2030, 1, 2),
      purpose: '11:00 · Vendor demo',
    ));
    expect(pass.status, 'expected');
    expect(c.read(visitorsProvider).requireValue.first.code, pass.code);
  });

  group('live guests', () {
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

    test('lists my passes; invites to the default desk once', () async {
      final repo = c.read(visitorsRepositoryProvider);
      final passes = await repo.passes();
      expect(transport.queries['/visitor/list-passes/ws/'], {'scope': 'mine'});
      expect(passes.single.needsAnswer, isTrue);

      for (var i = 0; i < 2; i++) {
        await repo.invite((
          name: 'Kemi Lawal',
          day: DateTime(2030, 1, 2),
          purpose: '11:00 · Vendor demo',
        ));
      }
      expect(
        transport.reads.where((p) => p == '/visitor/list-desks/ws/').length,
        1,
      );
      expect(transport.write?.$1, '/visitor/create-pass/ws/');
      expect(transport.write?.$2, {
        'guest_name': 'Kemi Lawal',
        'party_size': 1,
        'purpose': '11:00 · Vendor demo',
        'desk_id': 'fin',
        'valid_on': '2030-01-02',
        'arrived': false,
      });
    });

    test('holding asks for 10 minutes; a refusal keeps its reason', () async {
      final repo = c.read(visitorsRepositoryProvider);
      final pass = (await repo.passes()).single;
      final held = await repo.answer(pass, GuestAnswer.hold);
      expect(transport.write?.$1, '/visitor/pass-action/ws/p1/');
      expect(transport.write?.$2, {'action': 'hold', 'minutes': 10});
      expect(held.status, 'on_hold');

      transport.refuse = true;
      await expectLater(
        repo.answer(pass, GuestAnswer.admit),
        throwsA(
          isA<VisitorRefused>().having(
            (e) => e.detail,
            'detail',
            'Only Finance can answer this guest.',
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _pass(String status) => {
  'id': 'p1',
  'code': 'FIN-4K7Q',
  'guest_name': 'Folake Adebayo',
  'purpose': 'Interview',
  'valid_on': '2026-11-27',
  'status': status,
  'arrived_at': '2026-11-27T09:00:00Z',
  'can_answer': true,
};

class _Transport implements NetworkCallsRepository {
  final reads = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  (String, Object?)? write;
  var refuse = false;

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
    reads.add(path);
    queries[path] = queryParameters;
    final Object body = switch (path) {
      '/visitor/list-passes/ws/' => [_pass('waiting')],
      '/visitor/list-desks/ws/' => [
        {'id': 'gen', 'is_default': false},
        {'id': 'fin', 'is_default': true},
      ],
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
    write = (path, data);
    if (refuse) {
      return ApiResponse<T>.error(
        'refused',
        statusCode: 403,
        failureType: NetworkFailureType.forbidden,
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 403,
          data: {'detail': 'Only Finance can answer this guest.'},
        ),
      );
    }
    final body = path.contains('create-pass')
        ? _pass('expected')
        : _pass('on_hold');
    return ApiResponse<T>.success(body as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
