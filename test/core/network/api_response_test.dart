import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/dio_exception_handler.dart';
import 'package:sabi_pipu_tms/l10n/network_failure_localization.dart';

void main() {
  Response<dynamic> response(Object? data, int? status) => Response<dynamic>(
    requestOptions: RequestOptions(path: '/fixture'),
    data: data,
    statusCode: status,
  );

  test('every 2xx response succeeds and preserves its transport response', () {
    for (final status in [200, 201, 202, 204, 206, 299]) {
      final raw = response(status == 204 ? null : {'id': 'fixture'}, status);
      final result = ApiResponse<Map<String, dynamic>>.general(raw);
      expect(result.isSuccess, isTrue);
      expect(result.isSuccess200, isTrue);
      expect(result.error, isNull);
      expect(result.response, same(raw));
      expect(result.data, raw.data);
    }
  });

  test('missing status and non-2xx statuses never report success', () {
    for (final status in [null, 100, 301, 304, 400, 401, 422, 429, 500, 599]) {
      final result = ApiResponse<Object?>.general(response(null, status));
      expect(result.isSuccess, isFalse, reason: 'Status $status');
      expect(result.isSuccess200, isFalse);
      expect(result.failureType, isNotNull);
    }
  });

  test('success without status and empty success use the success branch', () {
    expect(
      ApiResponse<String>.success(
        'value',
      ).when(success: (data) => data, failure: (_) => 'failure'),
      'value',
    );
    expect(
      ApiResponse<String>.general(
        response(null, 204),
      ).when(success: (data) => data == null, failure: (_) => false),
      isTrue,
    );
    expect(
      ApiResponse<String>.error(
        'fixture',
        statusCode: 200,
      ).when(success: (_) => false, failure: (_) => true),
      isTrue,
    );
  });

  test('incompatible error envelopes do not cast to the success type', () {
    final raw = response({'detail': 'Fixture error'}, 400);
    final result = ApiResponse<List<int>>.general(raw);
    expect(result.data, isNull);
    expect(result.error, 'Fixture error');
    expect(result.response?.data, raw.data);
    expect(
      ApiResponse<int>.error('fixture', data: {'detail': []}).data,
      isNull,
    );
  });

  test('malformed success bodies are typed invalid-response failures', () {
    final result = ApiResponse<List<int>>.general(response({'id': 1}, 200));
    expect(result.failureType, NetworkFailureType.invalidResponse);
    expect(result.isSuccess200, isFalse);
  });

  test(
    'backend validation envelopes are parsed without unsafe string casts',
    () {
      final cases = <Object?, String>{
        {
          'detail': [
            {
              'loc': ['body', 'email'],
              'msg': 'Fixture invalid email',
            },
          ],
        }: 'Fixture invalid email',
        {
          'message': {'msg': 'Fixture nested error'},
        }: 'Fixture nested error',
        {'message': 42, 'error': [], 'detail': 'Fixture detail'}:
            'Fixture detail',
        'Fixture text': 'Fixture text',
        [
          null,
          4,
          {'msg': 'Fixture list error'},
        ]: 'Fixture list error',
        null: 'network.validation',
        '': 'network.validation',
      };
      for (final entry in cases.entries) {
        final raw = response(entry.key, 422);
        final result = DioExceptionHandler.handleDioException<int>(
          DioException(
            requestOptions: raw.requestOptions,
            response: raw,
            type: DioExceptionType.badResponse,
          ),
        );
        expect(result.failureType, NetworkFailureType.validation);
        expect(result.error, entry.value);
      }
    },
  );

  test('mapping failures never throw and preserve transport context', () {
    final raw = response({'id': 'fixture'}, 200);
    final result = ApiResponse<Map<String, dynamic>>.general(
      raw,
    ).map<int>((_) => throw const FormatException('private fixture'));
    expect(result.failureType, NetworkFailureType.invalidResponse);
    expect(result.statusCode, 200);
    expect(result.isSuccess200, isFalse);
    expect(result.response, same(raw));
    expect(result.error, isNot(contains('private fixture')));
    expect(
      ApiResponse<int>.success(null).map((value) => '$value').hasError,
      isTrue,
    );
    expect(ApiResponse<int?>.success(null).map((value) => value ?? 7).data, 7);
  });

  test(
    'mapping propagates failure type, network flag, metadata and response',
    () {
      final raw = response(null, 408);
      final original = ApiResponse<int>.error(
        'network.timeout',
        failureType: NetworkFailureType.timeout,
        isNetworkError: true,
        metadata: {'attempt': 1},
        statusCode: 408,
        response: raw,
      );
      final mapped = original.map<String>(
        (_) => throw StateError('Not called'),
      );
      expect(mapped.failureType, NetworkFailureType.timeout);
      expect(mapped.isNetworkError, isTrue);
      expect(mapped.metadata, original.metadata);
      expect(mapped.response, same(raw));
      expect(mapped.statusCode, 408);
    },
  );

  test('diagnostic string representations do not expose private payloads', () {
    final success = ApiResponse.success({'token': 'synthetic-private-token'});
    final failure = ApiResponse.error('synthetic-private-error');
    expect(success.toString(), isNot(contains('synthetic-private-token')));
    expect(failure.toString(), isNot(contains('synthetic-private-error')));
    expect(
      DioExceptionHandler.getLogMessage(
        DioException(
          requestOptions: RequestOptions(
            path: '/reset?token=synthetic-private-token',
          ),
          message: 'synthetic-private-error',
        ),
      ),
      isNot(contains('synthetic-private')),
    );
    expect(
      DioExceptionHandler.getLogMessage(StateError('synthetic-private')),
      isNot(contains('synthetic-private')),
    );
  });

  test('all typed failures have localized user-facing copy', () {
    final catalog =
        jsonDecode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
    final errors = catalog['network']['errors'] as Map<String, dynamic>;

    expect(
      errors.keys,
      unorderedEquals(NetworkFailureType.values.map((type) => type.name)),
    );
    for (final type in NetworkFailureType.values) {
      expect(type.translationKey, 'network.errors.${type.name}');
      expect(
        errors[type.name],
        isA<String>().having((text) => text.trim(), 'copy', isNotEmpty),
      );
    }
  });
}
