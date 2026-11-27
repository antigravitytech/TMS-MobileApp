import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../../shared/design/setup_controls.dart';
import '../../../../shared/design/hero_gradient.dart';

class SignInHeader extends StatelessWidget {
  const SignInHeader({super.key});
  @override
  Widget build(BuildContext context) {
    const wordmark = TextStyle(
      color: Color(0xfff3f5fe),
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: -.6,
    );
    return CustomPaint(
      painter: const DesignHeroGradient(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: context.tr('onboarding.sabi_pipu'),
              excludeSemantics: true,
              child: Row(
                spacing: 4,
                children: [
                  Text(context.tr('sign_in.brand_start'), style: wordmark),
                  const Icon(
                    TmsIcons.check,
                    size: 22,
                    color: Color(0xff2bb3a3),
                  ),
                  Text(context.tr('sign_in.brand_end'), style: wordmark),
                ],
              ),
            ),
            const SizedBox(height: 26),
            DesignEntrance(
              child: Text(
                context.tr('onboarding.welcome_back'),
                style: const TextStyle(
                  color: Color(0xfff3f5fe),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                  letterSpacing: -.7,
                ),
              ),
            ),
            const SizedBox(height: 6),
            DesignEntrance(
              order: 1,
              child: Text(
                context.tr('onboarding.one_sign_in_for_everyone_well_open'),
                style: const TextStyle(
                  color: Color(0xffc9cbe0),
                  fontSize: 15,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignInField extends StatelessWidget {
  const SignInField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.onSubmitted,
    this.autofillHints,
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: context.outline),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: setupLabel(context)),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            onFieldSubmitted: onSubmitted,
            autofillHints: autofillHints,
            textInputAction: onSubmitted == null
                ? TextInputAction.next
                : TextInputAction.done,
            style: const TextStyle(fontSize: 16, letterSpacing: 0),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: context.panel,
              constraints: const BoxConstraints(minHeight: 54),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: const BorderSide(color: DesignColor.purple),
              ),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}

class ProviderSignInButton extends StatelessWidget {
  const ProviderSignInButton({
    super.key,
    required this.onPressed,
    required this.microsoft,
  });
  final VoidCallback? onPressed;
  final bool microsoft;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: context.foreground,
      side: BorderSide(color: context.outline),
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        ExcludeSemantics(
          child: microsoft
              ? const SizedBox.square(
                  dimension: 16,
                  child: Column(
                    spacing: 2,
                    children: [
                      Row(
                        spacing: 2,
                        children: [
                          _MicrosoftSquare(Color(0xfff25022)),
                          _MicrosoftSquare(Color(0xff7fba00)),
                        ],
                      ),
                      Row(
                        spacing: 2,
                        children: [
                          _MicrosoftSquare(Color(0xff00a4ef)),
                          _MicrosoftSquare(Color(0xffffb900)),
                        ],
                      ),
                    ],
                  ),
                )
              : const Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xff8ab4f8),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        Flexible(
          child: Text(
            context.tr(
              microsoft ? 'onboarding.microsoft' : 'onboarding.google',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

class _MicrosoftSquare extends StatelessWidget {
  const _MicrosoftSquare(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: 7, child: ColoredBox(color: color));
}

class SignInDemoCard extends StatelessWidget {
  const SignInDemoCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 92,
    child: Material(
      color: context.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            spacing: 8,
            children: [
              SetupIconTile(icon, color),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
