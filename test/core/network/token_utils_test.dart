import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/network/token_utils.dart';
import 'package:sabi_pipu_tms/core/services/secure_storage_service.dart';

import 'network_fixtures.dart';

void main() {
  late MemorySecureStorage storage;
  late TokenUtils tokens;
  setUp(() {
    storage = MemorySecureStorage();
    tokens = TokenUtils.withStorage(storage);
  });

  test(
    'store waits for secure writes and queued reads see a complete session',
    () async {
      storage.writeGate = Completer<void>();
      var stored = false;
      var read = false;
      final save = tokens
          .storeTokens(
            accessToken: 'synthetic-access',
            refreshToken: 'synthetic-refresh',
          )
          .then((_) => stored = true);
      final load = tokens.getAccessToken().then((value) {
        read = true;
        return value;
      });
      await Future<void>.delayed(Duration.zero);
      expect(stored, isFalse);
      expect(read, isFalse);
      expect(storage.values, isEmpty);
      storage.writeGate!.complete();
      await save;
      expect(await load, 'synthetic-access');
      expect(await tokens.getRefreshToken(), 'synthetic-refresh');
      expect(storage.values[SecureKeys.tokenHash.name], isNotEmpty);
    },
  );

  test(
    'concurrent session replacement and sign-out cannot interleave',
    () async {
      final first = tokens.storeTokens(
        accessToken: 'synthetic-first',
        refreshToken: 'synthetic-refresh',
      );
      final second = tokens.storeTokens(accessToken: 'synthetic-second');
      final clear = tokens.clearTokens();
      await Future.wait([first, second, clear]);
      expect(await tokens.getAccessToken(), isNull);
      expect(await tokens.getRefreshToken(), isNull);
      expect(storage.values, isEmpty);
    },
  );

  test('new sessions remove an omitted or empty stale refresh token', () async {
    for (final refresh in [null, '']) {
      await tokens.storeTokens(
        accessToken: 'synthetic-first',
        refreshToken: 'synthetic-old-refresh',
      );
      await tokens.storeTokens(
        accessToken: 'synthetic-second',
        refreshToken: refresh,
      );
      expect(await tokens.getRefreshToken(), isNull);
      expect(await tokens.getAccessToken(), 'synthetic-second');
    }
  });

  test(
    'corrupt or missing integrity hashes invalidate all session tokens',
    () async {
      for (final hash in [null, 'fixture-wrong-hash']) {
        await tokens.storeTokens(
          accessToken: 'synthetic-access',
          refreshToken: 'synthetic-refresh',
        );
        if (hash == null) {
          storage.values.remove(SecureKeys.tokenHash.name);
        } else {
          storage.values[SecureKeys.tokenHash.name] = hash;
        }
        expect(await tokens.getAccessToken(), isNull);
        expect(storage.values, isEmpty);
      }
    },
  );

  test(
    'failed multi-key writes surface and clean up partial sessions',
    () async {
      storage.failingWriteKey = SecureKeys.tokenHash.name;
      await expectLater(
        tokens.storeTokens(
          accessToken: 'synthetic-access',
          refreshToken: 'synthetic-refresh',
        ),
        throwsA(isA<TokenStorageException>()),
      );
      expect(storage.values, isEmpty);
      storage.failingWriteKey = null;
      await tokens.storeTokens(accessToken: 'synthetic-recovered');
      expect(await tokens.getAccessToken(), 'synthetic-recovered');
    },
  );

  test(
    'temporary keychain read errors do not delete a valid session',
    () async {
      await tokens.storeTokens(accessToken: 'synthetic-access');
      final before = Map.of(storage.values);
      storage.failReads = true;
      await expectLater(
        tokens.getAccessToken(),
        throwsA(isA<TokenStorageException>()),
      );
      await expectLater(
        tokens.getRefreshToken(),
        throwsA(isA<TokenStorageException>()),
      );
      expect(storage.values, before);
      storage.failReads = false;
      expect(await tokens.getAccessToken(), 'synthetic-access');
    },
  );

  test(
    'sign-out failures surface and do not poison later operations',
    () async {
      await tokens.storeTokens(accessToken: 'synthetic-access');
      storage.failDeletes = true;
      await expectLater(
        tokens.clearTokens(),
        throwsA(isA<TokenStorageException>()),
      );
      storage.failDeletes = false;
      await tokens.clearTokens();
      expect(await tokens.getAccessToken(), isNull);
    },
  );

  test(
    'blank tokens and header injection are rejected without exposing values',
    () async {
      for (final token in ['', ' ', 'synthetic\r\ninjected']) {
        await expectLater(
          tokens.storeTokens(accessToken: token),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'safe diagnostic',
              isNot(contains('synthetic')),
            ),
          ),
        );
      }
      expect(storage.values, isEmpty);
      await tokens.storeTokens(accessToken: 'synthetic-valid');
      expect(await tokens.getAccessToken(), 'synthetic-valid');
    },
  );

  test('failed cleanup never permits use of an incomplete session', () async {
    storage.failingWriteKey = SecureKeys.refreshToken.name;
    storage.failCleanupAfterWrite = true;
    await expectLater(
      tokens.storeTokens(
        accessToken: 'synthetic-access',
        refreshToken: 'synthetic-refresh',
      ),
      throwsA(isA<TokenStorageException>()),
    );
    expect(storage.values[SecureKeys.tokenHash.name], isNull);
    await expectLater(
      tokens.getAccessToken(),
      throwsA(isA<TokenStorageException>()),
    );
    await expectLater(
      tokens.getRefreshToken(),
      throwsA(isA<TokenStorageException>()),
    );
    storage.failDeletes = false;
    storage.failingWriteKey = null;
    await tokens.storeTokens(accessToken: 'synthetic-recovered');
    expect(await tokens.getAccessToken(), 'synthetic-recovered');
  });

  test('failed sign-out blocks token use until cleanup succeeds', () async {
    await tokens.storeTokens(accessToken: 'synthetic-access');
    storage.failDeletes = true;
    await expectLater(
      tokens.clearTokens(),
      throwsA(isA<TokenStorageException>()),
    );
    await expectLater(
      tokens.getAccessToken(),
      throwsA(isA<TokenStorageException>()),
    );
    storage.failDeletes = false;
    await tokens.clearTokens();
    expect(await tokens.getAccessToken(), isNull);
  });

  test('unrelated secure storage keys survive clearing a session', () async {
    storage.values['unrelated-fixture-key'] = 'fixture-value';
    await tokens.storeTokens(accessToken: 'synthetic-access');
    await tokens.clearTokens();
    expect(storage.values, {'unrelated-fixture-key': 'fixture-value'});
  });
}
