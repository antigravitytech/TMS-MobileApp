import 'package:flutter/material.dart';

extension DesignTokens on BuildContext {
  bool get dark => Theme.of(this).brightness == Brightness.dark;
  Color get background =>
      dark ? const Color(0xff161826) : const Color(0xfff4f5fb);
  Color get panel => dark ? const Color(0xff232532) : Colors.white;
  Color get raised => dark ? const Color(0xff2d2f40) : const Color(0xffeceef7);
  Color get foreground =>
      dark ? const Color(0xffe9e9ed) : const Color(0xff161826);
  Color get muted => dark ? const Color(0xffa4a7bc) : const Color(0xff5d6175);
  Color get outline => foreground.withValues(alpha: dark ? .16 : .12);
  Color get lavender =>
      dark ? const Color(0xffd2cefd) : const Color(0xff5446b0);
}

abstract final class DesignColor {
  static const purple = Color(0xff9184d9);
  static const ink = Color(0xff161826);
  static const teal = Color(0xff5fd3c4);
  static const green = Color(0xff73cc95);
  static const amber = Color(0xffeccb84);
  static const rose = Color(0xfff0a3b5);
  static const red = Color(0xfffa797d);
  static const blue = Color(0xff82c7f8);
}

abstract final class DesignMotion {
  static const curve = Cubic(.2, .8, .2, 1);
  static const fast = Duration(milliseconds: 220);
  static const page = Duration(milliseconds: 320);
  static const object = Duration(milliseconds: 450);

  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}
