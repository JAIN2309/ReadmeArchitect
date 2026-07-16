/// Automated README Architect — Application Entry Point
///
/// Launches the app with a unified animated [SplashScreen] that handles
/// platform detection internally, then navigates to the correct main screen.
///
/// Flow:  main() → ReadmeArchitectApp → SplashScreen → MobileScreen / DesktopScreen
library;

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReadmeArchitectApp());
}

class ReadmeArchitectApp extends StatelessWidget {
  const ReadmeArchitectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automated README Architect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorSchemeSeed: const Color(0xFF6C63FF),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
