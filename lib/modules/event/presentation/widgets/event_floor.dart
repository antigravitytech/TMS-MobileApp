import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit.dart';
import '../../application/event_controller.dart';

/// `.floor`: a dotted room with the stage, the entrance and the tables.
class EventFloor extends StatelessWidget {
  const EventFloor({
    super.key,
    required this.view,
    required this.targeting,
    required this.onTable,
  });
  final EventView view;
  final bool targeting;
  final ValueChanged<WorkspaceRecord> onTable;
  @override
  Widget build(BuildContext c) {
    final label = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: c.muted,
    );
    return Container(
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(color: c.outline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (_, box) => CustomPaint(
          painter: _Dots(c.foreground.withValues(alpha: .08)),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(c.tr('event.stage').toUpperCase(), style: label),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    c.tr('event.entrance').toUpperCase(),
                    style: label,
                  ),
                ),
              ),
              for (final t in view.tables)
                _Table(
                  table: t,
                  seated: view.seatedAt(t.title),
                  targeting: targeting,
                  center: Offset(
                    box.maxWidth * t.px / 100,
                    box.maxHeight * t.py / 100,
                  ),
                  onTap: () => onTable(t),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.table,
    required this.seated,
    required this.targeting,
    required this.center,
    required this.onTap,
  });
  final WorkspaceRecord table;
  final int seated;
  final bool targeting;
  final Offset center;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final long = table.fields['shape'] == 'long';
    final size = long ? const Size(130, 46) : const Size(74, 74);
    final full = seated >= table.duration;
    return Positioned(
      left: center.dx - size.width / 2,
      top: center.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: Semantics(
        button: true,
        label: table.title,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: DesignMotion.curve,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.dark ? const Color(0xff1d1f2e) : Colors.white,
              shape: long ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: long ? BorderRadius.circular(12) : null,
              border: Border.all(
                width: 2,
                color: targeting
                    ? DesignColor.purple
                    : full
                    ? KitColor.done
                    : c.foreground.withValues(alpha: .25),
              ),
              boxShadow: targeting
                  ? const [BoxShadow(color: Color(0x2e9184d9), spreadRadius: 6)]
                  : null,
            ),
            child: Text.rich(
              TextSpan(
                text: '${table.title}\n',
                children: [
                  TextSpan(
                    text: '$seated/${table.duration}',
                    style: TextStyle(color: c.muted),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends CustomPainter {
  const _Dots(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 8.0; x < size.width; x += 16) {
      for (var y = 8.0; y < size.height; y += 16) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Dots old) => old.color != color;
}
