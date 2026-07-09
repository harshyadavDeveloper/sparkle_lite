import 'package:flutter/material.dart';
import 'app_theme.dart';

extension AppColorsX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get textPrimary =>
      isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

  Color get textSecondary =>
      isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

  Color get bg => isDarkMode ? AppTheme.darkBackground : AppTheme.background;

  Color get card => isDarkMode ? AppTheme.darkCard : AppTheme.surface;

  Color get border =>
      isDarkMode ? AppTheme.darkBorder : const Color(0xFFEEF0F3);

  Color get surfaceMuted =>
      isDarkMode ? AppTheme.darkSurface : AppTheme.background;
}
