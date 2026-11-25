import 'package:dio/dio.dart';

/// All environments use platform certificate verification. Development APIs
/// should install a trusted development certificate instead of bypassing TLS.
class DioCertificateException {
  static Dio createDio() => Dio();
  static Dio get developmentDio => createDio();
  static Dio get productionDio => createDio();
}
