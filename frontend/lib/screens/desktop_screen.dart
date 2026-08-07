/// Desktop-optimized screen for the Automated README Architect.
///
/// Premium layout with vertical icon sidebar, split-pane editor/preview,
/// and a clean toolbar. All components map to existing functional features.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/history_panel.dart';
import '../widgets/badge_selector.dart';
import '../theme/theme_provider.dart';
import '../widgets/shared/url_input_field.dart';
import '../widgets/shared/mode_selector.dart';
import '../widgets/shared/generate_button.dart';
import '../widgets/shared/settings_dialog.dart';
import '../widgets/shared/auth_dialog.dart';
import '../services/auth_service.dart';
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
  int _sidebarIndex = -1; // -1 = none selected
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    AuthService.initialize();
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

  void _onSidebarTap(int index) {
    final hasOutput = _controller.generatedMarkdown.isNotEmpty;

    switch (index) {
      case 0: // History
        setState(() {
          _historyOpen = !_historyOpen;
          _sidebarIndex = _historyOpen ? 0 : -1;
        });
        break;
      case 1: // Badges
        if (hasOutput && _controller.repoOwner.isNotEmpty && _controller.repoName.isNotEmpty) {
          BadgeSelector.show(
            context,
            repoOwner: _controller.repoOwner,
            repoName: _controller.repoName,
            initialSelectedKeys: _controller.selectedBadges,
            onApply: _controller.applyBadges,
          );
        }
        break;
      case 2: // Copy
        if (hasOutput) _controller.copyToClipboard(_showSnack);
        break;
      case 3: // PR
        if (hasOutput) _controller.createPullRequest(_showSnack);
        break;
      case 4: // Download
        if (hasOutput) _controller.downloadFile(_showSnack);
        break;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([_controller, AuthService.userNotifier]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              _buildToolbar(cs),
              _buildBanners(cs),
              Expanded(
                child: Row(
                  children: [
                    _buildSidebar(cs),
                    _buildMainContent(cs),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Toolbar ────────────────────────────────────────────────────────────

  Widget _buildToolbar(ColorScheme cs) {
    final user = AuthService.currentUser;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.onSurface.withAlpha(12)),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            'ReadmeArchitect',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(width: 20),

          // URL Input
          Expanded(
            child: UrlInputField(
              controller: _controller.urlController,
              onSubmitted: () => _controller.generate(context, () => _historyKey.currentState?.refresh()),
              height: 38,
              fontSize: 13,
              borderRadius: 10,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),

          const SizedBox(width: 16),

          // Mode Selector
          ModeSelector(
            modes: _controller.modes,
            selectedIndex: _controller.selectedModeIndex,
            onModeSelected: _controller.setModeIndex,
            borderRadius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            fontSize: 12,
          ),

          const SizedBox(width: 12),

          // Theme toggle
          _ToolbarButton(
            icon: ThemeProvider.themeModeNotifier.value == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            tooltip: 'Toggle Theme',
            onPressed: () {
              ThemeProvider.toggleTheme();
              setState(() {});
            },
          ),

          const SizedBox(width: 4),

          // Settings
          _ToolbarButton(
            icon: Icons.settings_rounded,
            tooltip: 'Settings',
            onPressed: _showSettingsDialog,
          ),

          const SizedBox(width: 4),

          // Auth / User Profile Button
          _ToolbarButton(
            icon: user != null ? Icons.account_circle_rounded : Icons.person_outline_rounded,
            tooltip: user != null ? 'Signed in as ${user.displayName}' : 'Sign In / Account',
            onPressed: () {
              if (user == null) {
                AuthDialog.show(context);
              } else {
                AuthService.signOut();
                _showSnack('Signed out');
              }
            },
          ),

          const SizedBox(width: 12),

          // Generate
          GenerateButton(
            isLoading: _controller.isLoading,
            onPressed: () => _controller.generate(context, () => _historyKey.currentState?.refresh()),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            fontSize: 13,
            borderRadius: 10,
          ),
        ],
      ),
    );
  }

  // ── Banners ────────────────────────────────────────────────────────────

  Widget _buildBanners(ColorScheme cs) {
    return Column(
      children: [
        if (_controller.errorMessage != null)
          _BannerBar(
            icon: Icons.error_outline_rounded,
            message: _controller.errorMessage!,
            color: const Color(0xFFEF4444),
            onDismiss: _controller.clearError,
          ),
        if (_controller.isMock)
          const _BannerBar(
            icon: Icons.warning_amber_rounded,
            message: 'GitHub API limit reached. Using mock repository data as a fallback.',
            color: Color(0xFFF59E0B),
          ),
      ],
    );
  }

  // ── Sidebar ────────────────────────────────────────────────────────────

  Widget _buildSidebar(ColorScheme cs) {
    final hasOutput = _controller.generatedMarkdown.isNotEmpty;
    final hasBadgeData = hasOutput && _controller.repoOwner.isNotEmpty && _controller.repoName.isNotEmpty;

    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(color: cs.onSurface.withAlpha(12)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.history_rounded,
            label: 'History',
            isActive: _sidebarIndex == 0,
            onTap: () => _onSidebarTap(0),
          ),
          if (hasBadgeData)
            _SidebarItem(
              icon: Icons.verified_rounded,
              label: 'Badges',
              isActive: false,
              onTap: () => _onSidebarTap(1),
            ),
          if (hasOutput) ...[
            _SidebarItem(
              icon: Icons.content_copy_rounded,
              label: 'Copy',
              isActive: false,
              onTap: () => _onSidebarTap(2),
            ),
            _SidebarItem(
              icon: Icons.call_merge_rounded,
              label: 'PR',
              isActive: false,
              onTap: () => _onSidebarTap(3),
            ),
            _SidebarItem(
              icon: Icons.download_rounded,
              label: 'Export',
              isActive: false,
              onTap: () => _onSidebarTap(4),
            ),
          ],
        ],
      ),
    );
  }

  // ── Main Content ───────────────────────────────────────────────────────

  Widget _buildMainContent(ColorScheme cs) {
    return Expanded(
      child: Row(
        children: [
          // History panel (animated)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _historyOpen ? 300 : 0,
            child: _historyOpen
                ? Container(
                    margin: const EdgeInsets.only(left: 12, top: 12, bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.onSurface.withAlpha(10)),
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

          // Editor pane
          Expanded(child: _buildEditorPane(cs)),

          // Divider
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 28),
            color: cs.onSurface.withAlpha(8),
          ),

          // Preview pane
          Expanded(child: _buildPreviewPane(cs)),
        ],
      ),
    );
  }

  // ── Editor Pane ────────────────────────────────────────────────────────

  Widget _buildEditorPane(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(
        left: _historyOpen ? 8 : 12,
        top: 12,
        bottom: 16,
        right: 6,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withAlpha(isDark ? 10 : 18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _PaneHeader(
              icon: Icons.code_rounded,
              label: 'README.md',
              cs: cs,
              trailing: _controller.repoLabel.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _controller.repoLabel,
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: _controller.generatedMarkdown.isEmpty
                  ? _buildEmptyState(
                      cs, 'Raw markdown will appear here', Icons.code_rounded)
                  : _buildLineNumberedEditor(cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineNumberedEditor(ColorScheme cs) {
    final lines = _controller.generatedMarkdown.split('\n');
    final lineCount = lines.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line numbers gutter
        Container(
          width: 48,
          color: cs.surfaceContainerHigh.withAlpha(80),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16),
            itemCount: lineCount,
            itemBuilder: (context, i) => SizedBox(
              height: 22.1, // Match line height of editor
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontFamily: 'Cascadia Code, Fira Code, monospace',
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(35),
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Editor
        Expanded(
          child: TextField(
            controller: _controller.markdownController,
            maxLines: null,
            expands: true,
            onChanged: _controller.updateMarkdown,
            style: TextStyle(
              fontFamily: 'Cascadia Code, Fira Code, monospace',
              fontSize: 13,
              height: 1.7,
              color: cs.onSurface.withAlpha(200),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(12, 16, 16, 16),
            ),
          ),
        ),
      ],
    );
  }

  // ── Preview Pane ──────────────────────────────────────────────────────

  Widget _buildPreviewPane(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 6, top: 12, bottom: 16, right: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withAlpha(isDark ? 10 : 18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PaneHeader(
              icon: Icons.visibility_rounded,
              label: 'Live Preview',
              cs: cs,
              trailing: _controller.isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SYNCING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF22C55E).withAlpha(200),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
            Expanded(
              child: _controller.generatedMarkdown.isEmpty
                  ? _buildEmptyState(
                      cs, 'Rendered preview will appear here', Icons.preview_rounded)
                  : Markdown(
                      data: _controller.generatedMarkdown,
                      padding: const EdgeInsets.all(24),
                      styleSheet: _buildMarkdownStyle(cs),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────

  Widget _buildEmptyState(ColorScheme cs, String label, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: cs.onSurface.withAlpha(30)),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withAlpha(50),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Markdown StyleSheet ───────────────────────────────────────────────

  MarkdownStyleSheet _buildMarkdownStyle(ColorScheme cs) {
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: TextStyle(
        color: cs.onSurface.withAlpha(200),
        fontSize: 14.5,
        height: 1.6,
        letterSpacing: 0.2,
      ),
      h1: TextStyle(
        color: cs.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      h2: TextStyle(
        color: cs.onSurface,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      h3: TextStyle(
        color: cs.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      code: TextStyle(
        backgroundColor: cs.onSurface.withAlpha(12),
        color: cs.primary,
        fontSize: 13,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.surfaceContainerHighest),
      ),
      listBullet: TextStyle(
        color: cs.onSurface.withAlpha(150),
        fontSize: 14,
      ),
      tableHead: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      tableBody: TextStyle(
        color: cs.onSurface.withAlpha(200),
        fontSize: 13,
      ),
      tableBorder: TableBorder.all(
        color: cs.onSurface.withAlpha(12),
        width: 1,
        borderRadius: BorderRadius.circular(8),
      ),
      blockquoteDecoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          left: BorderSide(color: cs.onSurface.withAlpha(30), width: 3),
        ),
      ),
      blockquote: TextStyle(
        color: cs.onSurface.withAlpha(150),
        fontStyle: FontStyle.italic,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.onSurface.withAlpha(12), width: 1),
        ),
      ),
    );
  }
}

// ── Pane Header ──────────────────────────────────────────────────────────

class _PaneHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final Widget? trailing;

  const _PaneHeader({
    required this.icon,
    required this.label,
    required this.cs,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.onSurface.withAlpha(10)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: cs.primary.withAlpha(180)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withAlpha(160),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

// ── Sidebar Item ─────────────────────────────────────────────────────────

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? cs.primary.withAlpha(15)
                  : _isHovered
                      ? cs.onSurface.withAlpha(8)
                      : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: widget.isActive ? cs.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isActive
                      ? cs.primary
                      : _isHovered
                          ? cs.onSurface.withAlpha(160)
                          : cs.onSurface.withAlpha(80),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isActive
                        ? cs.primary
                        : cs.onSurface.withAlpha(60),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Toolbar Button ───────────────────────────────────────────────────────

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered ? cs.onSurface.withAlpha(12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _isHovered
                  ? cs.onSurface.withAlpha(200)
                  : cs.onSurface.withAlpha(120),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Banner Bar ───────────────────────────────────────────────────────────

class _BannerBar extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback? onDismiss;

  const _BannerBar({
    required this.icon,
    required this.message,
    required this.color,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: color.withAlpha(15),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, size: 14, color: color.withAlpha(150)),
            ),
        ],
      ),
    );
  }
}
