import 'package:flutter/material.dart';

import '../design/design_tokens.dart';

/// Slides its child upward into place once, keeping it visible throughout.
class SlideUpEntrance extends StatefulWidget {
  const SlideUpEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1350),
    this.start = 0,
    this.end = 1,
    this.distance = 22,
  }) : assert(start >= 0 && start < end && end <= 1);

  final Widget child;
  final Duration duration;
  final double start;
  final double end;
  final double distance;

  @override
  State<SlideUpEntrance> createState() => _SlideUpEntranceState();
}

class _SlideUpEntranceState extends State<SlideUpEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _controller.value = 1;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SlideUpEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final progress = Interval(
        widget.start,
        widget.end,
        curve: DesignMotion.curve,
      ).transform(_controller.value);
      return Transform.translate(
        offset: Offset(0, widget.distance * (1 - progress)),
        child: child,
      );
    },
  );
}
