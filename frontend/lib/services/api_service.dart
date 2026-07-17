/// HTTP service that communicates with the FastAPI backend.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/history_entry.dart';

/// Response model returned by the API.
class ReadmeResult {
  final String markdown;
  final String repoOwner;
  final String repoName;
  final String presentationMode;

  const ReadmeResult({
    required this.markdown,
    required this.repoOwner,
    required this.repoName,
    required this.presentationMode,
  });

  factory ReadmeResult.fromJson(Map<String, dynamic> json) {
    return ReadmeResult(
      markdown: json['markdown'] as String,
      repoOwner: json['repo_owner'] as String,
      repoName: json['repo_name'] as String,
      presentationMode: json['presentation_mode'] as String,
    );
  }
}

/// Service that calls the FastAPI backend endpoints.
class ApiService {
  /// Base URL of the running FastAPI server.
  /// On production (GitHub Pages), points to the Render deployment.
  /// On local development, points to localhost:8000.
  static String get _baseUrl {
    if (kIsWeb) {
      // If running on GitHub Pages (or any non-localhost web host),
      // use the Render backend URL.
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:8000';
      }
      return 'https://readmearchitect.onrender.com';
    }
    // Native mobile — use localhost (for dev) or change for production.
    return 'http://localhost:8000';
  }

  /// Generate a README by sending the [githubUrl] and [presentationMode]
  /// to the backend.
  ///
  /// Returns a [ReadmeResult] on success, or throws an [Exception] on failure.
  static Future<ReadmeResult> generateReadme({
    required String githubUrl,
    required String presentationMode,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auto-readme');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'github_url': githubUrl,
        'presentation_mode': presentationMode,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ReadmeResult.fromJson(data);
    } else {
      throw Exception(_extractError(response));
    }
  }

  // ── History API ────────────────────────────────────────────────────────

  /// Fetch all history entries (newest first).
  static Future<List<HistoryEntry>> getHistory() async {
    final uri = Uri.parse('$_baseUrl/api/history');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(_extractError(response));
    }
  }

  /// Delete a single history entry by [entryId].
  static Future<void> deleteHistoryEntry(int entryId) async {
    final uri = Uri.parse('$_baseUrl/api/history/$entryId');
    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
  }

  /// Clear all history entries.
  static Future<void> clearHistory() async {
    final uri = Uri.parse('$_baseUrl/api/history');
    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static String _extractError(http.Response response) {
    String message = 'Request failed with status ${response.statusCode}';
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      if (errorData.containsKey('detail')) {
        message = errorData['detail'].toString();
      }
    } catch (_) {
      // Ignore JSON parse errors on the error body.
    }
    return message;
  }
}
