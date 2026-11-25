import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Writes app-owned downloads without requesting access to other apps' files.
class AndroidStorageService {
  static const _channel = MethodChannel('ng.hrng/downloads');

  static Future<bool> requestPermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    // MediaStore supports adding downloads and gallery media without a storage
    // permission from Android 10. Legacy storage permissions no longer grant
    // shared-storage write access on modern Android releases.
    if (androidInfo.version.sdkInt >= 29) return true;

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Copies an already downloaded temporary file into public Downloads.
  static Future<bool> saveToDownloads(
    String path, {
    required String name,
  }) async {
    return await _channel.invokeMethod<bool>('saveToDownloads', {
          'path': path,
          'name': name,
        }) ??
        false;
  }
}
