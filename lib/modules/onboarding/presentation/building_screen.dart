import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' show Barcode, BarcodeBar;

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/presentation/workspace_ui.dart';

part 'workspace_invite.dart';

class BuildingScreen extends ConsumerStatefulWidget {
  const BuildingScreen({super.key});
  @override
  ConsumerState<BuildingScreen> createState() => _BuildingScreenState();
}

class _BuildingScreenState extends ConsumerState<BuildingScreen>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..forward();

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final space = ref.watch(localWorkspacesProvider).value?.active;
    final name = space == null
        ? context.tr('common.family')
        : workspaceName(context, space);
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final step = (animation.value * 4).floor();
                if (step == 4 || MediaQuery.disableAnimationsOf(context)) {
                  return _WorkspaceInvite(
                    name: name,
                    kind: space?.kind ?? WorkspaceKind.family,
                  );
                }
                final ms = animation.value * 3600;
                double phase(double start, double duration) => DesignMotion
                    .curve
                    .transform(((ms - start) / duration).clamp(0, 1));
                Widget rise(int delay, Widget child) {
                  final t = phase(delay.toDouble(), 550);
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - t)),
                      child: child,
                    ),
                  );
                }

                final scale = ms < 300
                    ? .5 + .58 * phase(0, 300)
                    : 1.08 - .08 * phase(300, 200);
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    math.max(20, 110 - MediaQuery.paddingOf(context).top),
                    20,
                    24,
                  ),
                  children: [
                    Center(
                      child: Opacity(
                        opacity: phase(0, 300),
                        child: Transform.scale(
                          scale: scale,
                          child: CustomPaint(
                            painter: _BuildRing(
                              step / 3,
                              animation.value * 3.6 / 14,
                              context.raised,
                              context.outline,
                            ),
                            child: SizedBox.square(
                              dimension: 150,
                              child: Center(
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: DesignColor.purple,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x779184d9),
                                        blurRadius: 40,
                                        offset: Offset(0, 20),
                                        spreadRadius: -16,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    TmsIcons.check,
                                    color: DesignColor.ink,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    rise(
                      60,
                      Text(
                        context.tr('building.title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    rise(
                      120,
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.muted),
                      ),
                    ),
                    const SizedBox(height: 30),
                    for (final (index, key) in [
                      'roles',
                      'templates',
                      'home',
                    ].indexed)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: step < index ? 0.45 : 1,
                        child: Container(
                          height: 52,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: context.panel,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.outline),
                          ),
                          child: Row(
                            spacing: 12,
                            children: [
                              SizedBox.square(
                                dimension: 26,
                                child: step == index
                                    ? const Padding(
                                        padding: EdgeInsets.all(2),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: DesignColor.purple,
                                        ),
                                      )
                                    : Icon(
                                        step > index
                                            ? TmsIcons.checkCircleFilled
                                            : TmsIcons.circle,
                                        color: step > index
                                            ? DesignColor.purple
                                            : context.muted,
                                      ),
                              ),
                              Flexible(
                                child: Text(
                                  context.tr('building.$key'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
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

class _BuildRing extends CustomPainter {
  const _BuildRing(this.progress, this.turn, this.track, this.dash);
  final double progress, turn;
  final Color track, dash;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = track;
    canvas.drawCircle(center, 68, pen);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 68),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      pen..color = DesignColor.purple,
    );
    pen
      ..color = dash
      ..strokeWidth = 2;
    for (var i = 0; i < 74; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 88),
        2 * math.pi * (i / 74 + turn),
        math.pi / 74,
        false,
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(_BuildRing old) =>
      old.progress != progress ||
      old.turn != turn ||
      old.track != track ||
      old.dash != dash;
}
