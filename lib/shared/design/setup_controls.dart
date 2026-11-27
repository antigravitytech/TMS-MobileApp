import 'package:flutter/material.dart';

import 'design_tokens.dart';

TextStyle setupLabel(BuildContext context) => TextStyle(
  fontSize: 13,
  height: 1.4,
  color: context.muted,
  fontWeight: FontWeight.w500,
);

class SetupIconTile extends StatelessWidget {
  const SetupIconTile(this.icon, this.color, {this.size = 44, super.key});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      border: Border.all(color: color.withValues(alpha: .25)),
      borderRadius: BorderRadius.circular(size / 3),
    ),
    child: Icon(icon, color: color, size: size * .5),
  );
}
