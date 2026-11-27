import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../router/tms_routes.dart';
import '../domain/account.dart';
import '../data/auth_repository.dart';
import '../application/account_session.dart';
import '../application/oauth_controller.dart';
import 'widgets/account_action_form.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/presentation/widgets/workspace_picker.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../application/sign_in_notifier.dart';
import 'widgets/sign_in_widgets.dart';
import 'widgets/sign_in_ready.dart';

part 'widgets/sign_in_form.dart';
part 'widgets/sign_in_demo_section.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _shown = false, _remember = true;

  bool get _busy => ref.watch(signInProvider) == SignInStatus.busy;
  late final _defaults = ref.read(authRepositoryProvider).initialCredentials;
  late final _email = TextEditingController(text: _defaults.email);
  late final _password = TextEditingController(text: _defaults.password);
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    try {
      final attempt = ref
          .read(signInProvider.notifier)
          .signIn(
            email: _email.text,
            password: _password.text,
            remember: _remember,
            delay: DesignMotion.duration(
              context,
              const Duration(milliseconds: 1100),
            ),
          );
      final result = await attempt;
      if (!mounted) return;
      if (result == SignInResult.invalidCredentials) {
        designToast(
          context,
          context.tr('onboarding.enter_an_email_address_and_password'),
        );
      }
    } on AccountFailure catch (error) {
      if (mounted) designToast(context, accountErrorMessage(context, error));
    }
  }

  Future<void> _forgotPassword() async {
    if (ref.read(environmentProvider).isLive) {
      final reset = await showAccountAction(
        context,
        AccountAction.recover,
        email: _email.text.trim(),
      );
      if (mounted && reset == true) {
        _password.clear();
        designToast(
          context,
          context.tr('authentication.password_reset_complete'),
        );
      }
    } else {
      designSheet<void>(
        context,
        title: context.tr('onboarding.forgot_password'),
        builder: (_) => DesignLabel(
          context.tr('onboarding.password_reset_is_available_when_this_app'),
        ),
      );
    }
  }

  Future<void> _social(bool microsoft) async {
    if (!ref.read(environmentProvider).isLive) {
      _showSignedIn();
      return;
    }
    try {
      await ref
          .read(oauthControllerProvider)
          .start(microsoft ? OAuthProvider.microsoft : OAuthProvider.google);
    } on AccountFailure catch (error) {
      if (mounted) designToast(context, accountErrorMessage(context, error));
    } catch (_) {
      if (mounted) designToast(context, context.tr('network.errors.unknown'));
    }
  }

  void _togglePassword() => setState(() => _shown = !_shown);
  void _toggleRemember() => setState(() => _remember = !_remember);
  void _showSignedIn() => ref.read(signInProvider.notifier).showSignedIn();

  Future<void> _demo(WorkspaceKind kind) async {
    final saved = await saveWorkspaceChange(
      context,
      () => ref.read(signInProvider.notifier).enterDemo(kind),
    );
    if (saved && mounted) TmsRoute.home.reset(context);
  }

  Future<void> _openAccount(Account account) async {
    try {
      final resume = await ref
          .read(accountSessionProvider.notifier)
          .shouldResumeOnboarding(account);
      if (mounted) {
        (resume ? TmsRoute.profileSetup : TmsRoute.account).reset(context);
      }
    } catch (_) {
      if (mounted) {
        designToast(context, context.tr('authentication.restore_failed'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(signInProvider, (_, status) {
      if (status == SignInStatus.busy) FocusScope.of(context).unfocus();
    });
    final live = ref.watch(environmentProvider).isLive;
    if (ref.watch(signInProvider) == SignInStatus.signedIn) {
      final account = ref.watch(accountSessionProvider);
      if (account != null) {
        return SignInReady(
          name: account.firstName,
          initials: [account.firstName, account.lastName]
              .where((name) => name.isNotEmpty)
              .map((name) => name.characters.first)
              .join(),
          onOpen: () => _openAccount(account),
        );
      }
      if (!live) {
        final state = ref.watch(workspacePreviewProvider);
        return SignInReady(
          name: state.firstName,
          initials:
              '${state.firstName.isEmpty ? '' : state.firstName[0]}${state.lastName.isEmpty ? '' : state.lastName[0]}',
          onOpen: () => TmsRoute.home.reset(context),
        );
      }
    }
    final tr = context.tr;
    final muted = TextStyle(
      color: context.muted,
      fontSize: 12,
      letterSpacing: 0,
    );
    final actionStyle = TextButton.styleFrom(
      foregroundColor: context.lavender,
      padding: EdgeInsets.zero,
      textStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontSize: 13.5, letterSpacing: 0),
    );
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 440;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!compact) const SignInHeader(),
                    Expanded(
                      child: AutofillGroup(
                        onDisposeAction: AutofillContextAction.cancel,
                        child: ListView(
                          padding: EdgeInsets.only(
                            top: compact ? 0 : 22,
                            bottom: 12,
                          ),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            if (compact) ...[
                              const SignInHeader(),
                              const SizedBox(height: 22),
                            ],
                            _signInForm(context, actionStyle, muted),
                            const SizedBox(height: 28),
                            if (!live) _demoSection(context, muted),
                            const SizedBox(height: 15),
                            Center(
                              child: TextButton(
                                style: actionStyle,
                                onPressed: () => TmsRoute.setup.open(context),
                                child: Text.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      letterSpacing: 0,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: tr('sign_in.new_here'),
                                        style: TextStyle(color: context.muted),
                                      ),
                                      const TextSpan(text: ' '),
                                      TextSpan(
                                        text: tr('sign_in.create_account'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
