import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';

class SignInReady extends StatelessWidget {
  const SignInReady({
    super.key,
    required this.name,
    required this.initials,
    required this.onOpen,
  });
  final String name, initials;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.25),
          radius: 1.1,
          colors: [Color(0xff36396e), Color(0xff222440), Color(0xff191a22)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: .75, end: 1),
                      duration: DesignMotion.duration(
                        context,
                        const Duration(milliseconds: 450),
                      ),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xffc4bdf6),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x559184d9),
                                  blurRadius: 48,
                                  offset: Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Text(
                              initials.toUpperCase(),
                              style: const TextStyle(
                                color: DesignColor.ink,
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: 5,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DesignColor.green,
                                border: Border.all(
                                  color: const Color(0xff222440),
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                TmsIcons.check,
                                size: 19,
                                color: DesignColor.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    context.tr('sign_in.ready_welcome'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xffc9c8df),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xfff2f1fa),
                      fontSize: 40,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in [
                        'onboarding.1_due_today',
                        'onboarding.3_to_review',
                        'onboarding.its_your_birthday',
                      ])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff383b62),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            context.tr(key),
                            style: const TextStyle(
                              color: Color(0xfff3f2ff),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  FilledButton(
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xfff4f3ff),
                      foregroundColor: DesignColor.ink,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('onboarding.open_my_day'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(TmsIcons.arrowForward, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
