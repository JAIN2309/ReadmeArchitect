/// HTTP service that communicates with the FastAPI backend.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';

/// Response model returned by the API.
class ReadmeResult {
  final String markdown;
  final String repoOwner;
  final String repoName;
  final String presentationMode;
  final bool isMock;

  const ReadmeResult({
    required this.markdown,
    required this.repoOwner,
    required this.repoName,
    required this.presentationMode,
    required this.isMock,
  });

  factory ReadmeResult.fromJson(Map<String, dynamic> json) {
    return ReadmeResult(
      markdown: json['markdown'] as String,
      repoOwner: json['repo_owner'] as String,
      repoName: json['repo_name'] as String,
      presentationMode: json['presentation_mode'] as String,
      isMock: json['is_mock'] as bool? ?? false,
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
    // Native mobile — point to Render URL for production.
    if (kDebugMode) {
      // For local emulator testing (uncomment 10.0.2.2 if on Android emulator)
      return 'http://localhost:8000'; 
    }
    return 'https://readmearchitect.onrender.com';
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-Session-ID': _sessionId,
  };

  /// Generate a README by sending the [githubUrl] and [presentationMode]
  /// to the backend.
  ///
  /// Returns a [ReadmeResult] on success, or throws an [Exception] on failure.
  static Future<ReadmeResult> generateReadme({
    required String githubUrl,
    required String presentationMode,
    String? githubToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auto-readme');

    final bodyData = <String, dynamic>{
      'github_url': githubUrl,
      'presentation_mode': presentationMode,
    };
    if (githubToken != null && githubToken.isNotEmpty) {
      bodyData['github_token'] = githubToken;
    }

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ReadmeResult.fromJson(data);
    } else {
      throw Exception(_extractError(response));
    }
  }

  static String _sessionId = 'default';

  /// Initialize the session ID. Call this on app startup.
  static Future<void> initSession() async {
    String? sid;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      sid = prefs.getString('session_id');
      if (sid == null) {
        sid = const Uuid().v4();
        await prefs.setString('session_id', sid);
      }
    } else {
      const storage = FlutterSecureStorage();
      sid = await storage.read(key: 'session_id');
      if (sid == null) {
        sid = const Uuid().v4();
        await storage.write(key: 'session_id', value: sid);
      }
    }
    _sessionId = sid;
  }

  // ── History API ────────────────────────────────────────────────────────

  /// Fetch all history entries (newest first).
  static Future<List<HistoryEntry>> getHistory() async {
    final uri = Uri.parse('$_baseUrl/api/history');
    final response = await http.get(uri, headers: {'X-Session-ID': _sessionId});

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
    final response = await http.delete(uri, headers: {'X-Session-ID': _sessionId});

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
  }

  /// Clear all history entries.
  static Future<void> clearHistory() async {
    final uri = Uri.parse('$_baseUrl/api/history');
    final response = await http.delete(uri, headers: {'X-Session-ID': _sessionId});

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
  }

  /// Create a Pull Request via the FastAPI backend.
  static Future<String> createPullRequest({
    required String githubUrl,
    required String githubToken,
    required String markdown,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/create-pr');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'github_url': githubUrl,
        'github_token': githubToken,
        'markdown': markdown,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['pr_url'] as String;
    } else {
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
