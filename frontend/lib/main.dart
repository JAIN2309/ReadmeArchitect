/// Automated README Architect — Application Entry Point
///
/// Launches the app with a unified animated [SplashScreen] that handles
/// platform detection internally, then navigates to the correct main screen.
///
/// Flow:  main() → ReadmeArchitectApp → SplashScreen → MobileScreen / DesktopScreen
library;

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeProvider.initialize();
  runApp(const ReadmeArchitectApp());
}

class ReadmeArchitectApp extends StatelessWidget {
  const ReadmeArchitectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Automated README Architect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
