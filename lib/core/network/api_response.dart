import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Transport failures are localized by the presentation layer.
enum NetworkFailureType {
  configuration,
  connection,
  timeout,
  cancelled,
  certificate,
  tokenStorage,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  server,
  invalidResponse,
  unknown;

  static NetworkFailureType fromStatusCode(int? statusCode) =>
      switch (statusCode) {
        400 || 422 => validation,
        401 => unauthorized,
        403 => forbidden,
        404 => notFound,
        408 => timeout,
        409 => conflict,
        429 => rateLimited,
        int() && >= 500 && < 600 => server,
        _ => unknown,
      };
}

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;

  /// Backend diagnostic only; use [failureType] to select localized UI copy.
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? metadata;
  final bool isNetworkError;
  final Response<dynamic>? response;
  final NetworkFailureType? failureType;

  const ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
    this.metadata,
    this.isNetworkError = false,
    this.response,
    this.failureType,
  });

  factory ApiResponse.success(
    T? data, {
    int? statusCode,
    Map<String, dynamic>? metadata,
    Response<dynamic>? response,
  }) => ApiResponse._(
    isSuccess: true,
    data: data,
    statusCode: statusCode,
    metadata: metadata,
    response: response,
  );

  factory ApiResponse.error(
    Object error, {
    Object? data,
    int? statusCode,
    Map<String, dynamic>? metadata,
    bool isNetworkError = false,
    Response<dynamic>? response,
    NetworkFailureType failureType = NetworkFailureType.unknown,
  }) => ApiResponse._(
    isSuccess: false,
    error: error.toString(),
    statusCode: statusCode,
    metadata: metadata,
    isNetworkError: isNetworkError,
    // Error envelopes need not have the same shape as successful payloads.
    data: data is T ? data : null,
    response: response,
    failureType: failureType,
  );

  factory ApiResponse.general(Response<dynamic> response) {
    final status = response.statusCode;
    if (status == null || status < 200 || status >= 300) {
      final failure = NetworkFailureType.fromStatusCode(status);
      return ApiResponse.error(
        _errorDiagnostic(response.data) ?? 'network.${failure.name}',
        data: response.data,
        statusCode: status,
        response: response,
        failureType: failure,
      );
    }
    final body = status == 204 || status == 205 ? null : response.data;
    if (body != null && body is! T) {
      return ApiResponse.error(
        'network.invalidResponse',
        statusCode: status,
        response: response,
        failureType: NetworkFailureType.invalidResponse,
      );
    }
    return ApiResponse.success(
      body as T?,
      statusCode: status,
      response: response,
    );
  }

  static String? _errorDiagnostic(Object? body) {
    if (body is String) return body.trim().isEmpty ? null : body;
    if (body is Map) {
      for (final key in ['message', 'error', 'detail', 'msg']) {
        final diagnostic = _errorDiagnostic(body[key]);
        if (diagnostic != null) return diagnostic;
      }
    } else if (body is List) {
      // FastAPI validation errors use detail: [{loc: [...], msg: ...}].
      for (final item in body) {
        final diagnostic = _errorDiagnostic(item);
        if (diagnostic != null) return diagnostic;
      }
    }
    return null;
  }

  bool get hasData => isSuccess && data != null;
  bool get isSuccess200 =>
      isSuccess &&
      statusCode != null &&
      statusCode! >= 200 &&
      statusCode! < 300;
  bool get hasError => !isSuccess;
  String get apiErrorTechnicalMessage => error ?? 'network.unknown';
  T? get safeData => isSuccess ? data : null;
  String get errorMessage => apiErrorTechnicalMessage;

  /// Successful no-content responses pass null to the success callback.
  R when<R>({
    required R Function(T? data) success,
    required R Function(String error) failure,
  }) => isSuccess ? success(data) : failure(apiErrorTechnicalMessage);

  ApiResponse<R> map<R>(R Function(T data) mapper) {
    if (!isSuccess) {
      return ApiResponse.error(
        errorMessage,
        statusCode: statusCode,
        metadata: metadata,
        isNetworkError: isNetworkError,
        response: response,
        failureType: failureType ?? NetworkFailureType.unknown,
      );
    }
    try {
      return ApiResponse.success(
        mapper(data as T),
        statusCode: statusCode,
        metadata: metadata,
        response: response,
      );
    } catch (_) {
      return ApiResponse.error(
        'network.invalidResponse',
        statusCode: statusCode,
        metadata: metadata,
        response: response,
        failureType: NetworkFailureType.invalidResponse,
      );
    }
  }

  // Payloads and backend diagnostics may contain private information.
  @override
  String toString() =>
      'ApiResponse(isSuccess: $isSuccess, statusCode: $statusCode, '
      'failureType: ${failureType?.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiResponse<T> &&
          other.isSuccess == isSuccess &&
          other.data == data &&
          other.error == error &&
          other.statusCode == statusCode &&
          other.failureType == failureType &&
          other.isNetworkError == isNetworkError &&
          mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
    isSuccess,
    data,
    error,
    statusCode,
    failureType,
    isNetworkError,
    metadata == null
        ? null
        : Object.hashAllUnordered(
            metadata!.entries.map(
              (entry) => Object.hash(entry.key, entry.value),
            ),
          ),
  );
}
