/// Export utilities — copy to clipboard and download as .md file.
///
/// Download uses the HTML anchor trick on web. On native mobile,
/// falls back to clipboard copy with a user notification.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;

class ExportService {
  ExportService._();

  /// Copy raw markdown text to the system clipboard.
  static Future<void> copyToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
  }

  /// Download the markdown as a `.md` file.
  ///
  /// On web, triggers a browser file download. On native platforms,
  /// copies to clipboard as a fallback (returns `false` to let the
  /// caller show a contextual message).
  static bool downloadMarkdownFile({
    required String content,
    required String repoOwner,
    required String repoName,
  }) {
    final filename = '${repoOwner}_${repoName}_README.md';

    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], 'text/markdown');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return true; // download triggered
    }

    // Native mobile: no browser download available.
    return false;
  }
}
