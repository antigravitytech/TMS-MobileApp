import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/network/api_constants.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/dio_repository.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';

import 'network_fixtures.dart';

void main() {
  late NetworkFixture fixture;
  setUp(() => fixture = NetworkFixture());
  tearDown(() => fixture.transport.close());

  Future<ApiResponse<Object?>> call(String method) => switch (method) {
    'GET' => fixture.calls.get<Object?>('/fixture', withToken: false),
    'POST' => fixture.calls.post<Object?>('/fixture', withToken: false),
    'PUT' => fixture.calls.put<Object?>('/fixture', withToken: false),
    'DELETE' => fixture.calls.delete<Object?>('/fixture', withToken: false),
    'PATCH' => fixture.calls.patch<Object?>('/fixture', withToken: false),
    _ => throw ArgumentError(method),
  };

  for (final method in ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']) {
    test(
      '$method classifies all success and HTTP failure statuses consistently',
      () async {
        for (final status in [
          200,
          201,
          202,
          204,
          206,
          301,
          400,
          401,
          403,
          404,
          409,
          422,
          429,
          500,
          503,
        ]) {
          fixture.adapter.handler = (_) => jsonResponse(
            status == 204 ? null : {'detail': 'Fixture message'},
            status,
          );
          final result = await call(method);
          expect(
            result.isSuccess,
            status >= 200 && status < 300,
            reason: '$method $status',
          );
          expect(result.statusCode, status);
          expect(result.response?.statusCode, status);
          if (status == 204) expect(result.data, isNull);
          if (status >= 400) expect(result.error, 'Fixture message');
        }
      },
    );
  }

  test(
    'configuration is safe before dotenv load and can be corrected after failure',
    () async {
      final originalBaseUrl = ApiConstants.baseUrl;
      addTearDown(() => ApiConstants.baseUrl = originalBaseUrl);
      dotenv.clean();
      expect(ApiConstants.controlUrl, isEmpty);
      ApiConstants.baseUrl = '';
      final adapter = FixtureAdapter();
      final transport = DioRepositoryImpl(
        dio: Dio()..httpClientAdapter = adapter,
      );
      addTearDown(transport.close);
      final calls = NetworkCallsRepositoryImpl(transport);
      final unconfigured = await calls.get<Object?>(
        '/fixture',
        withToken: false,
      );
      expect(unconfigured.failureType, NetworkFailureType.configuration);
      expect(adapter.requests, isEmpty);
      ApiConstants.baseUrl = 'https://api.example.test';
      final configured = await calls.get<Object?>('/fixture', withToken: false);
      expect(configured.isSuccess, isTrue);
      expect(adapter.requests, hasLength(1));
    },
  );

  test('invalid base URL shapes fail before issuing a request', () async {
    for (final base in [
      '',
      'relative/path',
      'ftp://api.example.test',
      'https://user:password@api.example.test',
      'https://api.example.test?token=fixture',
      'https://api.example.test#fragment',
    ]) {
      final invalid = NetworkFixture(baseUrl: base);
      addTearDown(invalid.transport.close);
      final result = await invalid.calls.get<Object?>(
        '/fixture',
        withToken: false,
      );
      expect(
        result.failureType,
        NetworkFailureType.configuration,
        reason: base,
      );
      expect(invalid.adapter.requests, isEmpty);
    }
  });

  test(
    'concurrent initialization installs exactly one interceptor stack',
    () async {
      await Future.wait(
        List.generate(10, (_) => fixture.transport.initialize()),
      );
      expect(
        fixture.transport.dio.interceptors,
        hasLength(3),
      ); // Includes Dio's default.
      final results = await Future.wait(
        List.generate(
          8,
          (_) => fixture.calls.get<Object?>('/fixture', withToken: false),
        ),
      );
      expect(results.every((result) => result.isSuccess), isTrue);
      expect(fixture.adapter.requests, hasLength(8));
      expect(fixture.transport.dio.interceptors, hasLength(3));
    },
  );

  test(
    'query serialization matches repeated filters and retains false and zero',
    () async {
      await fixture.calls.get<Object?>(
        '/fixture',
        withToken: false,
        queryParameters: {
          'status': ['open', 'in progress'],
          'empty': '',
          'absent': null,
          'include_done': false,
          'offset': 0,
        },
      );
      final request = fixture.adapter.requests.single;
      expect(request.uri.queryParametersAll['status'], ['open', 'in progress']);
      expect(request.uri.queryParameters.containsKey('status[]'), isFalse);
      expect(request.uri.queryParameters.containsKey('empty'), isFalse);
      expect(request.uri.queryParameters.containsKey('absent'), isFalse);
      expect(request.uri.queryParameters['include_done'], 'false');
      expect(request.uri.queryParameters['offset'], '0');
    },
  );

  test(
    'protected requests use the latest token and public requests omit tokens',
    () async {
      await fixture.tokens.storeTokens(accessToken: 'synthetic-access-one');
      await fixture.calls.get<Object?>('/fixture');
      expect(
        fixture.adapter.requests.last.headers['Authorization'],
        'Bearer synthetic-access-one',
      );
      await fixture.tokens.storeTokens(accessToken: 'synthetic-access-two');
      await fixture.calls.get<Object?>('/fixture');
      expect(
        fixture.adapter.requests.last.headers['Authorization'],
        'Bearer synthetic-access-two',
      );
      fixture.transport.dio.options.headers['authorization'] =
          'synthetic-stale';
      fixture.transport.dio.options.headers['Authorization'] =
          'synthetic-stale';
      fixture.storage.failReads = true;
      final public = await fixture.calls.post<Object?>(
        '/auth/login/',
        withToken: false,
      );
      expect(public.isSuccess, isTrue);
      expect(
        fixture.adapter.requests.last.headers.keys.any(
          (key) => key.toLowerCase() == 'authorization',
        ),
        isFalse,
      );
    },
  );

  test(
    'a missing token returns unauthorized without sending a request',
    () async {
      final result = await fixture.calls.get<Object?>('/protected');
      expect(result.failureType, NetworkFailureType.unauthorized);
      expect(result.statusCode, 401);
      expect(fixture.adapter.requests, isEmpty);
    },
  );

  test(
    'keychain failures surface without making an anonymous protected request',
    () async {
      fixture.storage.failReads = true;
      final result = await fixture.calls.get<Object?>('/protected');
      expect(result.failureType, NetworkFailureType.tokenStorage);
      expect(fixture.adapter.requests, isEmpty);
    },
  );

  test(
    'authenticated absolute URLs cannot leak tokens to another origin',
    () async {
      await fixture.tokens.storeTokens(accessToken: 'synthetic-access');
      for (final path in [
        'https://other.example.test/fixture',
        'http://api.example.test/fixture',
        'https://api.example.test:444/fixture',
        'https://user@api.example.test/fixture',
      ]) {
        final result = await fixture.calls.get<Object?>(path);
        expect(result.failureType, NetworkFailureType.configuration);
      }
      expect(fixture.adapter.requests, isEmpty);
      final valid = await fixture.calls.get<Object?>(
        'https://api.example.test/fixture',
      );
      expect(valid.isSuccess, isTrue);
    },
  );

  test(
    '401 preserves the response and session without a fabricated refresh call',
    () async {
      await fixture.tokens.storeTokens(
        accessToken: 'synthetic-access',
        refreshToken: 'synthetic-refresh',
      );
      fixture.adapter.handler = (_) =>
          jsonResponse({'detail': 'Invalid token'}, 401);
      final results = await Future.wait(
        List.generate(
          4,
          (_) => fixture.calls.get<Object?>('/auth/check-auth/'),
        ),
      );
      expect(
        results.every(
          (result) =>
              result.statusCode == 401 &&
              result.failureType == NetworkFailureType.unauthorized,
        ),
        isTrue,
      );
      expect(fixture.adapter.requests, hasLength(4));
      expect(await fixture.tokens.getAccessToken(), 'synthetic-access');
      expect(await fixture.tokens.getRefreshToken(), 'synthetic-refresh');
    },
  );

  test(
    'non-map HTTP failure bodies complete without interceptor errors',
    () async {
      for (final body in [
        'Fixture plain failure',
        [1, 2],
        42,
        null,
      ]) {
        fixture.adapter.handler = (_) => jsonResponse(body, 401);
        final result = await fixture.calls
            .get<Object?>('/fixture', withToken: false)
            .timeout(const Duration(seconds: 2));
        expect(result.failureType, NetworkFailureType.unauthorized);
        expect(result.statusCode, 401);
      }
    },
  );

  test(
    'GET retries a transient failure once with fresh authorization',
    () async {
      fixture = NetworkFixture(maxRetries: 1);
      await fixture.tokens.storeTokens(accessToken: 'synthetic-access-one');
      fixture.adapter.handler = (_) async {
        if (fixture.adapter.requests.length == 1) {
          await fixture.tokens.storeTokens(accessToken: 'synthetic-access-two');
          return jsonResponse({'detail': 'Fixture unavailable'}, 503);
        }
        return jsonResponse({'id': 'fixture'}, 200);
      };
      final result = await fixture.calls.get<Map<String, dynamic>>('/fixture');
      expect(result.isSuccess, isTrue);
      expect(result.data, {'id': 'fixture'});
      expect(fixture.adapter.requests, hasLength(2));
      expect(
        fixture.adapter.requests.last.headers['Authorization'],
        'Bearer synthetic-access-two',
      );
    },
  );

  test('GET retry exhaustion preserves the last HTTP response', () async {
    fixture = NetworkFixture(maxRetries: 1);
    fixture.adapter.handler = (_) =>
        jsonResponse({'detail': 'Fixture outage'}, 503);
    final result = await call('GET');
    expect(result.statusCode, 503);
    expect(result.failureType, NetworkFailureType.server);
    expect(result.response?.data, {'detail': 'Fixture outage'});
    expect(fixture.adapter.requests, hasLength(2));
  });

  for (final status in [400, 401, 403, 422, 429, 501]) {
    test('GET does not retry status $status', () async {
      fixture = NetworkFixture(maxRetries: 2);
      fixture.adapter.handler = (_) => jsonResponse(null, status);
      final result = await call('GET');
      expect(result.isSuccess, isFalse);
      expect(fixture.adapter.requests, hasLength(1));
    });
  }

  for (final method in ['POST', 'PUT', 'DELETE', 'PATCH']) {
    test('$method never retries transient failures', () async {
      fixture = NetworkFixture(maxRetries: 2);
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.receiveTimeout,
        DioExceptionType.badResponse,
      ]) {
        fixture.adapter.requests.clear();
        fixture.adapter.handler = (options) {
          if (type == DioExceptionType.badResponse) {
            return jsonResponse(null, 503);
          }
          throw DioException(requestOptions: options, type: type);
        };
        expect((await call(method)).isSuccess, isFalse);
        expect(fixture.adapter.requests, hasLength(1));
      }
    });
  }

  test('GET bodies are not replayed after a transient failure', () async {
    fixture = NetworkFixture(maxRetries: 2);
    fixture.adapter.handler = (_) => jsonResponse(null, 503);
    await fixture.calls.get<Object?>(
      '/fixture',
      withToken: false,
      data: Stream.value([1, 2, 3]),
    );
    expect(fixture.adapter.requests, hasLength(1));
  });

  for (final type in [
    DioExceptionType.badCertificate,
    DioExceptionType.cancel,
    DioExceptionType.unknown,
  ]) {
    test('GET does not retry ${type.name}', () async {
      fixture = NetworkFixture(maxRetries: 2);
      fixture.adapter.handler = (options) =>
          throw DioException(requestOptions: options, type: type);
      final result = await call('GET');
      expect(result.isSuccess, isFalse);
      expect(fixture.adapter.requests, hasLength(1));
      expect(result.isNetworkError, isFalse);
    });
  }

  test(
    'cancelled requests return a cancellation failure without dispatch',
    () async {
      final cancel = CancelToken()..cancel('Synthetic cancellation');
      final result = await fixture.calls.get<Object?>(
        '/fixture',
        withToken: false,
        cancelToken: cancel,
      );
      expect(result.failureType, NetworkFailureType.cancelled);
      expect(fixture.adapter.requests, isEmpty);
    },
  );

  test(
    'multipart sends a valid boundary and reports upload progress',
    () async {
      var progressed = false;
      await fixture.calls.put<Object?>(
        '/auth/update-profile/',
        withToken: false,
        data: FormData.fromMap({
          'photo': MultipartFile.fromString(
            'synthetic-image',
            filename: 'fixture.txt',
          ),
        }),
        onSendProgress: (sent, total) => progressed = sent == total,
      );
      final request = fixture.adapter.requests.single;
      expect(request.contentType, startsWith('multipart/form-data; boundary='));
      expect(
        utf8.decode(fixture.adapter.bodies.single),
        contains('synthetic-image'),
      );
      expect(progressed, isTrue);
    },
  );

  test('POST forwards plain-text and binary response types', () async {
    fixture.adapter.handler = (_) =>
        ResponseBody.fromString('fixture text', 200);
    final text = await fixture.calls.post<String>(
      '/fixture',
      withToken: false,
      responseType: ResponseType.plain,
    );
    expect(text.data, 'fixture text');
    fixture.adapter.handler = (_) => ResponseBody.fromBytes([0, 1, 255], 200);
    final bytes = await fixture.calls.post<List<int>>(
      '/fixture',
      withToken: false,
      responseType: ResponseType.bytes,
    );
    expect(bytes.data, [0, 1, 255]);
  });

  test('malformed JSON returns invalid response and is not retried', () async {
    fixture = NetworkFixture(maxRetries: 2);
    fixture.adapter.handler = (_) => ResponseBody.fromString(
      '{invalid',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
    final result = await call('GET');
    expect(result.failureType, NetworkFailureType.invalidResponse);
    expect(fixture.adapter.requests, hasLength(1));
  });

  test(
    'malformed JSON errors preserve HTTP status and authentication failure',
    () async {
      for (final status in [401, 422, 503]) {
        fixture.adapter.handler = (_) => ResponseBody.fromString(
          '<html>Fixture failure</html>',
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
        final result = await call('GET');
        expect(result.statusCode, status);
        expect(result.failureType, NetworkFailureType.fromStatusCode(status));
        expect(result.response?.data, '<html>Fixture failure</html>');
      }
    },
  );

  test('empty dynamic 204 payloads are normalized to null', () async {
    fixture.adapter.handler = (_) => jsonResponse(null, 204);
    final result = await fixture.calls.post<dynamic>(
      '/fixture',
      withToken: false,
    );
    expect(result.isSuccess, isTrue);
    expect(result.data, isNull);
  });

  test(
    'TLS handshake failures are certificate failures without retries',
    () async {
      fixture = NetworkFixture(maxRetries: 2);
      fixture.adapter.handler = (options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: const HandshakeException('Synthetic certificate rejection'),
      );
      final result = await call('GET');
      expect(result.failureType, NetworkFailureType.certificate);
      expect(result.isNetworkError, isFalse);
      expect(fixture.adapter.requests, hasLength(1));
    },
  );

  test('invalid retry configuration is rejected before initialization', () {
    expect(() => DioRepositoryImpl(maxRetries: -1), throwsArgumentError);
    expect(
      () => DioRepositoryImpl(retryDelays: [const Duration(milliseconds: -1)]),
      throwsArgumentError,
    );
  });

  test(
    'providers construct without API configuration and dispose Dio',
    () async {
      final originalBaseUrl = ApiConstants.baseUrl;
      addTearDown(() => ApiConstants.baseUrl = originalBaseUrl);
      ApiConstants.baseUrl = '';
      final container = ProviderContainer();
      final calls = container.read(networkCallsRepositoryProvider);
      final transport =
          container.read(dioRepositoryProvider) as DioRepositoryImpl;
      final adapter = FixtureAdapter();
      transport.dio.httpClientAdapter = adapter;
      expect(calls, isA<NetworkCallsRepository>());
      container.dispose();
      expect(adapter.closed, isTrue);
    },
  );

  test(
    'real HTTP adapter sends filters and preserves a plain 401 response',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <HttpRequest>[];
      server.listen((request) async {
        requests.add(request);
        request.response.statusCode = 401;
        request.response.write('Fixture invalid token');
        await request.response.close();
      });
      final transport = DioRepositoryImpl(
        baseUrl: 'http://127.0.0.1:${server.port}',
        maxRetries: 0,
        tokenUtils: fixture.tokens,
      );
      addTearDown(transport.close);
      await fixture.tokens.storeTokens(accessToken: 'synthetic-access');
      final result = await NetworkCallsRepositoryImpl(transport).get<Object?>(
        '/auth/check-auth/',
        queryParameters: {
          'status': ['one', 'two'],
        },
      );
      expect(result.statusCode, 401);
      expect(result.failureType, NetworkFailureType.unauthorized);
      expect(result.error, 'Fixture invalid token');
      expect(
        requests.single.headers.value('authorization'),
        'Bearer synthetic-access',
      );
      expect(requests.single.uri.queryParametersAll['status'], ['one', 'two']);
    },
  );
  test(
    'real HTTP adapter exposes redirects without forwarding credentials',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final paths = <String>[];
      server.listen((request) async {
        paths.add(request.uri.path);
        request.response.statusCode = 302;
        request.response.headers.set(HttpHeaders.locationHeader, '/unexpected');
        await request.response.close();
      });
      final transport = DioRepositoryImpl(
        baseUrl: 'http://127.0.0.1:${server.port}',
        tokenUtils: fixture.tokens,
      );
      addTearDown(transport.close);
      await fixture.tokens.storeTokens(accessToken: 'synthetic-access');
      final result = await NetworkCallsRepositoryImpl(
        transport,
      ).get<Object?>('/fixture');
      expect(result.statusCode, 302);
      expect(result.isSuccess, isFalse);
      expect(paths, ['/fixture']);
    },
  );
}
