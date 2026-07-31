/// HTTP service that communicates with the FastAPI backend.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';
import 'auth_service.dart';

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
  static String get _baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:8000';
      }
      return 'https://readmearchitect.onrender.com';
    }
    if (kDebugMode) {
      return 'http://localhost:8000';
    }
    return 'https://readmearchitect.onrender.com';
  }

  static String _sessionId = 'default';

  /// Generate headers with Session ID and optional Firebase ID Token Bearer
  static Future<Map<String, String>> _getHeaders() async {
    final activeUid = AuthService.currentUser?.uid ?? _sessionId;
    final token = await AuthService.getIdToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Session-ID': activeUid,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

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

  /// Generate a README by sending the [githubUrl] and [presentationMode]
  /// to the backend.
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

    final headers = await _getHeaders();
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(bodyData),
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
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);

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
  static Future<void> deleteHistoryEntry(Object entryId) async {
    final uri = Uri.parse('$_baseUrl/api/history/$entryId');
    final headers = await _getHeaders();
    final response = await http.delete(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
  }

  /// Clear all history entries.
  static Future<void> clearHistory() async {
    final uri = Uri.parse('$_baseUrl/api/history');
    final headers = await _getHeaders();
    final response = await http.delete(uri, headers: headers);

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
    final headers = await _getHeaders();
    final response = await http.post(
      uri,
      headers: headers,
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

  static String _extractError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['detail'] as String? ?? 'Request failed (${response.statusCode})';
    } catch (_) {
      return 'Request failed (${response.statusCode}): ${response.body}';
    }
  }
}
