import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_response.dart';
import 'dio_exception_handler.dart';
import 'dio_repository.dart';

final networkCallsRepositoryProvider = Provider<NetworkCallsRepository>((ref) {
  return NetworkCallsRepositoryImpl(ref.watch(dioRepositoryProvider));
});

abstract class NetworkCallsRepository {
  // sends a GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    void Function(int, int)? onReceiveProgress,
  });

  // sends a POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    ResponseType? responseType,
  });
  // sends a  PUT  request
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  });

  // sends a DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
  });

  // sends a PATCH requests
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
  });
}

class NetworkCallsRepositoryImpl implements NetworkCallsRepository {
  final DioRepository _dioRepository;

  NetworkCallsRepositoryImpl(this._dioRepository);

  Future<ApiResponse<T>> _execute<T>(
    Future<Response<dynamic>> Function() call,
    bool logResponse,
  ) async {
    final ApiResponse<T> result;
    try {
      result = ApiResponse<T>.general(await call());
    } catch (error) {
      return DioExceptionHandler.handleDioException<T>(error);
    }
    if (logResponse && kDebugMode) {
      developer.log(result.toString(), name: 'NETWORK');
    }
    return result;
  }

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    ProgressCallback? onReceiveProgress,
  }) => _execute<T>(
    () => _dioRepository.get<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      withToken: withToken,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    ),
    logResponse,
  );

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    ResponseType? responseType,
  }) => _execute<T>(
    () => _dioRepository.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      withToken: withToken,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      responseType: responseType,
    ),
    logResponse,
  );

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) => _execute<T>(
    () => _dioRepository.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      withToken: withToken,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    ),
    logResponse,
  );

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
  }) => _execute<T>(
    () => _dioRepository.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      withToken: withToken,
      cancelToken: cancelToken,
    ),
    logResponse,
  );

  @override
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
  }) => _execute<T>(
    () => _dioRepository.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      withToken: withToken,
      cancelToken: cancelToken,
    ),
    logResponse,
  );
}
