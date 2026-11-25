import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sabi_pipu_tms/core/network/dio_exception_handler.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';

final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService(ref.watch(networkCallsRepositoryProvider));
});

class NetworkService {
  final NetworkCallsRepository _networkCallRepository;
  NetworkService(this._networkCallRepository);

  ApiResponse<T> _failure<T>(ApiResponse<dynamic> response) =>
      ApiResponse.error(
        response.errorMessage,
        statusCode: response.statusCode,
        metadata: response.metadata,
        isNetworkError: response.isNetworkError,
        response: response.response,
        failureType: response.failureType ?? NetworkFailureType.unknown,
      );

  Future<ApiResponse<T>> getModel<T>(
    String url, {
    required T Function(Map<String, dynamic>) fromJson,
    Object? data,
    Map<String, dynamic>? queryParams,
    String? name,
    bool logResponse = false,
    bool isStringResponse = false,
  }) async {
    try {
      final response = await _networkCallRepository.get(
        url,
        data: data,
        queryParameters: queryParams,
        logResponse: logResponse,
      );
      if (response.isSuccess200) {
        return ApiResponse.success(
          isStringResponse
              ? response.safeData as T
              : fromJson(response.safeData),
          statusCode: response.statusCode,
        );
      }
      return _failure(response);
    } catch (error) {
      return DioExceptionHandler.handleDioException<T>(error);
    }
  }

  Future<ApiResponse<T>> postModel<T>(
    String url, {
    Object? data,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(Object?)? fromResponse,
    Map<String, dynamic>? queryParams,
    String? mapKey,
    T? emptySuccessData,
    bool logResponse = false,
    bool isStringResponse = false,
    String? name,
  }) async {
    assert(
      isStringResponse ||
          fromJson != null ||
          fromResponse != null ||
          mapKey != null ||
          emptySuccessData != null,
      'fromJson, fromResponse, or mapKey must be provided',
    );

    try {
      final response = await _networkCallRepository.post(
        url,
        data: data,
        queryParameters: queryParams,
        logResponse: logResponse,
      );
      if (response.isSuccess200) {
        final responseData = response.safeData;
        if (responseData == null && emptySuccessData != null) {
          return ApiResponse.success(
            emptySuccessData,
            statusCode: response.statusCode,
          );
        }

        final parsedData = fromResponse != null
            ? fromResponse(responseData)
            : isStringResponse
            ? responseData as T
            : (mapKey == null ? null : responseData?[mapKey] as T?) ??
                  fromJson!(responseData);
        return ApiResponse.success(parsedData, statusCode: response.statusCode);
      }
      return _failure(response);
    } catch (error) {
      return DioExceptionHandler.handleDioException<T>(error);
    }
  }

  Future<ApiResponse<T>> putModel<T>(
    String url, {
    required Map<String, dynamic> data,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(Object?)? fromResponse,
    String? mapKey,
    String? name,
    bool logResponse = false,
  }) async {
    assert(
      fromJson != null || fromResponse != null || mapKey != null,
      'fromJson, fromResponse, or mapKey must be provided',
    );
    try {
      final response = await _networkCallRepository.put(url, data: data);
      if (response.isSuccess200) {
        return ApiResponse.success(
          fromResponse != null
              ? fromResponse(response.safeData)
              : (response.safeData?[mapKey] as T?) ??
                    fromJson!(response.safeData),
          statusCode: response.statusCode,
        );
      }
      return _failure(response);
    } catch (error) {
      return DioExceptionHandler.handleDioException<T>(error);
    }
  }

  /// PUT endpoints whose documented contract has no request body.
  Future<ApiResponse<T>> putWithoutBody<T>(
    String url, {
    required T Function(Object?) fromResponse,
  }) async {
    try {
      final response = await _networkCallRepository.put<Object?>(url);
      if (response.isSuccess200) {
        return ApiResponse.success(
          fromResponse(response.safeData),
          statusCode: response.statusCode,
        );
      }
      return _failure(response);
    } catch (error) {
      return DioExceptionHandler.handleDioException<T>(error);
    }
  }

