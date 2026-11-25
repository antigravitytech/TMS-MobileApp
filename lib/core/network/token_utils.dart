import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sabi_pipu_tms/core/services/secure_storage_service.dart';

class TokenStorageException implements Exception {
  const TokenStorageException();

  @override
  String toString() => 'network.tokenStorage';
}

class TokenUtils {
  static final TokenUtils _instance = TokenUtils.withStorage(
    const FlutterSecureStorage(),
  );
  factory TokenUtils() => _instance;
  TokenUtils.withStorage(this._storage);

  final FlutterSecureStorage _storage;
  Future<void> _pending = Future<void>.value();
  bool _sessionInvalid = false;

  // Reads, writes and sign-out share one queue. No request can observe a token
  // halfway through a write, and failed operations do not poison the queue.
  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  String _hash(String token) => sha256.convert(utf8.encode(token)).toString();

  Future<void> storeTokens({
    required String accessToken,
    String? refreshToken,
  }) => _serialized(() async {
    if (accessToken.trim().isEmpty || accessToken.contains(RegExp(r'[\r\n]'))) {
      throw ArgumentError('Invalid access token');
    }
    try {
      _sessionInvalid = true;
      // The hash is the commit marker for a complete multi-key update. Remove
      // it first and write it last, after the refresh token has been updated.
      await _storage.delete(key: SecureKeys.tokenHash.name);
      await _storage.write(
        key: SecureKeys.accessToken.name,
        value: accessToken,
      );
      if (refreshToken == null || refreshToken.isEmpty) {
        // A new session must not inherit a previous user's refresh token.
        await _storage.delete(key: SecureKeys.refreshToken.name);
      } else {
        await _storage.write(
          key: SecureKeys.refreshToken.name,
          value: refreshToken,
        );
      }
      await _storage.write(
        key: SecureKeys.tokenHash.name,
        value: _hash(accessToken),
      );
      _sessionInvalid = false;
    } catch (_) {
      // A failed multi-key update must never leave a usable partial session.
      try {
        await _deleteTokens();
      } catch (_) {
        // Preserve the original storage failure without logging private data.
      }
      throw const TokenStorageException();
    }
  });

  Future<String?> getAccessToken() => _serialized(() async {
    try {
      if (_sessionInvalid) throw const TokenStorageException();
      final token = await _storage.read(key: SecureKeys.accessToken.name);
      if (token == null) return null;
      final hash = await _storage.read(key: SecureKeys.tokenHash.name);
      if (token.trim().isEmpty ||
          token.contains(RegExp(r'[\r\n]')) ||
          hash != _hash(token)) {
        _sessionInvalid = true;
        await _deleteTokens();
        _sessionInvalid = false;
        return null;
      }
      return token;
    } catch (_) {
      // A temporary keychain failure should surface, not destroy the session.
      throw const TokenStorageException();
    }
  });

  Future<String?> getRefreshToken() => _serialized(() async {
    try {
      if (_sessionInvalid) throw const TokenStorageException();
      return await _storage.read(key: SecureKeys.refreshToken.name);
    } catch (_) {
      throw const TokenStorageException();
    }
  });

  Future<void> clearTokens() => _serialized(() async {
    _sessionInvalid = true;
    try {
      await _deleteTokens();
      _sessionInvalid = false;
    } catch (_) {
      throw const TokenStorageException();
    }
  });

  Future<void> _deleteTokens() => Future.wait([
    _storage.delete(key: SecureKeys.accessToken.name),
    _storage.delete(key: SecureKeys.refreshToken.name),
    _storage.delete(key: SecureKeys.tokenHash.name),
  ]);
}
