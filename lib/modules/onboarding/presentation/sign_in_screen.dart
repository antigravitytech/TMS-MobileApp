import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/presentation/workspace_picker.dart';
import '../../workspace/presentation/workspace_ui.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _shown = false, _remember = true, _busy = false, _signedIn = false;
  final _email = TextEditingController(text: 'chioma@acmegroup.com');
  final _password = TextEditingController(text: 'preview-password');
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_busy) return;
    if (!_email.text.contains('@') || _password.text.isEmpty) {
      designToast(
        context,
        context.tr('onboarding.enter_an_email_address_and_password'),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    await Future<void>.delayed(
      DesignMotion.duration(context, const Duration(milliseconds: 850)),
    );
    if (mounted) {
      setState(() {
        _busy = false;
        _signedIn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => DesignPage(
    title: context.tr('onboarding.sabi_pipu'),
    children: [
      if (_signedIn) ...[
        const Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: DesignAvatar('CO', size: 96)),
        ),
        Text(
          context.tr('onboarding.welcome_back_chioma'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            DesignPill(context.tr('onboarding.1_due_today')),
            DesignPill(context.tr('onboarding.3_to_review')),
            DesignPill(context.tr('onboarding.its_your_birthday')),
          ],
        ),
        DesignButton(
          context.tr('onboarding.open_my_day'),
          icon: TmsIcons.arrowForward,
          onPressed: () => TmsRoute.home.reset(context),
        ),
      ] else ...[
        const SizedBox(height: 10),
        Text(
          context.tr('onboarding.welcome_back'),
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -.9,
          ),
        ),
        DesignLabel(
          context.tr('onboarding.one_sign_in_for_everyone_well_open'),
        ),
        DesignField(
          label: context.tr('onboarding.email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        DesignField(
          label: context.tr('onboarding.password'),
          controller: _password,
          obscure: !_shown,
          onSubmitted: (_) => _continue(),
          suffix: IconButton(
            tooltip: _shown
                ? context.tr('onboarding.hide_password')
                : context.tr('onboarding.show_password'),
            icon: Icon(_shown ? TmsIcons.visibilityOff : TmsIcons.visibility),
            onPressed: () => setState(() => _shown = !_shown),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _remember,
                  onChanged: (value) =>
                      setState(() => _remember = value ?? true),
                ),
                Text(context.tr('onboarding.remember_me')),
              ],
            ),
            TextButton(
              onPressed: () => designSheet<void>(
                context,
                title: context.tr('onboarding.forgot_password'),
                builder: (sheet) => DesignLabel(
                  context.tr(
                    'onboarding.password_reset_is_available_when_this_app',
                  ),
                ),
              ),
              child: Text(context.tr('onboarding.forgot_password')),
            ),
          ],
        ),
        DesignButton(
          _busy
              ? context.tr('onboarding.signing_you_in')
              : context.tr('common.sign_in'),
          onPressed: _busy ? null : _continue,
        ),
        Center(child: DesignLabel(context.tr('onboarding.or_continue_with'))),
        Row(
          spacing: 8,
          children: [
            for (final name in [
              context.tr('onboarding.microsoft'),
              context.tr('onboarding.google'),
            ])
              Expanded(
                child: DesignButton(
                  name,
                  secondary: true,
                  onPressed: () => setState(() => _signedIn = true),
                ),
              ),
          ],
        ),
        DesignTitle(context.tr('onboarding.try_a_demo')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in [
              WorkspaceKind.business,
              WorkspaceKind.individual,
              WorkspaceKind.family,
            ])
              DesignPill(
                kind.label(context),
                onTap: () async {
                  final saved = await saveWorkspaceChange(
                    context,
                    () => ref
                        .read(localWorkspacesProvider.notifier)
                        .enterDemo(kind.name),
                  );
                  if (saved && context.mounted) TmsRoute.home.reset(context);
                },
              ),
            DesignPill(
              context.tr('workspaces.specials'),
              onTap: () => showWorkspacePicker(
                context,
                ref,
                ref.read(workspacePreviewProvider).workspace,
                returnHome: true,
                specialsOnly: true,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => TmsRoute.setup.open(context),
          child: Text(
            context.tr('onboarding.new_to_sabi_pipu_create_an_account'),
          ),
        ),
      ],
    ],
  );
}
