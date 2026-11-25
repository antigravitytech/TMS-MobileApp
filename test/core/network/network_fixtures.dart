import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sabi_pipu_tms/core/network/dio_repository.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/core/network/token_utils.dart';

ResponseBody jsonResponse(Object? data, int status) => ResponseBody.fromString(
  data == null ? '' : jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class FixtureAdapter implements HttpClientAdapter {
  FutureOr<ResponseBody> Function(RequestOptions) handler = (_) =>
      jsonResponse({'id': 'fixture'}, 200);
  final requests = <RequestOptions>[];
  final bodies = <List<int>>[];
  bool closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    bodies.add(
      await requestStream?.fold<List<int>>(
            [],
            (bytes, chunk) => bytes..addAll(chunk),
          ) ??
          [],
    );
    return handler(options);
  }

  @override
  void close({bool force = false}) => closed = true;
}

class MemorySecureStorage extends FlutterSecureStorage {
  final values = <String, String>{};
  Completer<void>? writeGate;
  String? failingWriteKey;
  bool failReads = false;
  bool failDeletes = false;
  bool failCleanupAfterWrite = false;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    await writeGate?.future;
    if (key == failingWriteKey) {
      if (failCleanupAfterWrite) failDeletes = true;
      throw StateError('Fixture storage write failure');
    }
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failReads) throw StateError('Fixture storage read failure');
    return values[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failDeletes) throw StateError('Fixture storage delete failure');
    values.remove(key);
  }
}

class NetworkFixture {
  final storage = MemorySecureStorage();
  final adapter = FixtureAdapter();
  late final tokens = TokenUtils.withStorage(storage);
  late final DioRepositoryImpl transport;
  late final NetworkCallsRepository calls;

  NetworkFixture({
    String baseUrl = 'https://api.example.test',
    int maxRetries = 0,
  }) {
    transport = DioRepositoryImpl(
      dio: Dio()..httpClientAdapter = adapter,
      tokenUtils: tokens,
      baseUrl: baseUrl,
      maxRetries: maxRetries,
      retryDelays: const [],
    );
    calls = NetworkCallsRepositoryImpl(transport);
  }
}
