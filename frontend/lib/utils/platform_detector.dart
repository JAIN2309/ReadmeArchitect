/// Platform detection utility for Automated README Architect.
///
/// Determines whether the app is running as a native Android app or inside
/// a desktop web browser (Chrome / Edge), and exposes the result as an enum.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

/// The detected runtime platform category.
enum AppPlatform {
  /// Running natively on an Android device / emulator.
  mobileNative,

  /// Running inside a desktop web browser (Chrome or Edge detected).
  desktopWeb,
}

/// Stateless utility that inspects the runtime environment once at startup.
class PlatformDetector {
  PlatformDetector._();

  /// Detect the platform and return the appropriate [AppPlatform] variant.
  static AppPlatform detect() {
    if (!kIsWeb) {
      // Not running on the web → treat as native mobile (Android).
      return AppPlatform.mobileNative;
    }

    // Running on the web — check user agent and screen size
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    
    final isMobileDevice = userAgent.contains('mobile') ||
        userAgent.contains('android') ||
        userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');

    final screenWidth = html.window.screen?.width ?? 1024;
    final isSmallScreen = screenWidth < 768;

    if (isMobileDevice || isSmallScreen) {
      // Route web mobile users to the mobile-optimized screen
      return AppPlatform.mobileNative;
    }

    // Default to desktop split-pane layout for laptops and desktops
    return AppPlatform.desktopWeb;
  }
}
