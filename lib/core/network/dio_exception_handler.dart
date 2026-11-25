import 'dart:io';

import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'api_response.dart';
import 'token_utils.dart';

class DioExceptionHandler {
  static ApiResponse<T> handleDioException<T>(Object e) {
    if (e is DioException &&
        e.type == DioExceptionType.badResponse &&
        e.response != null) {
      return ApiResponse<T>.general(e.response!);
    }
    final failure = switch (e) {
      ApiConfigurationException() => NetworkFailureType.configuration,
      TokenStorageException() => NetworkFailureType.tokenStorage,
      TlsException() => NetworkFailureType.certificate,
      SocketException() => NetworkFailureType.connection,
      FormatException() || TypeError() => NetworkFailureType.invalidResponse,
      DioException(
        type: DioExceptionType.connectionTimeout ||
            DioExceptionType.sendTimeout ||
            DioExceptionType.receiveTimeout,
      ) =>
        NetworkFailureType.timeout,
      DioException(type: DioExceptionType.cancel) =>
        NetworkFailureType.cancelled,
      DioException(type: DioExceptionType.badCertificate) =>
        NetworkFailureType.certificate,
      DioException(error: TlsException()) => NetworkFailureType.certificate,
      DioException(type: DioExceptionType.connectionError) =>
        NetworkFailureType.connection,
      DioException(error: SocketException()) => NetworkFailureType.connection,
      DioException(error: ApiConfigurationException()) =>
        NetworkFailureType.configuration,
      DioException(error: TokenStorageException()) =>
        NetworkFailureType.tokenStorage,
      DioException(error: FormatException() || TypeError()) =>
        NetworkFailureType.invalidResponse,
      _ => NetworkFailureType.unknown,
    };
    return ApiResponse.error(
      'network.${failure.name}',
      statusCode: e is DioException ? e.response?.statusCode : null,
      response: e is DioException ? e.response : null,
      failureType: failure,
      isNetworkError:
          failure == NetworkFailureType.connection ||
          failure == NetworkFailureType.timeout,
    );
  }

  /// Retry only transient failures. Request safety is checked by the caller.
  static bool shouldRetryError<T>(ApiResponse<T> response) {
    if (response.isSuccess) return false;
    if (response.failureType == NetworkFailureType.connection ||
        response.failureType == NetworkFailureType.timeout) {
      return true;
    }
    // Rate limits require a server-directed delay; do not immediately replay.
    return (response.failureType == NetworkFailureType.server ||
            response.failureType == NetworkFailureType.unknown) &&
        [408, 500, 502, 503, 504].contains(response.statusCode);
  }

  /// Excludes URLs, headers, bodies and raw exception messages.
  static String getLogMessage(Object e) {
    if (e is DioException) {
      return '[${e.type.name}] Status: ${e.response?.statusCode ?? 'unknown'}';
    }
    return '[ERROR] ${e.runtimeType}';
  }
}
