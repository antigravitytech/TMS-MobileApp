import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/workspace_preview.dart';
import 'widgets/profile_avatar_picker.dart';
import 'widgets/splash_artwork.dart';

part 'business_ready_confetti.dart';

class BusinessReadyScreen extends ConsumerStatefulWidget {
  const BusinessReadyScreen({super.key});

  @override
  ConsumerState<BusinessReadyScreen> createState() =>
      _BusinessReadyScreenState();
}

class _BusinessReadyScreenState extends ConsumerState<BusinessReadyScreen>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2750),
  )..forward();

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  double _phase(int delay, int duration, [Curve curve = DesignMotion.curve]) {
    if (MediaQuery.disableAnimationsOf(context)) return 1;
    final elapsed = motion.value * 2750;
    return curve.transform(((elapsed - delay) / duration).clamp(0, 1));
  }

  Widget _rise(int delay, Widget child) => AnimatedBuilder(
    animation: motion,
    child: child,
    builder: (context, child) {
      final value = _phase(delay, 550);
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: child,
        ),
      );
    },
  );

  Widget _pop(int delay, Widget child) => AnimatedBuilder(
    animation: motion,
    child: child,
    builder: (context, child) {
      final value = _phase(delay, 500);
      final scale = value < .6
          ? .5 + .58 * value / .6
          : 1.08 - .08 * (value - .6) / .4;
      return Opacity(
        opacity: value,
        child: Transform.scale(scale: scale, child: child),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(workspacePreviewProvider);
    final due = preview.tasks
        .where(
          (task) =>
              task.group == 'Mine' &&
              task.due == 'Today' &&
              task.status != 'Completed',
        )
        .length;
    final reviews = preview.reviewQueue.length;
    final locale = context.locale.toString();
    final number = NumberFormat.decimalPattern(locale);
    final formattedTime = DateFormat.jm(
      locale,
    ).format(DateTime(2000, 1, 1, 17));
    final time = context.locale.languageCode == 'en'
        ? formattedTime.toLowerCase()
        : formattedTime;
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        minimum: const EdgeInsets.only(bottom: 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      math.max(20, 116 - MediaQuery.viewPaddingOf(context).top),
                      20,
                      20,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (!MediaQuery.disableAnimationsOf(context))
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: motion,
                                builder: (_, _) => CustomPaint(
                                  painter: _Confetti(motion.value * 2750),
                                ),
                              ),
                            ),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: _pop(
                                0,
                                Container(
                                  width: 112,
                                  height: 112,
                                  decoration: BoxDecoration(
                                    color: DesignColor.purple,
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: DesignColor.purple,
                                        blurRadius: 60,
                                        spreadRadius: -20,
                                        offset: Offset(0, 30),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: AnimatedBuilder(
                                    animation: motion,
                                    builder: (_, _) => CustomPaint(
                                      size: const Size.square(56),
                                      painter: BrandCheckPainter(
                                        _phase(300, 700, Curves.easeOut),
                                        color: DesignColor.ink,
                                        width: 2.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            _rise(
                              120,
                              Text(
                                context.tr(
                                  'business_ready.title',
                                  namedArgs: {'name': preview.firstName},
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  height: 1.12,
                                  letterSpacing: -.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _rise(
                              180,
                              Text(
                                context.tr(
                                  'business_ready.description',
                                  namedArgs: {'workspace': preview.workspace},
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  height: 1.38,
                                  color: context.profileSetupMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),
                            _rise(
                              240,
                              _ReadyList(
                                rows: [
                                  (
                                    TmsIcons.checkSquare,
                                    DesignColor.blue,
                                    context.plural(
                                      'business_ready.due',
                                      due,
                                      name: 'count',
                                    ),
                                  ),
                                  (
                                    TmsIcons.checkCircle,
                                    DesignColor.amber,
                                    context.tr(
                                      'business_ready.review',
                                      namedArgs: {
                                        'count': number.format(reviews),
                                      },
                                    ),
                                  ),
                                  (
                                    TmsIcons.edit,
                                    DesignColor.teal,
                                    context.tr(
                                      'business_ready.report',
                                      namedArgs: {'time': time},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _pop(
                    300,
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: DesignColor.purple,
                        foregroundColor: DesignColor.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      onPressed: () => TmsRoute.home.reset(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          Flexible(
                            child: Text(context.tr('business_ready.open')),
                          ),
                          const Icon(TmsIcons.arrowForward, size: 18),
                        ],
                      ),
                    ),
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

class _ReadyList extends StatelessWidget {
  const _ReadyList({required this.rows});

  final List<(IconData, Color, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.panel,
      border: Border.all(color: context.outline),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        for (final (index, (icon, accent, title)) in rows.indexed) ...[
          if (index > 0)
            Divider(height: 1, color: context.outline.withValues(alpha: .08)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .13),
                    border: Border.all(color: accent.withValues(alpha: .28)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
