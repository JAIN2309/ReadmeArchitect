import 'package:flutter/material.dart';

class AppTheme {
  // Sleek Pristine Light Mode
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    colorSchemeSeed: const Color(0xFF0070F3), // Vibrant Blue
    fontFamily: 'Segoe UI',
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0070F3),
      surface: Colors.white,
      onSurface: Color(0xFF111111),
      surfaceContainerHigh: Color(0xFFF2F2F2),
      surfaceContainerHighest: Color(0xFFE5E5E5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF111111),
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerColor: const Color(0xFFE5E5E5),
    cardColor: Colors.white,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0070F3),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  // Sleek Premium Dark Mode
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000), // Pure Black
    colorSchemeSeed: const Color(0xFF0A84FF), // Bright Accent Blue
    fontFamily: 'Segoe UI',
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF0A84FF),
      surface: Color(0xFF0A0A0A), // Almost black
      onSurface: Color(0xFFF5F5F5), // Off-white
      surfaceContainerHigh: Color(0xFF111111), // Containers
      surfaceContainerHighest: Color(0xFF222222), // Borders
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0A0A),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerColor: const Color(0xFF222222),
    cardColor: const Color(0xFF111111),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0A84FF),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
