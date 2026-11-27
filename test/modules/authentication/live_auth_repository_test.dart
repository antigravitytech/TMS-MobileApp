import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/core/network/token_utils.dart';
import 'package:sabi_pipu_tms/modules/authentication/data/auth_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';

typedef _Json = Map<String, dynamic>;

const _user = {
  'id': 'fixture-user',
  'email': 'member@example.test',
  'is_verified': true,
};

void main() {
  late TokenUtils tokens;
  late _Network network;
  late LiveAuthRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    tokens = TokenUtils.withStorage(const FlutterSecureStorage());
    network = _Network();
    repository = LiveAuthRepository(network, tokens);
  });

  Future<Account> signIn() => repository.signIn(
    'member@example.test',
    'fixture-password',
    false,
    Duration.zero,
  );

  test(
    'a login response arriving after sign-out cannot restore the session',
    () async {
      final login = signIn();
      final assertion = expectLater(
        login,
        _failsWith(NetworkFailureType.cancelled),
      );
      await repository.signOut();
      network.login.complete(_session('late-fixture-token'));
      await assertion;
      expect(await tokens.getAccessToken(), isNull);
    },
  );

  test('a stale unauthorized restore cannot clear a newer session', () async {
    await tokens.storeTokens(accessToken: 'old-fixture-token');
    final restore = repository.restore();
    final assertion = expectLater(
      restore,
      _failsWith(NetworkFailureType.cancelled),
    );
    await network.restoreStarted.future;
    final login = signIn();
    network.login.complete(_session('new-fixture-token'));
    await login;

    network.restore.complete(
      ApiResponse<_Json>.error(
        'unauthorized',
        statusCode: 401,
        failureType: NetworkFailureType.unauthorized,
      ),
    );

    await assertion;
    expect(await tokens.getAccessToken(), 'new-fixture-token');
  });

  test('a malformed login response leaves the existing token intact', () async {
    await tokens.storeTokens(accessToken: 'old-fixture-token');
    network.login.complete(
      ApiResponse<_Json>.success({
        'user': ['unexpected'],
        'access_token': 'new-fixture-token',
        'token_type': 'bearer',
      }),
    );

    await expectLater(signIn(), _failsWith(NetworkFailureType.invalidResponse));
    expect(await tokens.getAccessToken(), 'old-fixture-token');
  });

  test(
    'a malformed restore response is typed and preserves the stored token',
    () async {
      await tokens.storeTokens(accessToken: 'old-fixture-token');
      network.restore.complete(
        ApiResponse<_Json>.success({..._user, 'is_verified': 'true'}),
      );

      await expectLater(
        repository.restore(),
        _failsWith(NetworkFailureType.invalidResponse),
      );
      expect(await tokens.getAccessToken(), 'old-fixture-token');
    },
  );

  test(
    'invalid verification and unsupported OAuth inputs fail before sending requests',
    () async {
      await expectLater(
        repository.verifyEmail(email: 'member@example.test'),
        _failsWith(NetworkFailureType.validation),
      );
      await expectLater(
        repository.verifyEmail(
          email: 'member@example.test',
          code: '123456',
          token: 'link',
        ),
        _failsWith(NetworkFailureType.validation),
      );
      await expectLater(
        repository.startOAuth('unsupported'),
        _failsWith(NetworkFailureType.validation),
      );
      await expectLater(
        repository.finishOAuth('unsupported', 'code', 'state', Uri()),
        _failsWith(NetworkFailureType.validation),
      );
    },
  );

  test(
    'workspace pagination stays within the first page count and keeps Specials',
    () async {
      network.pages.addAll([
        {
          'total_pages': 2,
          'items': [_workspace('one', 'family')],
        },
        {
          'total_pages': 3,
          'items': [
            _workspace('two', 'business'),
            {..._workspace('three', 'specials'), 'subtype': 'church'},
          ],
        },
      ]);

      final workspaces = await repository.workspaces();

      expect(workspaces.map((workspace) => workspace.id), [
        'one',
        'two',
        'three',
      ]);
      expect(workspaces.last.subtype, 'church');
      expect(network.requestedPages, [1, 2]);
    },
  );
}

Matcher _failsWith(NetworkFailureType type) =>
    throwsA(isA<AccountFailure>().having((error) => error.type, 'type', type));

ApiResponse<_Json> _session(String token) => ApiResponse.success({
  'user': _user,
  'access_token': token,
  'token_type': 'bearer',
});

_Json _workspace(String id, String kind) => {
  'id': id,
  'name': 'Fixture workspace',
  'kind': kind,
  'approval_status': 'approved',
};

class _Network implements NetworkCallsRepository {
  final login = Completer<ApiResponse<_Json>>();
  final restore = Completer<ApiResponse<_Json>>();
  final restoreStarted = Completer<void>();
  final pages = <_Json>[];
  final requestedPages = <int>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final path = invocation.positionalArguments.single as String;
    switch (path) {
      case '/auth/login/':
        return login.future;
      case '/auth/check-auth/':
        restoreStarted.complete();
        return restore.future;
      case '/workspace/list-workspaces/':
        final params = invocation.namedArguments[#queryParameters] as Map;
        final page = params['page'] as int;
        requestedPages.add(page);
        return Future.value(ApiResponse<_Json>.success(pages[page - 1]));
      default:
        throw StateError('Unexpected auth request');
    }
  }
}
