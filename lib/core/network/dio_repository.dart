import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment.dart';
import 'api_constants.dart';
import 'dio_exception_handler.dart';
import 'token_utils.dart';

part 'dio_repository_provider.dart';

abstract class DioRepository {
  Future<void> initialize();

  // HTTP Methods - Simplified (keeping progress callbacks)
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = false,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  });

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = false,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    ResponseType? responseType,
  });

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = false,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  });

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = false,
    CancelToken? cancelToken,
  });

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = false,
    CancelToken? cancelToken,
  });
}

class DioRepositoryImpl extends DioRepository {
  final Dio _dio;
  final TokenUtils _tokenUtils;
  final String? baseUrl;
  final int maxRetries;
  final List<Duration> _retryDelays;
  Future<void>? _initialization;

  DioRepositoryImpl({
    Dio? dio,
    TokenUtils? tokenUtils,
    this.baseUrl,
    this.maxRetries = ApiConstants.maxRetries,
    List<Duration> retryDelays = ApiConstants.retryDelays,
  }) : _dio = dio ?? Dio(),
       _tokenUtils = tokenUtils ?? TokenUtils(),
       _retryDelays = List.unmodifiable(retryDelays) {
    if (maxRetries < 0) {
      throw ArgumentError.value(maxRetries, 'maxRetries');
    }
    if (_retryDelays.any((delay) => delay.isNegative)) {
      throw ArgumentError('Retry delays must not be negative');
    }
  }

  Dio get dio => _dio;

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    // Defer configuration until initialize has cached this future, including
    // failures that must clear the cache to allow a later configuration retry.
    await Future<void>.value();
    try {
      final baseUrl = (this.baseUrl ?? ApiConstants.baseUrl).trim();
      final uri = Uri.tryParse(baseUrl);
      if (uri == null ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          !['http', 'https'].contains(uri.scheme) ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment) {
        throw const ApiConfigurationException();
      }
      _dio.options = BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: Map.of(ApiConstants.defaultHeaders),
        listFormat: ListFormat.multi,
        // Expose redirects rather than forwarding credentials or changing a
        // mutation's method/body through an implicit redirect.
        followRedirects: false,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      );
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            // Never inherit a stale token from Dio defaults or reused options.
            options.headers.removeWhere(
              (key, _) => key.toLowerCase() == 'authorization',
            );
            if (options.extra['withToken'] != true) {
              handler.next(options);
              return;
            }
            try {
              if (options.uri.origin != uri.origin ||
                  options.uri.userInfo.isNotEmpty) {
                throw const ApiConfigurationException();
              }
              final token = await _tokenUtils.getAccessToken();
              if (token == null || token.trim().isEmpty) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.badResponse,
                    response: Response<void>(
                      requestOptions: options,
                      statusCode: 401,
                    ),
                  ),
                );
                return;
              }
              options.headers['Authorization'] = 'Bearer $token';
              handler.next(options);
            } catch (error, stackTrace) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  error: error,
                  stackTrace: stackTrace,
                ),
              );
            }
          },
        ),
      );
      _dio.interceptors.add(
        RetryInterceptor(
          dio: _dio,
          retries: maxRetries,
          retryDelays: _retryDelays,
          retryEvaluator: (error, _) {
            final request = error.requestOptions;
            // Even PUT/DELETE endpoints may trigger backend workflow actions.
            // Never replay mutations or consumed request streams automatically.
            if (!['GET', 'HEAD'].contains(request.method.toUpperCase()) ||
                request.data != null) {
              return false;
            }
            return DioExceptionHandler.shouldRetryError(
              DioExceptionHandler.handleDioException<Object?>(error),
            );
          },
        ),
      );
      _dio.transformer = _HttpErrorTransformer(_dio.transformer);
    } catch (_) {
      // A missing environment can be configured and initialization retried.
      _initialization = null;
      rethrow;
    }
  }

  void close() => _dio.close(force: true);

  Options _options(bool withToken, {ResponseType? responseType}) =>
      Options(extra: {'withToken': withToken}, responseType: responseType);

  // Match the reference's repeated filters and omission of absent values.
  Map<String, dynamic>? _query(Map<String, dynamic>? parameters) =>
      parameters == null
      ? null
      : {
          for (final entry in parameters.entries)
            if (entry.value != null && entry.value != '')
              entry.key: entry.value,
        };

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = false,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    await initialize();
    return _dio.get<T>(
      path,
      data: data,
      queryParameters: _query(queryParameters),
      options: _options(withToken),
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    ResponseType? responseType,
  }) async {
    await initialize();
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: _query(queryParameters),
      options: _options(withToken, responseType: responseType),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    await initialize();
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: _query(queryParameters),
      options: _options(withToken),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = false,
    CancelToken? cancelToken,
  }) async {
    await initialize();
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: _query(queryParameters),
      options: _options(withToken),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = false,
    CancelToken? cancelToken,
  }) async {
    await initialize();
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: _query(queryParameters),
      options: _options(withToken),
      cancelToken: cancelToken,
    );
  }
}

/// Servers and proxies sometimes send malformed JSON on HTTP failures. Decode
/// those bodies as text first so a JSON parse error cannot hide a 401 or 503.
class _HttpErrorTransformer extends Transformer {
  _HttpErrorTransformer(this._delegate);

  final Transformer _delegate;

  @override
  Future<String> transformRequest(RequestOptions options) =>
      _delegate.transformRequest(options);

  @override
  Future<dynamic> transformResponse(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    if (options.validateStatus(responseBody.statusCode) ||
        options.responseType != ResponseType.json) {
      return _delegate.transformResponse(options, responseBody);
    }
    final body = await _delegate.transformResponse(
      options.copyWith(responseType: ResponseType.plain),
      responseBody,
    );
    if (body is! String ||
        !Transformer.isJsonMimeType(
          responseBody.headers[Headers.contentTypeHeader]?.firstOrNull,
        )) {
      return body;
    }
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }
}
