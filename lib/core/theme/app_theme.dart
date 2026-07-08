import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2E7D8C);
  static const Color primaryLight = Color(0xFF4EAAB8);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2B3C);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF66BB6A);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF0F1923);
  static const Color darkSurface = Color(0xFF1A2535);
  static const Color darkCard = Color(0xFF1E2D40);
  static const Color darkBorder = Color(0xFF2A3A4F);
  static const Color darkTextPrimary = Color(0xFFE8EDF2);
  static const Color darkTextSecondary = Color(0xFF8A9BB0);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      surface: surface,
      error: error,
    ),
    scaffoldBackgroundColor: background,
    cardColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? primary : Colors.grey,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? primary.withValues(alpha: 0.4)
            : Colors.grey.withValues(alpha: 0.3),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: primary.withValues(alpha: 0.15),
      labelStyle: const TextStyle(color: textPrimary),
    ),
    dividerColor: const Color(0xFFEEF0F3),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: darkSurface,
      error: error,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCard,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        side: const BorderSide(color: primaryLight),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      labelStyle: const TextStyle(color: darkTextSecondary),
      hintStyle: const TextStyle(color: darkTextSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? primaryLight : Colors.grey,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? primaryLight.withValues(alpha: 0.4)
            : Colors.grey.withValues(alpha: 0.3),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkCard,
      selectedColor: primary.withValues(alpha: 0.3),
      labelStyle: const TextStyle(color: darkTextPrimary),
    ),
    dividerColor: darkBorder,
    listTileTheme: const ListTileThemeData(
      iconColor: darkTextSecondary,
      textColor: darkTextPrimary,
    ),
  );
}
