import 'package:flutter/material.dart';

extension XBorder on Widget {
  ///Add a border around the widget its called on, defaults to [AppColors.kPrimary] if not color is specified
  ///Other properties can be set includes; color, width, paddingX, paddingY, borderRadius
  Widget addPrimaryBorder({
    Color? color,
    double? width,
    double? padY,
    double? padX,
    double? borderRadius,
  }) {
    return Container(
      padding: .symmetric(horizontal: padX ?? 6, vertical: padY ?? 2),
      decoration: BoxDecoration(
        // border: Border.all(color: color ?? AppColors.kPrimary, width: width ?? 1),
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      child: this,
    );
  }

  ///Pads the widget only on the specified sides
  Widget padOnly({double? top, double? bottom, double? left, double? right}) {
    return Padding(
      padding: .only(
        top: top ?? 0,
        bottom: bottom ?? 0,
        left: left ?? 0,
        right: right ?? 0,
      ),
      child: this,
    );
  }
}
