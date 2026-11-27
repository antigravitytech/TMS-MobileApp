part of '../task_forms.dart';

class _TaskConfirmation extends StatelessWidget {
  const _TaskConfirmation({
    required this.id,
    required this.person,
    required this.due,
    required this.onAgain,
  });
  final String id, person, due;
  final VoidCallback onAgain;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: ColoredBox(
        color: context.background.withValues(alpha: .95),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: .5, end: 1),
                        duration: DesignMotion.duration(
                          context,
                          const Duration(milliseconds: 450),
                        ),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) =>
                            Transform.scale(scale: value, child: child),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: DesignColor.purple,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x809184d9),
                                offset: Offset(0, 30),
                                blurRadius: 60,
                                spreadRadius: -20,
                              ),
                            ],
                          ),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: DesignMotion.duration(
                              context,
                              const Duration(milliseconds: 850),
                            ),
                            builder: (context, value, _) => CustomPaint(
                              painter: _CreatedCheck(
                                ((value - .29) / .71).clamp(0, 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      context.tr('tasks.task_created'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        'tasks.created_notice',
                        namedArgs: {'person': person, 'id': id, 'due': due},
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.muted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    DesignButton(
                      context.tr('tasks.view_task'),
                      onPressed: () => TmsRoute.task.open(context),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onAgain,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        foregroundColor: context.foreground,
                        side: BorderSide(color: context.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        context.tr('tasks.create_another'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => TmsRoute.tasks.open(context),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        foregroundColor: context.muted,
                      ),
                      child: Text(
                        context.tr('common.done'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
  );
}

class _CreatedCheck extends CustomPainter {
  const _CreatedCheck(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(33, 48)
      ..lineTo(43, 58)
      ..lineTo(61, 36);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = DesignColor.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CreatedCheck oldDelegate) =>
      oldDelegate.progress != progress;
}
