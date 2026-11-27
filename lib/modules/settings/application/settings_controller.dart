import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../../onboarding/data/profile_setup_repository.dart';
import '../data/settings_repository.dart';

/// The notification switches. A change shows at once and is undone if the
/// save fails.
final settingsNoticesProvider =
    AsyncNotifierProvider.autoDispose<SettingsNotices, Map<String, bool>>(
      SettingsNotices.new,
      retry: (_, _) => null,
    );

class SettingsNotices extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() =>
      guardSession(ref, () => ref.watch(settingsRepositoryProvider).notices());

  Future<void> toggle(String key, bool on) async {
    final before = state.value;
    if (before == null) return;
    state = AsyncData({...before, key: on});
    try {
      await guardSession(
        ref,
        () => ref.read(settingsRepositoryProvider).setNotice(key, on),
      );
    } catch (_) {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    }
  }
}

final settingsActionsProvider = Provider.autoDispose(SettingsActions.new);

/// Saves account-level changes made on the settings page.
class SettingsActions {
  const SettingsActions(this._ref);
  final Ref _ref;

  Future<void> saveProfile(String first, String last, String job) async {
    final account = await guardSession(
      _ref,
      () => _ref
          .read(profileSetupRepositoryProvider)
          .saveProfile(first, last, job, null),
    );
    if (account != null) {
      _ref.read(accountSessionProvider.notifier).update(account);
    }
  }

  /// Stores the theme on my account. The server has no "system" choice, so
  /// that one stays on this phone.
  Future<void> saveTheme(ThemeMode mode) => _appearance(
    theme: switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => null,
    },
  );

  Future<void> saveLanguage(String tag) => _appearance(language: tag);

  Future<void> _appearance({String? theme, String? language}) async {
    if (theme == null && language == null) return;
    final account = await guardSession(
      _ref,
      () => _ref
          .read(settingsRepositoryProvider)
          .saveAppearance(theme: theme, language: language),
    );
    if (account != null) {
      _ref.read(accountSessionProvider.notifier).update(account);
    }
  }

  Future<void> signOut() =>
      _ref.read(accountSessionProvider.notifier).signOut();
}
