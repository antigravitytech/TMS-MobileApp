import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../domain/local_workspace.dart';

/// A zoomable floor with movable tables. Positions use floor coordinates so
/// rotating the phone never changes the seating arrangement.
class WorkspaceFloorPlan extends StatefulWidget {
  const WorkspaceFloorPlan({
    super.key,
    required this.tables,
    required this.guests,
    required this.onMove,
    required this.onSelect,
  });
  final Map<String, WorkspaceRecord> tables;
  final Map<String, List<WorkspaceRecord>> guests;
  final Future<void> Function(WorkspaceRecord, Offset) onMove;
  final ValueChanged<String> onSelect;
  @override
  State<WorkspaceFloorPlan> createState() => _WorkspaceFloorPlanState();
}

class _WorkspaceFloorPlanState extends State<WorkspaceFloorPlan> {
  final zoom = TransformationController();
  final dragging = <String, Offset>{};
  @override
  void dispose() {
    zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = {
      ...widget.tables.keys,
      ...widget.guests.keys.where((t) => t.isNotEmpty),
    }.toList();
    final height = math.max(260.0, 65.0 + 116 * ((names.length + 1) ~/ 2));
    return DesignCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 300,
        child: InteractiveViewer(
          constrained: false,
          transformationController: zoom,
          minScale: .65,
          maxScale: 2.5,
          child: SizedBox(
            width: 360,
            height: height,
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 90,
                  right: 90,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.raised,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Center(
                        child: DesignLabel(context.tr('workspaces.stage')),
                      ),
                    ),
                  ),
                ),
                for (final (i, name) in names.indexed)
                  Builder(
                    builder: (context) {
                      final table = widget.tables[name],
                          party = widget.guests[name] ?? [];
                      final used = party.fold(0, (n, r) => n + r.duration);
                      final pos =
                          dragging[name] ??
                          Offset(
                            double.tryParse(table?.fields['x'] ?? '') ??
                                18 + 175.0 * (i % 2),
                            double.tryParse(table?.fields['y'] ?? '') ??
                                55 + 116.0 * (i ~/ 2),
                          );
                      final left = pos.dx.clamp(0.0, 230.0),
                          top = pos.dy.clamp(44.0, height - 95);
                      final seats = table?.duration ?? used;
                      final label = context.tr(
                        'workspaces.table_name',
                        namedArgs: {'table': name},
                      );
                      return Positioned(
                        left: left,
                        top: top,
                        width: 126,
                        child: Semantics(
                          button: true,
                          label: label,
                          child: GestureDetector(
                            onTap: () => widget.onSelect(name),
                            onPanUpdate: table == null
                                ? null
                                : (d) => setState(
                                    () => dragging[name] = Offset(
                                      (left + d.delta.dx).clamp(0.0, 230.0),
                                      (top + d.delta.dy).clamp(
                                        44.0,
                                        height - 95,
                                      ),
                                    ),
                                  ),
                            onPanEnd: table == null
                                ? null
                                : (_) async {
                                    final p = dragging[name];
                                    if (p == null) return;
                                    await widget.onMove(table, p);
                                    if (mounted) {
                                      setState(() => dragging.remove(name));
                                    }
                                  },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    for (var j = 0; j < math.min(seats, 8); j++)
                                      Icon(
                                        TmsIcons.circle,
                                        size: 9,
                                        color: j < used
                                            ? context.lavender
                                            : context.muted,
                                      ),
                                  ],
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.raised,
                                    border: Border.all(color: context.outline),
                                    borderRadius: BorderRadius.circular(
                                      table?.fields['shape'] == 'long'
                                          ? 10
                                          : 30,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        name,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        context.tr(
                                          'workspaces.seats_used',
                                          namedArgs: {
                                            'used': NumberFormat.decimalPattern(
                                              context.locale.toString(),
                                            ).format(used),
                                            'total':
                                                NumberFormat.decimalPattern(
                                                  context.locale.toString(),
                                                ).format(seats),
                                          },
                                        ),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
