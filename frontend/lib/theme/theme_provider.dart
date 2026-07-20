import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true;
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> toggleTheme() async {
    final isDark = themeModeNotifier.value == ThemeMode.dark;
    themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', !isDark);
  }
}
