import 'package:flutter/material.dart';

class AppDimensions {
  static const double _k4 = 4;
  static const double _k8 = 8;
  static const double _k12 = 12;
  static const double _k20 = 20;
  static const double _k24 = 24;

  static const double kTinySpacing = _k4;
  static const double kSmallSpacing = _k8;
  static const double kWidgetSpacing = _k12;
  static const double kLargeSpacing = _k20;

  // App padding
  static const double _kScaffoldPadding = 14;

  /// The default padding for the scaffold body.
  static EdgeInsets kScaffoldBodyPadding = const EdgeInsets.all(_kScaffoldPadding);
  static EdgeInsets kCardPadding = const EdgeInsets.all(_k12);

  static BorderRadius kDefaultBorderRadius = BorderRadius.circular(_k12);
  static BorderRadius kCircularBorderRadius = BorderRadius.circular(_k24);
}
