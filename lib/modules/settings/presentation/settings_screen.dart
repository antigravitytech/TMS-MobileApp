import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../core/config/environment.dart';
import '../../../l10n/network_failure_localization.dart';
import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../../authentication/presentation/widgets/account_action_form.dart';
import '../../home/application/live_home.dart';
import '../../workspace/application/workspace_preview.dart';
import '../application/settings_controller.dart';
import '../data/settings_repository.dart';

part 'widgets/settings_rows.dart';
part 'widgets/settings_actions.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool face = true;
  static const modes = [ThemeMode.dark, ThemeMode.light, ThemeMode.system];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspacePreviewProvider);
    final live = ref.watch(environmentProvider).isLive;
    final account = live ? ref.watch(accountSessionProvider) : null;
    final notices = ref.watch(settingsNoticesProvider).value;
    final birthday = live ? account?.birthday : DateTime(2000, 11, 23);
    final initials =
        [
              account?.firstName ?? state.firstName,
              account?.lastName ?? state.lastName,
            ]
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
                            onTap: () => _edit(context, state, account),
                          ),
                          _SettingsRow(
                            title: context.tr('settings.password_email'),
                            detail: account?.email ?? 'chioma@acmegroup.com',
                            leading: _SettingsIcon(
                              TmsIcons.lock,
                              context.lavender,
                            ),
                            onTap: () => _security(context, live),
                          ),
                          _SettingsRow(
                            title: context.tr('common.birthday'),
                            detail: birthday == null
                                ? context.tr('settings.birthday_not_set')
                                : context.tr(
                                    account?.birthdayVisible ?? true
                                        ? 'settings.birthday_detail'
                                        : 'settings.birthday_private',
                                    namedArgs: {
                                      'date': DateFormat(
                                        'd MMMM',
                                        context.locale.toString(),
                                      ).format(birthday),
                                    },
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
                          for (final key in settingsNotices)
                            _SettingsRow(
                              title: context.tr('settings.$key'),
                              detail: context.tr(
                                'settings.notification_details.$key',
                              ),
                              trailing: _SettingsToggle(
                                label: context.tr('settings.$key'),
                                value: notices?[key] ?? false,
                                onChanged: (value) {
                                  if (notices != null) {
                                    _notice(context, key, value);
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _SettingsHeading(context.tr('settings.appearance')),
                      _ThemeSegments(
                        mode: state.theme,
                        select: (mode) => _theme(context, mode, live),
                      ),
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
                            onTap: () => _language(context, live),
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
                        onPressed: () => _signOut(context),
                        child: Text(context.tr('common.sign_out')),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: DesignLabel(
                          context.tr(
                            'settings.sabi_pipu_tms_workspace',
                            namedArgs: {
                              'workspace': live
                                  ? ref
                                            .watch(activeLiveWorkspaceProvider)
                                            ?.name ??
                                        ''
                                  : state.workspace,
                            },
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
