import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../shared/animation/slide_up_entrance.dart';
import 'widgets/welcome_artwork.dart';

export 'splash_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  static const _phrases = [
    'welcome.all_in_one_place',
    'welcome.always_on_target',
    'welcome.reviewed_in_a_swipe',
    'welcome.showing_up_daily',
    'welcome.growing_together',
  ];
  late final AnimationController _orbit, _wave;
  Timer? _phraseTimer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1610),
    );
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1630),
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      _orbit.stop();
      _phraseTimer?.cancel();
      _phraseTimer = null;
    } else {
      if (!_orbit.isAnimating) _orbit.repeat();
      _phraseTimer ??= Timer.periodic(
        const Duration(milliseconds: 2600),
        (_) => setState(() => _index = (_index + 1) % _phrases.length),
      );
    }
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    _orbit.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff10111c),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.28),
          radius: .85,
          colors: [Color(0xff22243a), Color(0xff10111c), Color(0xff0b0c13)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: LayoutBuilder(
              builder: (context, bounds) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: bounds.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                          child: Row(
                            children: [
                              const WelcomeLogo(),
                              const Spacer(),
                              TextButton(
                                onPressed: () => TmsRoute.signIn.open(context),
                                child: Text(
                                  context.tr('common.sign_in'),
                                  style: const TextStyle(
                                    color: Color(0xffc9cbe0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: (bounds.maxHeight * .5).clamp(260, 420),
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_orbit, _wave]),
                            builder: (context, child) => WelcomeOrbitArtwork(
                              ms:
                                  (_orbit.lastElapsedDuration?.inMicroseconds ??
                                      0) /
                                  1000,
                              reduced: MediaQuery.disableAnimationsOf(context),
                              wave: _wave.value,
                              core: Semantics(
                                button: true,
                                label: context.tr('welcome.sabi_pipu'),
                                child: GestureDetector(
                                  onTap: () {
                                    if (!MediaQuery.disableAnimationsOf(
                                      context,
                                    )) {
                                      _wave.forward(from: 0);
                                    }
                                  },
                                  child: WelcomeMark(
                                    ms: MediaQuery.disableAnimationsOf(context)
                                        ? 2000
                                        : (_orbit
                                                      .lastElapsedDuration
                                                      ?.inMicroseconds ??
                                                  0) /
                                              1000,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SlideUpEntrance(
                          start: .25,
                          end: .80,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              children: [
                                Text(
                                  context.tr('welcome.your_teams_rhythm'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xfff3f5fe),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 34,
                                    letterSpacing: -1.2,
                                    height: 1.08,
                                  ),
                                ),
                                ClipRect(
                                  child: AnimatedSwitcher(
                                    duration: DesignMotion.duration(
                                      context,
                                      DesignMotion.object,
                                    ),
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position:
                                                Tween(
                                                  begin: const Offset(0, 1),
                                                  end: Offset.zero,
                                                ).animate(
                                                  CurvedAnimation(
                                                    parent: animation,
                                                    curve: DesignMotion.curve,
                                                  ),
                                                ),
                                            child: child,
                                          ),
                                        ),
                                    child: ShaderMask(
                                      key: ValueKey(_index),
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                            colors: [
                                              Color(0xffb3a8f2),
                                              Color(0xff5fd3c4),
                                            ],
                                          ).createShader(bounds),
                                      child: Text(
                                        context.tr(_phrases[_index]),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 34,
                                          letterSpacing: -1.1,
                                          height: 1.08,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  context.tr(
                                    'welcome.assign_review_and_celebrate_work_tasks_approvals',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xffa4a7bd),
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        SlideUpEntrance(
                          start: .35,
                          end: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(36, 20, 36, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xff9184d9,
                                        ).withValues(alpha: .35),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xfff3f5fe),
                                      foregroundColor: const Color(0xff161826),
                                      minimumSize: const Size.fromHeight(64),
                                      shape: const StadiumBorder(),
                                    ),
                                    onPressed: () =>
                                        TmsRoute.setup.open(context),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          context.tr('welcome.get_started'),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          TmsIcons.arrowForward,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () =>
                                      TmsRoute.signIn.open(context),
                                  child: Text(
                                    context.tr(
                                      'welcome.i_already_have_an_account',
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xffa4a7bd),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
