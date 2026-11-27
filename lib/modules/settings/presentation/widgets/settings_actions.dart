part of '../settings_screen.dart';

extension on _SettingsScreenState {
  Future<void> _language(BuildContext context) async {
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
    }
  }

  Future<void> _edit(BuildContext context, WorkspacePreview state) async {
    var first = state.firstName, last = state.lastName, job = state.jobTitle;
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
    if (saved == true) state.saveProfile(first, last, job);
  }
}