  /// PUT variant for multipart bodies (e.g. receipt uploads): Dio accepts an
  /// [FormData] payload, so it is forwarded as-is through the network layer.
  Future<ApiResponse<T>> putMultipartModel<T>(
    String url, {
    required FormData formData,
    required T Function(Map<String, dynamic>) fromJson,
    String? name,
    bool logResponse = false,
  }) async {
    try {
      final response = await _networkCallRepository.put(
        url,
        data: formData,
        logResponse: logResponse,
      );
      if (response.isSuccess200) {
        return ApiResponse.success(
          fromJson(response.safeData),
          statusCode: response.statusCode,
        );
      }
      return _failure(response);
    } catch (error) {
      return DioExceptionHandler.handleDioException<T>(error);
    }
  }

  /// POST variant of [putMultipartModel] — FormData as the request body.
  Future<ApiResponse<T>> postMultipartModel<T>(
    String url, {
    required FormData formData,
    required T Function(Map<String, dynamic>) fromJson,
    String? name,
    bool logResponse = false,
  }) async {
    try {
      final response = await _networkCallRepository.post(
        url,
        data: formData,
        logResponse: logResponse,
      );
      if (response.isSuccess200) {
        return ApiResponse.success(
          fromJson(response.safeData),
          statusCode: response.statusCode,
        );
      }
      return _failure(response);
    } catch (error) {
      return DioExceptionHandler.handleDioException<T>(error);
    }
  }

  Future<ApiResponse<T>> deleteModel<T>(
    String url, {
    T Function(Map<String, dynamic>)? fromJson,
    Map<String, dynamic>? data,
    T? emptySuccessData,
    String? name,
    bool logResponse = false,
  }) async {
    try {
      // The DELETE body shape is backend-defined (empty, {"message": ...}, a
      // list, or plain text), so the request is fetched untyped — casting the
      // decoded body to [T] would throw a TypeError for any shape mismatch and
      // turn a successful 2xx delete into a reported error.
      final response = await _networkCallRepository.delete<Object?>(
        url,
        data: data,
        logResponse: logResponse,
      );
      if (response.isSuccess200) {
        final body = response.safeData;
        if (body is Map<String, dynamic>) {
          final parsed = fromJson?.call(body);
          if (parsed != null) {
            return ApiResponse.success(parsed, statusCode: response.statusCode);
          }
          final message = body['message']?.toString();
          if (message != null && message.isNotEmpty) {
            return ApiResponse.success(
              message as T,
              statusCode: response.statusCode,
            );
          }
        }
        // 2xx without a parseable payload: fall back to the caller default,
        // then the parser on an empty payload, then an empty message.
        if (emptySuccessData != null) {
          return ApiResponse.success(
            emptySuccessData,
            statusCode: response.statusCode,
          );
        }
        final parsedEmpty = fromJson?.call(const {});
        if (parsedEmpty != null) {
          return ApiResponse.success(
            parsedEmpty,
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success('' as T, statusCode: response.statusCode);
      }
      return _failure(response);
    } catch (error) {
      return DioExceptionHandler.handleDioException<T>(error);
    }
  }

  Future<ApiResponse<List<T>>> getList<T>(
    String url, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParams,
    String? name,
    bool logResponse = false,
    bool isNotMap = false,
  }) async {
    try {
      final response = await _networkCallRepository.get(
        url,
        queryParameters: queryParams,
        logResponse: logResponse,
      );
      if (response.isSuccess200) {
        return ApiResponse.success(
          isNotMap
              ? (response.safeData as List).map((item) => item as T).toList()
              : (response.safeData as List)
                    .map((item) => fromJson(item))
                    .toList(),
          statusCode: response.statusCode,
        );
      }
      return _failure(response);
    } catch (error) {
      return DioExceptionHandler.handleDioException<List<T>>(error);
    }
  }

  Future<ApiResponse<List<T>>> postList<T>(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    required T Function(Map<String, dynamic>) fromJson,
    String? name,
    bool logResponse = false,
  }) async {
    try {
      final response = await _networkCallRepository.post(
        url,
        data: data,
        queryParameters: queryParams,
        logResponse: logResponse,
      );
      if (response.isSuccess200) {
        return ApiResponse.success(
          (response.safeData as List).map((item) => fromJson(item)).toList(),
          statusCode: response.statusCode,
        );
      }
      return _failure(response);
    } catch (error) {
      return DioExceptionHandler.handleDioException<List<T>>(error);
    }
  }
}
