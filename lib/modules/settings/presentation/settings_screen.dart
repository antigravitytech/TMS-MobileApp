import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final notices = <String, bool>{
    'settings.push_notifications': true,
    'settings.reviews_mentions': true,
    'settings.daily_report_reminder': true,
    'settings.quiet_hours': true,
    'settings.sounds_vibration': false,
  };
  bool face = true;
  static const modes = [ThemeMode.dark, ThemeMode.light, ThemeMode.system];
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspacePreviewProvider);
    return DesignPage(
      title: context.tr('common.settings'),
      children: [
        DesignTitle(context.tr('settings.account')),
        DesignSection(
          children: [
            DesignTile(
              title: context.tr('common.profile'),
              subtitle: context.tr('settings.name_photo_job_title_department'),
              leading: const DesignAvatar('CO'),
              onTap: () => TmsRoute.profile.open(context),
            ),
            DesignTile(
              title: context.tr('settings.password_email'),
              subtitle: 'chioma@acmegroup.com',
              icon: TmsIcons.lock,
              onTap: () => designSheet<void>(
                context,
                title: context.tr('settings.password_email'),
                builder: (_) => DesignLabel(
                  context.tr('settings.changes_are_available_when_this_app_is'),
                ),
              ),
            ),
            DesignTile(
              title: context.tr('common.birthday'),
              subtitle: context.tr(
                'settings.23_november_colleagues_see_day_and_month',
              ),
              icon: TmsIcons.birthday,
              onTap: () => TmsRoute.profileSetup.open(context),
            ),
          ],
        ),
        DesignTitle(context.tr('common.notifications')),
        DesignSection(
          children: [
            for (final item in notices.entries)
              SwitchListTile(
                title: Text(context.tr(item.key)),
                value: item.value,
                onChanged: (value) => setState(() => notices[item.key] = value),
              ),
          ],
        ),
        DesignTitle(context.tr('settings.appearance')),
        DesignChoices(
          items: [
            context.tr('settings.dark'),
            context.tr('settings.light'),
            context.tr('settings.system'),
          ],
          selected: modes.indexOf(state.theme),
          onChanged: (i) => state.setTheme(modes[i]),
        ),
        DesignSection(
          children: [
            DesignTile(
              title: context.tr('settings.language'),
              subtitle: context.tr('locales.${context.locale.toLanguageTag()}'),
              onTap: context.supportedLocales.length > 1
                  ? () async {
                      final locale = await designSheet<Locale>(
                        context,
                        title: context.tr('settings.language'),
                        builder: (sheet) => Column(
                          children: [
                            for (final option in sheet.supportedLocales)
                              DesignTile(
                                title: sheet.tr(
                                  'locales.${option.toLanguageTag()}',
                                ),
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
                  : null,
              icon: TmsIcons.language,
            ),
            SwitchListTile(
              title: Text(context.tr('settings.unlock_with_face_id')),
              subtitle: DesignLabel(context.tr('settings.preview_preference')),
              value: face,
              onChanged: (value) => setState(() => face = value),
            ),
          ],
        ),
        DesignButton(
          context.tr('common.sign_out'),
          secondary: true,
          color: context.raised,
          icon: TmsIcons.logout,
          onPressed: () => TmsRoute.welcome.reset(context),
        ),
        Center(
          child: DesignLabel(
            context.tr(
              'settings.sabi_pipu_tms_workspace',
              namedArgs: {'workspace': state.workspace},
            ),
          ),
        ),
      ],
    );
  }
}
