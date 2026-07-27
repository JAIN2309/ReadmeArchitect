import 'package:flutter/material.dart';

class AppTheme {
  // ── Pristine Modern Light Mode (Slate Palette) ───────────────────────────
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
    fontFamily: 'Segoe UI',
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2563EB),                  // Blue 600 accent
      onPrimary: Colors.white,
      surface: Colors.white,                        // Cards, Panels, Toolbar
      onSurface: Color(0xFF0F172A),                // Slate 900 - Crisp dark text
      surfaceContainerHigh: Color(0xFFF1F5F9),      // Slate 100 - Inputs, Tabs container
      surfaceContainerHighest: Color(0xFFE2E8F0),   // Slate 200 - Borders, Dividers
      secondary: Color(0xFF2563EB),
      onSecondary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      scrolledUnderElevation: 0.5,
    ),
    dividerColor: const Color(0xFFE2E8F0),
    cardColor: Colors.white,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0xFF2563EB).withAlpha(80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  // ── Premium Dark Mode (Zinc Palette) ────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF09090B), // Zinc 950 - Deep dark
    fontFamily: 'Segoe UI',
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),                  // Blue 500 - Vibrant blue accent
      onPrimary: Colors.white,
      surface: Color(0xFF18181B),                  // Zinc 900 - Panels, Toolbar
      onSurface: Color(0xFFF4F4F5),                // Zinc 100 - Crisp white text
      surfaceContainerHigh: Color(0xFF27272A),      // Zinc 800 - Inputs, Tabs container
      surfaceContainerHighest: Color(0xFF3F3F46),   // Zinc 700 - Borders, Dividers
      secondary: Color(0xFF3B82F6),
      onSecondary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF18181B),
      foregroundColor: Color(0xFFF4F4F5),
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerColor: const Color(0xFF27272A),
    cardColor: const Color(0xFF18181B),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0xFF3B82F6).withAlpha(80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
