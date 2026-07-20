/// Desktop-optimized screen for the Automated README Architect.
///
/// Renders a side-by-side split layout with a collapsible history sidebar:
///   History — past generations list (collapsible).
///   Left pane  — raw Markdown source in a monospace code viewer.
///   Right pane — live rendered Markdown preview.
/// Toolbar at the top contains URL input, mode toggle, generate, copy, download.
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

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _markdownController = TextEditingController();
  final GlobalKey<HistoryPanelState> _historyKey = GlobalKey<HistoryPanelState>();
  final List<String> _modes = ['Basic', 'Advanced', 'Professional'];
  int _selectedModeIndex = 0;
  String _githubToken = '';

  List<String> _selectedBadges = [];

  bool _isLoading = false;
  bool _historyOpen = false;
  String _generatedMarkdown = '';
  String _repoOwner = '';
  String _repoName = '';
  String? _errorMessage;
  String _repoLabel = '';

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
    _shimmerController.dispose();
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
      _repoLabel = '';
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
        _repoOwner = result.repoOwner;
        _repoName = result.repoName;
        _repoLabel = '${result.repoOwner}/${result.repoName}';
      });
      // Refresh history after generation.
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
    _showSnack('Markdown copied to clipboard');
  }

  void _downloadFile() {
    if (_generatedMarkdown.isEmpty) return;
    final success = ExportService.downloadMarkdownFile(
      content: _generatedMarkdown,
      repoOwner: _repoOwner,
      repoName: _repoName,
    );
    if (!success) {
      _showSnack('Downloading files is not supported on this platform');
    }
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
        markdown: _generatedMarkdown, // Uses the latest edited markdown from the text field
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

  void _onHistorySelect(HistoryEntry entry) {
    setState(() {
      _urlController.text = entry.githubUrl;
      _generatedMarkdown = entry.markdown;
      _markdownController.text = entry.markdown;
      _repoOwner = entry.repoOwner;
      _repoName = entry.repoName;
      _repoLabel = '${entry.repoOwner}/${entry.repoName}';
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
        margin: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
      ),
    );
  }

  // ── Build helpers ──────────────────────────────────────────────────────

  Widget _buildToolbar() {
    final hasOutput = _generatedMarkdown.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF14142B),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2A4A), width: 1),
        ),
      ),
      child: Row(
        children: [
          // History toggle
          _ToolbarIconButton(
            icon: Icons.history,
            tooltip: 'Toggle history',
            isActive: _historyOpen,
            onPressed: () => setState(() => _historyOpen = !_historyOpen),
          ),
          const SizedBox(width: 8),

          // Theme toggle
          _ToolbarIconButton(
            icon: ThemeProvider.themeModeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            tooltip: 'Toggle Theme',
            onPressed: () {
              ThemeProvider.toggleTheme();
              setState(() {}); // Rebuild to update icon
            },
          ),
          const SizedBox(width: 12),

          // Logo / title
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'README Architect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // URL input
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onSubmitted: (_) => _generate(),
                decoration: InputDecoration(
                  hintText: 'https://github.com/owner/repo',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(70)),
                  prefixIcon: const Icon(
                    Icons.link,
                    color: Colors.purpleAccent,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E3F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.purpleAccent,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Mode selector
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E3F),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_modes.length, (i) {
                final isSelected = _selectedModeIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedModeIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Colors.purpleAccent, Color(0xFF8B5CF6)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _modes[i],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withAlpha(140),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 12),

          // Badge button
          if (hasOutput && _repoOwner.isNotEmpty && _repoName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ToolbarIconButton(
                icon: Icons.local_police,
                tooltip: 'Add Badges',
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
            ),

          // Generate button
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generate,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  : const Icon(Icons.bolt, size: 16),
              label: Text(
                _isLoading ? 'Generating…' : 'Generate',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                disabledBackgroundColor: const Color(0xFF3A3670),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),

          // Action buttons (appear when output exists)
          const SizedBox(width: 8),
          _ToolbarIconButton(
            icon: Icons.settings,
            tooltip: 'Settings (GitHub Token)',
            onPressed: _showSettingsDialog,
          ),
          if (hasOutput) ...[
            const SizedBox(width: 4),
            _ToolbarIconButton(
              icon: Icons.copy,
              tooltip: 'Copy markdown',
              onPressed: _copyToClipboard,
            ),
            const SizedBox(width: 4),
            _ToolbarIconButton(
              icon: Icons.merge_type,
              tooltip: 'Push to GitHub (Create PR)',
              onPressed: _createPullRequest,
            ),
            const SizedBox(width: 4),
            _ToolbarIconButton(
              icon: Icons.download,
              tooltip: 'Download .md file',
              onPressed: _downloadFile,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String label, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Theme.of(context).colorScheme.onSurface.withAlpha(40)),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaneHeader(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withAlpha(15)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.4,
            ),
          ),
          if (_repoLabel.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _repoLabel,
                style: const TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRawPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPaneHeader('Markdown Source', Icons.code),
        Expanded(
          child: _generatedMarkdown.isEmpty
              ? _buildEmptyState(
                  'Raw markdown will\nappear here',
                  Icons.code_outlined,
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
                    fontFamily: 'Cascadia Code, Fira Code, monospace',
                    fontSize: 13,
                    height: 1.7,
                    color: Color(0xFFB0B0D0),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPreviewPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPaneHeader('Live Preview', Icons.visibility),
        Expanded(
          child: _generatedMarkdown.isEmpty
              ? _buildEmptyState(
                  'Rendered preview will\nappear here',
                  Icons.preview_outlined,
                )
              : Markdown(
                  data: _generatedMarkdown,
                  padding: const EdgeInsets.all(24),
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
                    tableHead: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tableBody: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                      fontSize: 13,
                    ),
                    tableBorder: TableBorder.all(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(12),
                      width: 1,
                      borderRadius: BorderRadius.circular(8),
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
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Top toolbar ──
          _buildToolbar(),

          // ── Error banner ──
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              color: Colors.red.withAlpha(20),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),

          // ── Main content area ──
          Expanded(
            child: Row(
              children: [
                // History sidebar (animated open/close)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _historyOpen ? 300 : 0,
                  child: _historyOpen
                      ? Container(
                          margin: const EdgeInsets.only(
                            left: 16,
                            top: 16,
                            bottom: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(10)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: HistoryPanel(
                              key: _historyKey,
                              onSelect: _onHistorySelect,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Left — raw markdown
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      left: _historyOpen ? 12 : 20,
                      top: 16,
                      bottom: 20,
                      right: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12122A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(10)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildRawPane(),
                    ),
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 32),
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(10),
                ),

                // Right — rendered preview
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 8,
                      top: 16,
                      bottom: 20,
                      right: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12122A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(10)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildPreviewPane(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small toolbar icon button ────────────────────────────────────────────

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? Theme.of(context).colorScheme.primary.withAlpha(25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withAlpha(140),
            ),
          ),
        ),
      ),
    );
  }
}
