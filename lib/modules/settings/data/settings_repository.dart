import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../../core/services/shared_pref_service.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';

part 'live_settings_repository.dart';
part 'mock_settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) return MockSettingsRepository();
  return LiveSettingsRepository(
    ref.watch(networkCallsRepositoryProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
  );
});

/// The notification switches on the settings page, in display order.
const settingsNotices = [
  'push_notifications',
  'reviews_mentions',
  'daily_report_reminder',
  'quiet_hours',
  'sounds_vibration',
];

const _noticeDefaults = {
  'push_notifications': true,
  'reviews_mentions': true,
  'daily_report_reminder': true,
  'quiet_hours': true,
  'sounds_vibration': false,
};

abstract class SettingsRepository {
  /// Whether each of [settingsNotices] is on.
  Future<Map<String, bool>> notices();
  Future<void> setNotice(String key, bool on);

  /// Saves my theme (`light` or `dark`) or language to my account; returns
  /// the updated account, or null when there's no account to update.
  Future<Account?> saveAppearance({String? theme, String? language});
}

/// Switches that only affect this phone, kept on the device in both modes.
abstract final class DeviceNotices {
  static String _key(String key) => 'settings.notice.$key';

  static bool read(String key) =>
      SharedPreferencesService.containsKey(key: _key(key))
      ? SharedPreferencesService.getBool(key: _key(key))
      : _noticeDefaults[key] ?? false;

  static Future<void> write(String key, bool on) =>
      SharedPreferencesService.setBool(key: _key(key), value: on);
}
