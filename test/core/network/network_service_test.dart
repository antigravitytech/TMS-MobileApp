import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/services/network_service.dart';

import 'network_fixtures.dart';

void main() {
  late NetworkFixture fixture;
  late NetworkService service;
  setUp(() async {
    fixture = NetworkFixture();
    service = NetworkService(fixture.calls);
    await fixture.tokens.storeTokens(accessToken: 'synthetic-access');
  });
  tearDown(() => fixture.transport.close());

  List<Future<ApiResponse<dynamic>> Function()> calls() => [
    () => service.getModel<String>('/fixture', fromJson: (_) => 'fixture'),
    () => service.postModel<String>('/fixture', fromResponse: (_) => 'fixture'),
    () => service.putModel<String>(
      '/fixture',
      data: {},
      fromResponse: (_) => 'fixture',
    ),
    () => service.putWithoutBody<String>(
      '/fixture',
      fromResponse: (_) => 'fixture',
    ),
    () => service.putMultipartModel<String>(
      '/fixture',
      formData: FormData(),
      fromJson: (_) => 'fixture',
    ),
    () => service.postMultipartModel<String>(
      '/fixture',
      formData: FormData(),
      fromJson: (_) => 'fixture',
    ),
    () => service.deleteModel<String>('/fixture'),
    () => service.getList<String>('/fixture', fromJson: (_) => 'fixture'),
    () => service.postList<String>('/fixture', fromJson: (_) => 'fixture'),
  ];

  test(
    'all model helpers preserve typed failures and plain error responses',
    () async {
      fixture.adapter.handler = (_) =>
          ResponseBody.fromString('Fixture unavailable', 503);
      for (final call in calls()) {
        final result = await call();
        expect(result.statusCode, 503);
        expect(result.failureType, NetworkFailureType.server);
        expect(result.error, 'Fixture unavailable');
        expect(result.response?.data, 'Fixture unavailable');
      }
    },
  );

  test(
    'all model helpers preserve connectivity and timeout classification',
    () async {
      fixture.adapter.handler = (options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );
      for (final call in calls()) {
        final result = await call();
        expect(result.failureType, NetworkFailureType.timeout);
        expect(result.isNetworkError, isTrue);
      }
    },
  );

  test('PUT model mapping preserves the successful HTTP status', () async {
    fixture.adapter.handler = (_) => jsonResponse({'id': 'fixture'}, 202);
    final result = await service.putModel<String>(
      '/fixture',
      data: {},
      fromJson: (data) => data['id'] as String,
    );
    expect(result.data, 'fixture');
    expect(result.isSuccess200, isTrue);
    expect(result.statusCode, 202);
  });

  test('empty POST success can use only a caller-supplied fallback', () async {
    fixture.adapter.handler = (_) => jsonResponse(null, 204);
    final result = await service.postModel<String>(
      '/fixture',
      emptySuccessData: 'fixture-empty-success',
    );
    expect(result.isSuccess, isTrue);
    expect(result.data, 'fixture-empty-success');
    expect(result.statusCode, 204);
  });

  test(
    'payload parser failures remain typed without logging response content',
    () async {
      fixture.adapter.handler = (_) => jsonResponse({'id': 42}, 200);
      final result = await service.getModel<String>(
        '/fixture',
        fromJson: (data) => data['id'] as String,
      );
      expect(result.failureType, NetworkFailureType.invalidResponse);
      expect(result.isSuccess, isFalse);
    },
  );
}
