import 'package:flutter/material.dart';

abstract final class TmsTheme {
  static final light = ThemeData(
    fontFamily: 'Inter',
    scaffoldBackgroundColor: const Color(0xFFF4F5FB),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6658C0),
      primary: const Color(0xFF6658C0),
      onPrimary: Colors.white,
      surface: const Color(0xFFF3F4F9),
      onSurface: const Color(0xFF1C1E2A),
    ),
  );

  static final dark = ThemeData(
    fontFamily: 'Inter',
    scaffoldBackgroundColor: const Color(0xFF161826),
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: const Color(0xFF9184D9),
      primary: const Color(0xFF9184D9),
      onPrimary: const Color(0xFF161826),
      surface: const Color(0xFF161826),
      onSurface: const Color(0xFFE9E9ED),
    ),
  );
}
