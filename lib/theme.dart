import 'package:flutter/material.dart';

class AppTheme {
  // Luna palette: light -> navy blue shades
  static const Color primary = Color(0xFF0B2545); // deep navy
  static const Color primaryVariant = Color(0xFF17375A);
  static const Color primaryLight = Color(0xFFE8F0FA); // very light
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color muted = Color(0xFF6B7280); // gray-500

  static const List<Color> primaryGradient = [primaryLight, primaryVariant];

  static ThemeData themeData = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: primaryVariant,
      background: Color(0xFFF8FAFC),
      surface: surface,
      onPrimary: onPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
