import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/workspace_preview.dart';

part 'widgets/settings_rows.dart';
part 'widgets/settings_actions.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const sections = [
    'push_notifications',
    'reviews_mentions',
    'daily_report_reminder',
    'quiet_hours',
    'sounds_vibration',
  ];
  final notices = [true, true, true, true, false];
  bool face = true;
  static const modes = [ThemeMode.dark, ThemeMode.light, ThemeMode.system];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspacePreviewProvider);
    final initials = [state.firstName, state.lastName]
        .where((name) => name.isNotEmpty)
        .map((name) => name.characters.first.toUpperCase())
        .join();
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    spacing: 10,
                    children: [
                      DesignIcon(
                        icon: TmsIcons.chevronBack,
                        label: context.tr('common.back'),
                        onPressed: () async {
                          if (!await context.router.maybePop() &&
                              context.mounted) {
                            TmsRoute.more.reset(context);
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          context.tr('common.settings'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    children: [
                      _SettingsHeading(context.tr('settings.account')),
                      _SettingsGroup(
                        children: [
                          _SettingsRow(
                            title: context.tr('common.profile'),
                            detail: context.tr(
                              'settings.name_photo_job_title_department',
                            ),
                            leading: DesignAvatar(
                              initials,
                              size: 36,
                              color: const Color(0xffc4bdf6),
                            ),
                            onTap: () => _edit(context, state),
                          ),
                          _SettingsRow(
                            title: context.tr('settings.password_email'),
                            detail: 'chioma@acmegroup.com',
                            leading: _SettingsIcon(
                              TmsIcons.lock,
                              context.lavender,
                            ),
                            onTap: () => designSheet<void>(
                              context,
                              title: context.tr('settings.password_email'),
                              builder: (_) => DesignLabel(
                                context.tr(
                                  'settings.changes_are_available_when_this_app_is',
                                ),
                              ),
                            ),
                          ),
                          _SettingsRow(
                            title: context.tr('common.birthday'),
                            detail: context.tr(
                              'settings.23_november_colleagues_see_day_and_month',
                            ),
                            leading: const _SettingsIcon(
                              TmsIcons.birthday,
                              DesignColor.red,
                            ),
                            onTap: () => TmsRoute.profileSetup.open(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _SettingsHeading(context.tr('common.notifications')),
                      _SettingsGroup(
                        children: [
                          for (final (index, key) in sections.indexed)
                            _SettingsRow(
                              title: context.tr('settings.$key'),
                              detail: context.tr(
                                'settings.notification_details.$key',
                              ),
                              trailing: _SettingsToggle(
                                label: context.tr('settings.$key'),
                                value: notices[index],
                                onChanged: (value) =>
                                    setState(() => notices[index] = value),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _SettingsHeading(context.tr('settings.appearance')),
                      _ThemeSegments(mode: state.theme, select: state.setTheme),
                      const SizedBox(height: 10),
                      _SettingsGroup(
                        children: [
                          _SettingsRow(
                            title: context.tr('settings.language'),
                            leading: const _SettingsIcon(
                              TmsIcons.language,
                              DesignColor.blue,
                            ),
                            trailing: DesignLabel(
                              context.tr(
                                'locales.${context.locale.toLanguageTag()}',
                              ),
                            ),
                            onTap: () => _language(context),
                          ),
                          _SettingsRow(
                            title: context.tr('settings.unlock_with_face_id'),
                            leading: const _SettingsIcon(
                              TmsIcons.faceScan,
                              DesignColor.teal,
                            ),
                            trailing: _SettingsToggle(
                              label: context.tr('settings.unlock_with_face_id'),
                              value: face,
                              onChanged: (value) =>
                                  setState(() => face = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DesignColor.red,
                          side: BorderSide(color: context.outline),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => TmsRoute.welcome.reset(context),
                        child: Text(context.tr('common.sign_out')),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: DesignLabel(
                          context.tr(
                            'settings.sabi_pipu_tms_workspace',
                            namedArgs: {'workspace': state.workspace},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
