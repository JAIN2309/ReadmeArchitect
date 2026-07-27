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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/history_entry.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../widgets/history_panel.dart';
import '../widgets/badge_selector.dart';
import '../theme/theme_provider.dart';
import '../widgets/shared/url_input_field.dart';
import '../widgets/shared/mode_selector.dart';
import '../widgets/shared/generate_button.dart';
import '../widgets/shared/settings_dialog.dart';
import '../controllers/readme_controller.dart';

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen>
    with SingleTickerProviderStateMixin {
  final ReadmeController _controller = ReadmeController();
  final GlobalKey<HistoryPanelState> _historyKey = GlobalKey<HistoryPanelState>();

  bool _historyOpen = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
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

  void _showSettingsDialog() {
    SettingsDialog.show(
      context,
      initialToken: _controller.githubToken,
      onTokenSaved: _controller.updateToken,
    );
  }

  // ── Build helpers ──────────────────────────────────────────────────────

  Widget _buildToolbar() {
    final hasOutput = _controller.generatedMarkdown.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF14142B),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A4A), width: 1)),
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
            icon: ThemeProvider.themeModeNotifier.value == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode,
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
            child: UrlInputField(
              controller: _controller.urlController,
              onSubmitted: () => _controller.generate(() => _historyKey.currentState?.refresh()),
              height: 42,
              fontSize: 13,
              borderRadius: 10,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),

          const SizedBox(width: 16),

          // Mode selector
          ModeSelector(
            modes: _controller.modes,
            selectedIndex: _controller.selectedModeIndex,
            onModeSelected: _controller.setModeIndex,
            borderRadius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            fontSize: 12,
          ),

          const SizedBox(width: 12),

          // Badge button
          if (hasOutput && _controller.repoOwner.isNotEmpty && _controller.repoName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ToolbarIconButton(
                icon: Icons.local_police,
                tooltip: 'Add Badges',
                onPressed: () {
                  BadgeSelector.show(
                    context,
                    repoOwner: _controller.repoOwner,
                    repoName: _controller.repoName,
                    initialSelectedKeys: _controller.selectedBadges,
                    onApply: _controller.applyBadges,
                  );
                },
              ),
            ),

          // Generate button
          GenerateButton(
            isLoading: _controller.isLoading,
            onPressed: () => _controller.generate(() => _historyKey.currentState?.refresh()),
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            fontSize: 14,
            borderRadius: 10,
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
              onPressed: () => _controller.copyToClipboard(_showSnack),
            ),
            const SizedBox(width: 4),
            _ToolbarIconButton(
              icon: Icons.merge_type,
              tooltip: 'Push to GitHub (Create PR)',
              onPressed: () => _controller.createPullRequest(_showSnack),
            ),
            const SizedBox(width: 4),
            _ToolbarIconButton(
              icon: Icons.download,
              tooltip: 'Download .md file',
              onPressed: () => _controller.downloadFile(_showSnack),
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
          Icon(
            icon,
            size: 52,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(40),
          ),
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
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
          ),
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
          if (_controller.repoLabel.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _controller.repoLabel,
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
          child: _controller.generatedMarkdown.isEmpty
              ? _buildEmptyState(
                  'Raw markdown will\nappear here',
                  Icons.code_outlined,
                )
              : TextField(
                  controller: _controller.markdownController,
                  maxLines: null,
                  expands: true,
                  onChanged: _controller.updateMarkdown,
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
          child: _controller.generatedMarkdown.isEmpty
              ? _buildEmptyState(
                  'Rendered preview will\nappear here',
                  Icons.preview_outlined,
                )
              : Markdown(
                  data: _controller.generatedMarkdown,
                  padding: const EdgeInsets.all(24),
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                        p: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(200),
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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(12),
                          color: const Color(0xFFA5B4FC),
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFF141417),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(12),
                          ),
                        ),
                        listBullet: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                          fontSize: 14,
                        ),
                        tableHead: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        tableBody: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(200),
                          fontSize: 13,
                        ),
                        tableBorder: TableBorder.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(12),
                          width: 1,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(30),
                              width: 3,
                            ),
                          ),
                        ),
                        blockquote: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                          fontStyle: FontStyle.italic,
                        ),
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(12),
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
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              // ── Top toolbar ──
              _buildToolbar(),

              // ── Error banner ──
              if (_controller.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  color: Colors.red.withAlpha(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _controller.errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        onPressed: _controller.clearError,
                      ),
                    ],
                  ),
                ),
              
              // ── Mock Fallback Banner ──
              if (_controller.isMock)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  color: Colors.orange.withAlpha(20),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'GitHub API limit reached. Using mock repository data as a fallback.',
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                        ),
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
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(10),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: HistoryPanel(
                              key: _historyKey,
                              onSelect: _controller.onHistorySelect,
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
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(10),
                      ),
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
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(10),
                      ),
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
