import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'api_response.dart';
import 'dio_exception_handler.dart';

final connectivityRepositoryProvider = Provider<ConnectivityRepository>((ref) {
  return ConnectivityRepositoryImpl();
});

abstract class ConnectivityRepository {
  /// For explicitly requested connectivity checks. Normal API calls use Dio
  /// directly: a failed external probe cannot establish API reachability.
  /// Callers requesting retries must ensure their operation is safe to replay.
  Future<ApiResponse<T>> executeWithConnectivityCheck<T>({
    required Future<ApiResponse<T>> Function() networkCall,
    VoidCallback? onNetworkUnavailable,
    int maxAttempts = 1,
    Duration retryDelay = const Duration(seconds: 2),
    String? operationName,
  });
  Stream<InternetStatus> internetStatus();
  Future<bool> checkConnectivity();
}

class ConnectivityRepositoryImpl implements ConnectivityRepository {
  ConnectivityRepositoryImpl({
    Future<bool> Function()? connectivityCheck,
    Stream<InternetStatus> Function()? statusStream,
    Future<void> Function(Duration)? delay,
  }) : _connectivityCheck =
           connectivityCheck ?? (() => InternetConnection().hasInternetAccess),
       _statusStream =
           statusStream ?? (() => InternetConnection().onStatusChange),
       _delay = delay ?? Future<void>.delayed;

  final Future<bool> Function() _connectivityCheck;
  final Stream<InternetStatus> Function() _statusStream;
  final Future<void> Function(Duration) _delay;

  @override
  Future<bool> checkConnectivity() async {
    try {
      return await _connectivityCheck();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ApiResponse<T>> executeWithConnectivityCheck<T>({
    required Future<ApiResponse<T>> Function() networkCall,
    VoidCallback? onNetworkUnavailable,
    int maxAttempts = 1,
    Duration retryDelay = const Duration(seconds: 2),
    String? operationName,
  }) async {
    if (maxAttempts < 1) throw ArgumentError.value(maxAttempts, 'maxAttempts');
    if (retryDelay.isNegative) {
      throw ArgumentError.value(retryDelay, 'retryDelay');
    }

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final hasConnection = await checkConnectivity();
      ApiResponse<T> result;
      if (!hasConnection) {
        result = ApiResponse.error(
          'network.connection',
          failureType: NetworkFailureType.connection,
          isNetworkError: true,
        );
      } else {
        try {
          result = await networkCall();
        } catch (error) {
          result = DioExceptionHandler.handleDioException<T>(error);
        }
      }
      if (attempt == maxAttempts ||
          !DioExceptionHandler.shouldRetryError(result)) {
        if (!hasConnection) onNetworkUnavailable?.call();
        return result;
      }
      // Preserve sub-second delays; truncating to seconds created tight loops.
      await _delay(retryDelay * attempt);
    }
    throw StateError('Unreachable connectivity attempt');
  }

  @override
  Stream<InternetStatus> internetStatus() => _statusStream();
}
