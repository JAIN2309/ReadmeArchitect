import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/history_entry.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

class ReadmeController extends ChangeNotifier {
  final TextEditingController urlController = TextEditingController();
  final TextEditingController markdownController = TextEditingController();
  
  final List<String> modes = ['Basic', 'Advanced', 'Professional'];
  int selectedModeIndex = 0;
  String githubToken = '';
  List<String> selectedBadges = [];

  bool isLoading = false;
  String generatedMarkdown = '';
  String repoOwner = '';
  String repoName = '';
  String? errorMessage;
  String repoLabel = '';
  bool isMock = false;

  ReadmeController() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      githubToken = prefs.getString('github_token') ?? '';
    } else {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'github_token');
      githubToken = token ?? '';
    }
    notifyListeners();
  }

  void updateToken(String token) async {
    githubToken = token;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('github_token', token);
    } else {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'github_token', value: token);
    }
    notifyListeners();
  }

  void setModeIndex(int index) {
    selectedModeIndex = index;
    notifyListeners();
  }
  
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void updateMarkdown(String newMarkdown) {
    generatedMarkdown = newMarkdown;
    notifyListeners();
  }

  void applyBadges(List<String> keys, String injectedMarkdown) {
    selectedBadges = keys;
    if (injectedMarkdown.isNotEmpty) {
      generatedMarkdown = injectedMarkdown + '\n\n' + generatedMarkdown;
      markdownController.text = generatedMarkdown;
    }
    notifyListeners();
  }

  Future<void> generate(VoidCallback onSuccess) async {
    final url = urlController.text.trim();
    if (url.isEmpty) {
      errorMessage = 'Please enter a GitHub repository URL.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    generatedMarkdown = '';
    repoLabel = '';
    selectedBadges = [];
    isMock = false;
    notifyListeners();

    try {
      final result = await ApiService.generateReadme(
        githubUrl: url,
        presentationMode: modes[selectedModeIndex],
        githubToken: githubToken,
      );
      generatedMarkdown = result.markdown;
      markdownController.text = result.markdown;
      repoOwner = result.repoOwner;
      repoName = result.repoName;
      repoLabel = '${result.repoOwner}/${result.repoName}';
      isMock = result.isMock;
      
      onSuccess();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void copyToClipboard(Function(String) onCopy) {
    if (generatedMarkdown.isEmpty) return;
    ExportService.copyToClipboard(generatedMarkdown);
    onCopy('Markdown copied to clipboard');
  }

  void downloadFile(Function(String) onResult) {
    if (generatedMarkdown.isEmpty) return;
    final success = ExportService.downloadMarkdownFile(
      content: generatedMarkdown,
      repoOwner: repoOwner,
      repoName: repoName,
    );
    if (!success) {
      onResult('Downloading files is not supported on this platform');
    }
  }

  Future<void> createPullRequest(Function(String) showSnack) async {
    if (generatedMarkdown.isEmpty) return;
    if (githubToken.isEmpty) {
      showSnack('Please set a GitHub Token in settings first');
      return;
    }

    isLoading = true;
    notifyListeners();
    
    try {
      final prUrl = await ApiService.createPullRequest(
        githubUrl: urlController.text,
        githubToken: githubToken,
        markdown: generatedMarkdown,
      );
      showSnack('PR Created Successfully!');
      final uri = Uri.parse(prUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      errorMessage = 'Failed to create PR: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void onHistorySelect(HistoryEntry entry) {
    urlController.text = entry.githubUrl;
    generatedMarkdown = entry.markdown;
    markdownController.text = entry.markdown;
    repoOwner = entry.repoOwner;
    repoName = entry.repoName;
    repoLabel = '${entry.repoOwner}/${entry.repoName}';
    errorMessage = null;
    isMock = false; // History doesn't persist the mock flag, reset it
    selectedModeIndex = modes.indexOf(entry.presentationMode).clamp(0, 2);
    notifyListeners();
  }

  @override
  void dispose() {
    urlController.dispose();
    markdownController.dispose();
    super.dispose();
  }
}
