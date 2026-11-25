import 'dart:convert';

import 'package:sabi_pipu_tms/core/extensions/string_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SharedKeys { hasOnboarded, themeMode }

class SharedPreferencesService {
  static SharedPreferences? _preferences;

  // Initialize SharedPreferences instance
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Reloads to fetch latest updates from native side
  static Future<void> reload() async {
    await _preferences?.reload();
  }

  // Set methods
  static Future<void> setString({
    required String key,
    required String value,
  }) async {
    final preferences = _preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(key, value)) {
      throw StateError('Could not save a string preference');
    }
  }

  static Future<void> setBool({
    required String key,
    required bool value,
  }) async {
    final preferences = _preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool(key, value)) {
      throw StateError('Could not save a boolean preference');
    }
  }

  static Future<void> setInt({required String key, required int value}) async {
    ' key: $key, value: $value'.logInfo(name: 'setInt sharedPref');

    await _preferences?.setInt(key, value);
  }

  static Future<void> setDouble({
    required String key,
    required double value,
  }) async {
    ' key: $key, value: $value'.logInfo(name: 'setInt sharedPref');

    await _preferences?.setDouble(key, value);
  }

  static Future<void> setStringList({
    required String key,
    required List<String> value,
  }) async {
    ' key: $key, value: $value'.logInfo(name: 'setStringList sharedPref');

    await _preferences?.setStringList(key, value);
  }

  static Future<void> setObject({
    required String key,
    required Object value,
  }) async {
    ' key: $key, value: $value'.logInfo(
      name: 'setStringListFromString sharedPref',
    );

    final jsonString = json.encode(value);
    await _preferences?.setString(key, jsonString);
  }

  // Get methods
  static String? getString({required String key}) {
    return _preferences?.getString(key);
  }

  static bool getBool({required String key}) {
    return _preferences?.getBool(key) ?? false;
  }

  static int? getInt({required String key}) {
    return _preferences?.getInt(key);
  }

  static double? getDouble({required String key}) {
    return _preferences?.getDouble(key);
  }

  static List<String>? getStringList({required String key}) {
    return _preferences?.getStringList(key);
  }

  static T? getObject<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromMap,
  }) {
    final jsonString = _preferences?.getString(key);
    if (jsonString != null) {
      final Map<String, dynamic> map =
          json.decode(jsonString) as Map<String, dynamic>;
      return fromMap(map);
    }
    return null;
  }

  static bool containsKey({required String key}) {
    return _preferences?.containsKey(key) ?? false;
  }

  // Remove methods
  static Future<void> remove({required String key}) async {
    ' key: $key'.logInfo(name: 'remove sharedPref');

    await _preferences?.remove(key);
  }

  // Clear all stored data
  static Future<void> clearAll() async {
    await _preferences?.clear();
  }
}
