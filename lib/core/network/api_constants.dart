import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static const bool isDevelopment = kDebugMode;
  static const bool isProduction = kReleaseMode;
  static String? _baseUrlOverride;

  // Configuration can be read before dotenv has been loaded.
  static String get baseUrl => _baseUrlOverride ?? _environment('BASE_URL');
  static set baseUrl(String value) => _baseUrlOverride = value;
  static String get controlUrl => _environment('CONTROL_URL');

  static String _environment(String key) =>
      dotenv.isInitialized ? (dotenv.env[key] ?? '').trim() : '';

  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const int defaultPageLimit = 10;
  static const int maxRetries = 1;
  static const List<Duration> retryDelays = [Duration(seconds: 1)];

  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenExpiryKey = 'token_expiry';
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Diagnostic identifiers. Localize NetworkFailureType at the UI boundary.
  static const String networkError = 'network.connection';
  static const String timeoutError = 'network.timeout';
  static const String serverError = 'network.server';
  static const String unknownError = 'network.unknown';
  static const String authError = 'network.unauthorized';
}

class ApiConfigurationException implements Exception {
  const ApiConfigurationException();

  @override
  String toString() => 'network.configuration';
}
