import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  //Theme Data
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  ThemeData get theme => Theme.of(this);
  bool get isDarkMode => theme.brightness == Brightness.dark;

  //Color
  // Color get greyTextColor => isDarkMode ? AppColors.kGreyTextDark : AppColors.kGreyTextLight;
  BoxShadow get lightCardShadow =>
      BoxShadow(color: theme.shadowColor, blurRadius: 12, offset: Offset(0, 4));
  BoxShadow get softShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 24,
    offset: const Offset(0, 16),
  );

  //MediaQuery
  double screenWidth([double widthFactor = 1]) =>
      MediaQuery.sizeOf(this).width * widthFactor;
  double screenHeight([double heightFactor = 1]) =>
      MediaQuery.sizeOf(this).height * heightFactor;

  void unfocus() => FocusScope.of(this).unfocus();
}
