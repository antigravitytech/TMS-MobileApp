part of '../sign_in_screen.dart';

extension on _SignInScreenState {
  Widget _signInForm(
    BuildContext context,
    ButtonStyle actionStyle,
    TextStyle muted,
  ) {
    final tr = context.tr;
    final environment = ref.watch(environmentProvider);
    final showSocial = !environment.isLive || environment.oauthCallback != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          DesignEntrance(
            order: 2,
            child: SignInField(
              label: tr('onboarding.email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: environment.isLive
                  ? const [AutofillHints.username, AutofillHints.email]
                  : null,
            ),
          ),
          DesignEntrance(
            order: 3,
            child: SignInField(
              label: tr('onboarding.password'),
              controller: _password,
              obscure: !_shown,
              autofillHints: environment.isLive
                  ? const [AutofillHints.password]
                  : null,
              onSubmitted: (_) => _continue(),
              suffix: IconButton(
                tooltip: tr(
                  _shown
                      ? 'onboarding.hide_password'
                      : 'onboarding.show_password',
                ),
                icon: Icon(
                  _shown ? TmsIcons.visibilityOff : TmsIcons.visibility,
                  size: 20,
                ),
                onPressed: _togglePassword,
              ),
            ),
          ),
          DesignEntrance(
            order: 3,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semantics(
                  checked: _remember,
                  child: InkWell(
                    onTap: _toggleRemember,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 10,
                        children: [
                          AnimatedContainer(
                            duration: DesignMotion.duration(
                              context,
                              DesignMotion.fast,
                            ),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _remember
                                  ? DesignColor.purple
                                  : context.panel,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: _remember
                                    ? DesignColor.purple
                                    : context.outline,
                              ),
                            ),
                            child: _remember
                                ? const Icon(
                                    TmsIcons.check,
                                    color: DesignColor.ink,
                                    size: 16,
                                  )
                                : null,
                          ),
                          Text(
                            tr('onboarding.remember_me'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                TextButton(
                  style: actionStyle,
                  onPressed: _forgotPassword,
                  child: Text(tr('onboarding.forgot_password')),
                ),
              ],
            ),
          ),
          DesignEntrance(
            order: 4,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 52),
                backgroundColor: DesignColor.purple,
                foregroundColor: DesignColor.ink,
                disabledBackgroundColor: DesignColor.purple,
                disabledForegroundColor: DesignColor.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: _busy ? null : _continue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  if (_busy)
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: DesignColor.ink,
                        backgroundColor: Color(0x40161826),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      tr(
                        _busy ? 'onboarding.signing_you_in' : 'common.sign_in',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showSocial)
            DesignEntrance(
              order: 4,
              child: Row(
                spacing: 12,
                children: [
                  Expanded(child: Divider(color: context.outline)),
                  Text(tr('onboarding.or_continue_with'), style: muted),
                  Expanded(child: Divider(color: context.outline)),
                ],
              ),
            ),
          if (showSocial)
            DesignEntrance(
              order: 5,
              child: Row(
                spacing: 10,
                children: [
                  for (final microsoft in [true, false])
                    Expanded(
                      child: ProviderSignInButton(
                        microsoft: microsoft,
                        onPressed: _busy ? null : () => _social(microsoft),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
