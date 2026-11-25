import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/connectivity_repository.dart';
import 'package:sabi_pipu_tms/core/network/dio_exception_handler.dart';

void main() {
  test('asynchronous connectivity probe failures resolve to false', () async {
    final repository = ConnectivityRepositoryImpl(
      connectivityCheck: () async {
        throw const SocketException('Synthetic unavailable');
      },
    );
    expect(await repository.checkConnectivity(), isFalse);
  });

  test('interface and implementation both default to one attempt', () async {
    var probes = 0;
    var notices = 0;
    final ConnectivityRepository repository = ConnectivityRepositoryImpl(
      connectivityCheck: () async {
        probes++;
        return false;
      },
    );
    final result = await repository.executeWithConnectivityCheck<int>(
      networkCall: () async => throw StateError('Must not dispatch'),
      onNetworkUnavailable: () => notices++,
    );
    expect(result.failureType, NetworkFailureType.connection);
    expect(result.isNetworkError, isTrue);
    expect(probes, 1);
    expect(notices, 1);
  });

  test(
    'explicit retries preserve millisecond backoff and stop on success',
    () async {
      var attempts = 0;
      final delays = <Duration>[];
      final repository = ConnectivityRepositoryImpl(
        connectivityCheck: () async => true,
        delay: (duration) async => delays.add(duration),
      );
      final result = await repository.executeWithConnectivityCheck<int>(
        maxAttempts: 3,
        retryDelay: const Duration(milliseconds: 75),
        networkCall: () async {
          attempts++;
          if (attempts < 3) throw const SocketException('Synthetic outage');
          return ApiResponse.success(7);
        },
      );
      expect(result.data, 7);
      expect(attempts, 3);
      expect(delays, [
        const Duration(milliseconds: 75),
        const Duration(milliseconds: 150),
      ]);
    },
  );

  test('probe retries can recover without notifying unavailability', () async {
    var probes = 0;
    var notices = 0;
    final repository = ConnectivityRepositoryImpl(
      connectivityCheck: () async => ++probes >= 2,
      delay: (_) async {},
    );
    final result = await repository.executeWithConnectivityCheck<int>(
      maxAttempts: 3,
      networkCall: () async => ApiResponse.success(7),
      onNetworkUnavailable: () => notices++,
    );
    expect(result.data, 7);
    expect(probes, 2);
    expect(notices, 0);
  });

  test('non-transient thrown errors and failures are not retried', () async {
    var attempts = 0;
    final repository = ConnectivityRepositoryImpl(
      connectivityCheck: () async => true,
      delay: (_) async => throw StateError('Must not delay'),
    );
    final result = await repository.executeWithConnectivityCheck<int>(
      maxAttempts: 3,
      networkCall: () async {
        attempts++;
        throw const FormatException('Synthetic malformed payload');
      },
    );
    expect(result.failureType, NetworkFailureType.invalidResponse);
    expect(attempts, 1);
  });

  test('invalid retry arguments fail before invoking callbacks', () async {
    final repository = ConnectivityRepositoryImpl(
      connectivityCheck: () async => throw StateError('Must not probe'),
    );
    for (final attempts in [0, -1]) {
      await expectLater(
        repository.executeWithConnectivityCheck<int>(
          maxAttempts: attempts,
          networkCall: () async => ApiResponse.success(7),
        ),
        throwsArgumentError,
      );
    }
    await expectLater(
      repository.executeWithConnectivityCheck<int>(
        retryDelay: const Duration(milliseconds: -1),
        networkCall: () async => ApiResponse.success(7),
      ),
      throwsArgumentError,
    );
  });

  test('internet status forwards the connection status stream', () async {
    final repository = ConnectivityRepositoryImpl(
      statusStream: () => Stream.fromIterable([
        InternetStatus.connected,
        InternetStatus.disconnected,
      ]),
    );
    expect(await repository.internetStatus().toList(), [
      InternetStatus.connected,
      InternetStatus.disconnected,
    ]);
  });

  test('retry classification never relies on backend message text', () {
    for (final word in [
      'connection',
      'network',
      'timeout',
      'server error 503',
    ]) {
      expect(
        DioExceptionHandler.shouldRetryError(
          ApiResponse.error(
            word,
            statusCode: 400,
            failureType: NetworkFailureType.validation,
          ),
        ),
        isFalse,
      );
    }
    for (final type in [
      DioExceptionType.cancel,
      DioExceptionType.badCertificate,
      DioExceptionType.unknown,
    ]) {
      final response = DioExceptionHandler.handleDioException<int>(
        DioException(
          requestOptions: RequestOptions(path: '/fixture'),
          type: type,
          message: 'Fixture connection timeout',
        ),
      );
      expect(DioExceptionHandler.shouldRetryError(response), isFalse);
    }
  });
}
