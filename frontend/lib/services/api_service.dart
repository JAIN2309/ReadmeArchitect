/// HTTP service that communicates with the FastAPI backend.
library;

import 'dart:convert';
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
  /// Base URL of the running FastAPI server. Change this for production.
  static const String _baseUrl = 'http://localhost:8000';

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
