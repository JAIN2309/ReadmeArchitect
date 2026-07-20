/// Mobile-optimized screen for the Automated README Architect.
///
/// Designed for native Android with a single-column vertical layout,
/// large touch targets, scrollable markdown output, and action buttons
/// for copy, download, and history.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/history_entry.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../widgets/history_panel.dart';
import '../widgets/badge_selector.dart';
import '../theme/theme_provider.dart';

class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<HistoryPanelState> _historyKey = GlobalKey<HistoryPanelState>();
  final List<String> _modes = ['Basic', 'Advanced', 'Professional'];
  int _selectedModeIndex = 0;
  String _githubToken = '';

  List<String> _selectedBadges = [];

  final TextEditingController _markdownController = TextEditingController();
  bool _isPreview = true;

  bool _isLoading = false;
  String _generatedMarkdown = '';
  String _repoOwner = '';
  String _repoName = '';
  String? _errorMessage;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _githubToken = prefs.getString('github_token') ?? '';
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _markdownController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Please enter a GitHub repository URL.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _generatedMarkdown = '';
      _selectedBadges = [];
    });

    try {
      final result = await ApiService.generateReadme(
        githubUrl: url,
        presentationMode: _modes[_selectedModeIndex],
        githubToken: _githubToken,
      );
      setState(() {
        _generatedMarkdown = result.markdown;
        _markdownController.text = result.markdown;
        _isPreview = true;
        _repoOwner = result.repoOwner;
        _repoName = result.repoName;
      });
      // Refresh history panel after a new generation.
      _historyKey.currentState?.refresh();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (_generatedMarkdown.isEmpty) return;
    ExportService.copyToClipboard(_generatedMarkdown);
    _showSnack('Copied to clipboard');
  }

  void _downloadFile() {
    if (_generatedMarkdown.isEmpty) return;
    final success = ExportService.downloadMarkdownFile(
      content: _generatedMarkdown,
      repoOwner: _repoOwner,
      repoName: _repoName,
    );
    if (success) {
      _showSnack('Download started');
    } else {
      // Fallback on mobile — copy to clipboard instead.
      ExportService.copyToClipboard(_generatedMarkdown);
      _showSnack('File download is web-only. Copied to clipboard instead.');
    }
  }

  void _onHistorySelect(HistoryEntry entry) {
    Navigator.pop(context); // close the drawer
    setState(() {
      _urlController.text = entry.githubUrl;
      _generatedMarkdown = entry.markdown;
      _markdownController.text = entry.markdown;
      _isPreview = true;
      _repoOwner = entry.repoOwner;
      _repoName = entry.repoName;
      _errorMessage = null;
      _selectedModeIndex = _modes.indexOf(entry.presentationMode).clamp(0, 2);
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSettingsDialog() {
    final TextEditingController tokenController = TextEditingController(text: _githubToken);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: Text('Settings', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: tokenController,
          obscureText: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'GitHub Personal Access Token',
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
            hintText: 'ghp_...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(50)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withAlpha(20)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('github_token', tokenController.text.trim());
              setState(() {
                _githubToken = tokenController.text.trim();
              });
              if (mounted) Navigator.pop(context);
              _showSnack('Settings saved');
            },
            child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  Future<void> _createPullRequest() async {
    if (_generatedMarkdown.isEmpty) return;
    if (_githubToken.isEmpty) {
      _showSnack('Please set a GitHub Token in settings first');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prUrl = await ApiService.createPullRequest(
        githubUrl: _urlController.text,
        githubToken: _githubToken,
        markdown: _generatedMarkdown,
      );
      _showSnack('PR Created Successfully!');
      final uri = Uri.parse(prUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to create PR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasOutput = _generatedMarkdown.isNotEmpty;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'README Architect',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
          tooltip: 'History',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (hasOutput && _repoOwner.isNotEmpty && _repoName.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.local_police),
              tooltip: 'Add Badges',
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                BadgeSelector.show(
                  context,
                  repoOwner: _repoOwner,
                  repoName: _repoName,
                  initialSelectedKeys: _selectedBadges,
                  onApply: (selectedKeys, markdownToInject) {
                    setState(() {
                      _selectedBadges = selectedKeys;
                      if (markdownToInject.isNotEmpty) {
                        _generatedMarkdown = markdownToInject + '\n\n' + _generatedMarkdown;
                        _markdownController.text = _generatedMarkdown;
                      }
                    });
                  },
                );
              },
            ),
          IconButton(
            icon: Icon(ThemeProvider.themeModeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ThemeProvider.toggleTheme();
              setState(() {}); // Rebuild to update icon
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            tooltip: 'Settings (GitHub Token)',
            onPressed: _showSettingsDialog,
          ),
          if (hasOutput) ...[
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'Copy markdown',
              onPressed: _copyToClipboard,
            ),
            IconButton(
              icon: const Icon(Icons.merge_type, size: 20),
              tooltip: 'Push to GitHub (Create PR)',
              onPressed: _createPullRequest,
            ),
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              tooltip: 'Download .md',
              onPressed: _downloadFile,
            ),
          ],
        ],
      ),

      // ── History drawer ──
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: HistoryPanel(
            key: _historyKey,
            onSelect: _onHistorySelect,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── URL Input ──
              TextField(
                controller: _urlController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'https://github.com/owner/repo',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(90)),
                  prefixIcon: Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Mode Selector ──
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: List.generate(_modes.length, (i) {
                    final isSelected = _selectedModeIndex == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedModeIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Color(0xFF8B5CF6),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _modes[i],
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurface.withAlpha(150),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 18),

              // ── Generate Button ──
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor: const Color(0xFF3A3670),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Generate README',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // ── Error Message ──
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withAlpha(80)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // ── Output Area ──
              if (hasOutput)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => _isPreview = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isPreview ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHigh,
                          elevation: 0,
                        ),
                        child: Text('Edit Raw', style: TextStyle(color: !_isPreview ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withAlpha(150))),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => setState(() => _isPreview = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPreview ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHigh,
                          elevation: 0,
                        ),
                        child: Text('Preview', style: TextStyle(color: _isPreview ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withAlpha(150))),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
                    ),
                  ),
                  child: !hasOutput
                      ? Center(
                          child: FadeTransition(
                            opacity: _pulseController.drive(
                              Tween(begin: 0.3, end: 0.7),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Your generated README will appear here',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _isPreview 
                              ? Markdown(
                                  data: _generatedMarkdown,
                                  padding: const EdgeInsets.all(16),
                                  styleSheet: MarkdownStyleSheet.fromTheme(
                                    Theme.of(context),
                                  ).copyWith(
                                    p: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                                      fontSize: 14.5,
                                      height: 1.6,
                                      letterSpacing: 0.2,
                                    ),
                                    h1: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.5,
                                    ),
                                    h2: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                    ),
                                    h3: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    code: TextStyle(
                                      backgroundColor: Theme.of(context).colorScheme.onSurface.withAlpha(12),
                                      color: const Color(0xFFA5B4FC),
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: const Color(0xFF141417),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(12)),
                                    ),
                                    listBullet: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                                      fontSize: 14,
                                    ),
                                    blockquoteDecoration: BoxDecoration(
                                      color: Colors.transparent,
                                      border: Border(
                                        left: BorderSide(
                                          color: Theme.of(context).colorScheme.onSurface.withAlpha(30),
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    blockquote: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    horizontalRuleDecoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Theme.of(context).colorScheme.onSurface.withAlpha(12),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : TextField(
                                  controller: _markdownController,
                                  maxLines: null,
                                  expands: true,
                                  onChanged: (val) {
                                    setState(() {
                                      _generatedMarkdown = val;
                                    });
                                  },
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Color(0xFFB0B0D0),
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
