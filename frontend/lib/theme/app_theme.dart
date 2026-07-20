import 'package:flutter/material.dart';

class AppTheme {
  // Apple-style pristine light mode
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Apple off-white
    colorSchemeSeed: const Color(0xFF5E5CE6), // Primary purple
    fontFamily: 'Segoe UI',
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF5E5CE6),
      surface: Colors.white,
      onSurface: Color(0xFF1D1D1F), // Apple dark gray
      surfaceContainerHigh: Color(0xFFE5E5EA), // Light borders/dividers
      surfaceContainerHighest: Color(0xFFD1D1D6),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1D1D1F),
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerColor: const Color(0xFFE5E5EA),
    cardColor: Colors.white,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5E5CE6),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  // Existing premium dark mode
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D0D1A),
    colorSchemeSeed: const Color(0xFF6C63FF),
    fontFamily: 'Segoe UI',
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6C63FF),
      surface: Color(0xFF14142B),
      onSurface: Colors.white,
      surfaceContainerHigh: Color(0xFF1A1A36), // Containers/panels
      surfaceContainerHighest: Color(0xFF2A2A4A), // Borders
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF14142B),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerColor: const Color(0xFF2A2A4A),
    cardColor: const Color(0xFF1A1A36),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
