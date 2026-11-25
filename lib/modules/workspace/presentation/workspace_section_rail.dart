import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../domain/workspace_kind.dart';
import 'workspace_ui.dart';

class WorkspaceSectionRail extends StatefulWidget {
  const WorkspaceSectionRail({
    super.key,
    required this.sections,
    required this.selected,
    required this.onChanged,
  });
  final List<WorkspaceSection> sections;
  final WorkspaceSection selected;
  final ValueChanged<WorkspaceSection> onChanged;
  @override
  State<WorkspaceSectionRail> createState() => _WorkspaceSectionRailState();
}

class _WorkspaceSectionRailState extends State<WorkspaceSectionRail> {
  final selectedKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    _reveal();
  }

  @override
  void didUpdateWidget(WorkspaceSectionRail old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _reveal();
  }

  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    final chip = selectedKey.currentContext;
    if (chip == null || !mounted) return;
    Scrollable.of(chip, axis: Axis.horizontal).position.ensureVisible(
      chip.findRenderObject()!,
      alignment: .4,
      duration: DesignMotion.duration(context, DesignMotion.fast),
      curve: DesignMotion.curve,
    );
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      spacing: 8,
      children: [
        for (final section in widget.sections)
          KeyedSubtree(
            key: section == widget.selected ? selectedKey : ValueKey(section),
            child: DesignPill(
              section.label(context),
              selected: section == widget.selected,
              icon: section.icon,
              onTap: () => widget.onChanged(section),
            ),
          ),
      ],
    ),
  );
}

class WorkspaceContentTransition extends StatelessWidget {
  const WorkspaceContentTransition({
    super.key,
    required this.identity,
    required this.child,
  });
  final Object identity;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(identity),
    tween: Tween(begin: 0, end: 1),
    duration: DesignMotion.duration(context, DesignMotion.object),
    curve: DesignMotion.curve,
    child: child,
    builder: (_, v, child) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset((1 - v) * 30, 0), child: child),
    ),
  );
}

/// The mobile selection glyph contracts, tilts, then settles into place.
class WorkspaceSelectionIcon extends StatelessWidget {
  const WorkspaceSelectionIcon({
    super.key,
    required this.icon,
    required this.color,
  });
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: DesignMotion.duration(context, DesignMotion.object),
    child: Icon(icon, color: color),
    builder: (_, v, child) => Transform.rotate(
      angle: .09 * math.sin(v * 2 * math.pi) * (1 - v),
      child: Transform.scale(
        scale: 1 - .18 * math.sin(v * 2 * math.pi) * (1 - v),
        child: child,
      ),
    ),
  );
}
