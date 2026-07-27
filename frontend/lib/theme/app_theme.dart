import 'package:flutter/material.dart';

class AppTheme {
  // ── Light Mode ─ Clean, Airy, High-Contrast ────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    fontFamily: 'Segoe UI',
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0066FF),       // Vivid Blue
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1A1A1A),     // Near-black text
      surfaceContainerHigh: Color(0xFFF0F1F3),   // Input fields / cards
      surfaceContainerHighest: Color(0xFFDCDEE3), // Borders
      secondary: Color(0xFF0066FF),
      onSecondary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A1A),
      elevation: 0,
      scrolledUnderElevation: 0.5,
    ),
    dividerColor: const Color(0xFFE2E4E9),
    cardColor: Colors.white,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  // ── Dark Mode ─ Rich, Deep, Premium ────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF09090B),  // Near-black
    fontFamily: 'Segoe UI',
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),       // Bright Blue accent
      onPrimary: Colors.white,
      surface: Color(0xFF111113),       // Panels / cards
      onSurface: Color(0xFFECECEE),    // High-contrast white text
      surfaceContainerHigh: Color(0xFF18181B),  // Input fields / containers
      surfaceContainerHighest: Color(0xFF27272A), // Borders
      secondary: Color(0xFF3B82F6),
      onSecondary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111113),
      foregroundColor: Color(0xFFECECEE),
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerColor: const Color(0xFF27272A),
    cardColor: const Color(0xFF18181B),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF09090B),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
