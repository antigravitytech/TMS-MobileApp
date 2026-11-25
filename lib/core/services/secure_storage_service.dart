import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//TODO: Change user to userData
enum SecureKeys { accessToken, refreshToken, tokenHash, user, userId }

class SecureStorageService {
  static FlutterSecureStorage? _secureStorage;

  static FlutterSecureStorage get _instance {
    _secureStorage ??= const FlutterSecureStorage();
    return _secureStorage!;
  }

  // Set methods
  static Future<void> setString({required String key, required String value}) async {
    await _instance.write(key: key, value: value);
  }

  // Get methods
  static Future<String?> getString({required String key}) async {
    return await _instance.read(key: key);
  }

  // Remove methods
  static Future<void> remove({required String key}) async {
    await _instance.delete(key: key);
  }

  // Clear all
  static Future<void> clear() async {
    await _instance.deleteAll();
  }
}
