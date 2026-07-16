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

    // Running on the web — inspect the browser user-agent string.
    final userAgent = html.window.navigator.userAgent.toLowerCase();

    final isChrome = userAgent.contains('chrome') && !userAgent.contains('edg');
    final isEdge = userAgent.contains('edg');

    if (isChrome || isEdge) {
      return AppPlatform.desktopWeb;
    }

    // Fallback: unknown browser → still use the desktop layout since we are
    // on the web and likely have a wide viewport.
    return AppPlatform.desktopWeb;
  }
}
