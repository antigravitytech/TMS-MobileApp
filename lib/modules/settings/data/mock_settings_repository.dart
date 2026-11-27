part of 'settings_repository.dart';

/// Keeps every switch on the device; there's no account to save to.
class MockSettingsRepository implements SettingsRepository {
  @override
  Future<Map<String, bool>> notices() async => {
    for (final key in settingsNotices) key: DeviceNotices.read(key),
  };

  @override
  Future<void> setNotice(String key, bool on) => DeviceNotices.write(key, on);

  @override
  Future<Account?> saveAppearance({String? theme, String? language}) async =>
      null;
}
