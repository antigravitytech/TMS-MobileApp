part of '../settings_screen.dart';

extension on _SettingsScreenState {
  SettingsActions get _actions => ref.read(settingsActionsProvider);

  String _error(BuildContext context, Object error) => error is AccountFailure
      ? error.type.localizedMessage(context)
      : context.tr('network.errors.unknown');

  /// Runs a save and shows why it failed, if it did.
  Future<void> _save(BuildContext context, Future<void> Function() save) async {
    try {
      await save();
    } catch (error) {
      if (context.mounted) designToast(context, _error(context, error));
    }
  }

  void _notice(BuildContext context, String key, bool on) => _save(
    context,
    () => ref.read(settingsNoticesProvider.notifier).toggle(key, on),
  );

  void _theme(BuildContext context, ThemeMode mode, bool live) {
    ref.read(workspacePreviewProvider).setTheme(mode);
    if (live) _save(context, () => _actions.saveTheme(mode));
  }

  Future<void> _signOut(BuildContext context) async {
    await _save(context, _actions.signOut);
    if (context.mounted) TmsRoute.welcome.reset(context);
  }

  /// Email and password changes; they need the server, so the preview only
  /// explains that.
  Future<void> _security(BuildContext context, bool live) async {
    if (!live) {
      return designSheet<void>(
        context,
        title: context.tr('settings.password_email'),
        builder: (_) => DesignLabel(
          context.tr('settings.changes_are_available_when_this_app_is'),
        ),
      );
    }
    final action = await designSheet<AccountAction>(
      context,
      title: context.tr('settings.password_email'),
      builder: (sheet) => Column(
        children: [
          for (final option in [
            AccountAction.requestEmailChange,
            AccountAction.changePassword,
          ])
            DesignTile(
              title: sheet.tr('authentication.action.${option.name}'),
              onTap: () => Navigator.pop(sheet, option),
            ),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    final done = await showAccountAction(context, action);
    if (done != true || !context.mounted) return;
    if (action == AccountAction.changePassword) {
      designToast(context, context.tr('settings.password_changed'));
      TmsRoute.welcome.reset(context);
    } else {
      designToast(context, context.tr('settings.email_change_sent'));
    }
  }

  Future<void> _language(BuildContext context, bool live) async {
    final locale = await designSheet<Locale>(
      context,
      title: context.tr('settings.language'),
      builder: (sheet) => Column(
        children: [
          for (final option in sheet.supportedLocales)
            DesignTile(
              title: sheet.tr('locales.${option.toLanguageTag()}'),
              trailing: option == sheet.locale
                  ? const Icon(TmsIcons.check)
                  : null,
              onTap: () => Navigator.pop(sheet, option),
            ),
        ],
      ),
    );
    if (context.mounted && locale != null) {
      await context.setLocale(locale);
      if (live && context.mounted) {
        await _save(
          context,
          () => _actions.saveLanguage(locale.toLanguageTag()),
        );
      }
    }
  }

  Future<void> _edit(
    BuildContext context,
    WorkspacePreview state,
    Account? account,
  ) async {
    var first = account?.firstName ?? state.firstName,
        last = account?.lastName ?? state.lastName,
        job = account?.jobTitle ?? state.jobTitle;
    final saved = await designSheet<bool>(
      context,
      title: context.tr('common.edit_profile'),
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 11,
        children: [
          DesignField(
            label: context.tr('common.first_name'),
            initialValue: first,
            onChanged: (v) => first = v,
          ),
          DesignField(
            label: context.tr('common.last_name'),
            initialValue: last,
            onChanged: (v) => last = v,
          ),
          DesignField(
            label: context.tr('common.job_title'),
            initialValue: job,
            onChanged: (v) => job = v,
          ),
          DesignButton(
            context.tr('common.save_profile'),
            onPressed: () => Navigator.pop(sheet, true),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      await _save(context, () => _actions.saveProfile(first, last, job));
    }
  }
}
