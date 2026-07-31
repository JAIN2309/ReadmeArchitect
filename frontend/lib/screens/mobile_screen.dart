/// Mobile-optimized screen for the Automated README Architect.
///
/// Premium single-column layout with clean AppBar, drawer history,
/// and a tabbed editor/preview output area. Only existing functional
/// components are shown.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/history_entry.dart';
import '../widgets/history_panel.dart';
import '../widgets/badge_selector.dart';
import '../theme/theme_provider.dart';
import '../widgets/shared/url_input_field.dart';
import '../widgets/shared/mode_selector.dart';
import '../widgets/shared/generate_button.dart';
import '../widgets/shared/settings_dialog.dart';
import '../controllers/readme_controller.dart';

class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen>
    with SingleTickerProviderStateMixin {
  final ReadmeController _controller = ReadmeController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<HistoryPanelState> _historyKey = GlobalKey<HistoryPanelState>();

  bool _isPreview = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
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

  void _onHistorySelect(HistoryEntry entry) {
    Navigator.pop(context);
    _controller.onHistorySelect(entry);
    setState(() => _isPreview = true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final hasOutput = _controller.generatedMarkdown.isNotEmpty;
        final hasBadgeData = hasOutput &&
            _controller.repoOwner.isNotEmpty &&
            _controller.repoName.isNotEmpty;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,

          // ── AppBar ──
          appBar: _buildAppBar(cs, hasOutput, hasBadgeData),

          // ── Drawer ──
          drawer: _buildDrawer(cs),

          body: SafeArea(
            child: Column(
              children: [
                // ── Banners ──
                _buildBanners(cs),

                // ── Input Section ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UrlInputField(
                        controller: _controller.urlController,
                        onSubmitted: () {
                          _controller.generate(
                              () => _historyKey.currentState?.refresh());
                          setState(() => _isPreview = true);
                        },
                      ),
                      const SizedBox(height: 12),
                      ModeSelector(
                        modes: _controller.modes,
                        selectedIndex: _controller.selectedModeIndex,
                        onModeSelected: _controller.setModeIndex,
                        isExpanded: true,
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        fontSize: 13,
                      ),
                      const SizedBox(height: 12),
                      GenerateButton(
                        isLoading: _controller.isLoading,
                        onPressed: () {
                          _controller.generate(
                              () => _historyKey.currentState?.refresh());
                          setState(() => _isPreview = true);
                        },
                        height: 48,
                        fontSize: 14,
                        borderRadius: 12,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Output Section ──
                if (hasOutput) _buildOutputToggle(cs),
                Expanded(child: _buildOutputArea(cs, hasOutput)),

                // ── Bottom Action Bar ──
                if (hasOutput) _buildBottomBar(cs),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      ColorScheme cs, bool hasOutput, bool hasBadgeData) {
    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.history_rounded, color: cs.primary, size: 20),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            'ReadmeArchitect',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        // Theme toggle
        _MobileAppBarButton(
          icon: ThemeProvider.themeModeNotifier.value == ThemeMode.dark
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          onTap: () {
            ThemeProvider.toggleTheme();
            setState(() {});
          },
        ),
        // Settings
        _MobileAppBarButton(
          icon: Icons.settings_rounded,
          onTap: _showSettingsDialog,
        ),
        // Badges (conditional)
        if (hasBadgeData)
          _MobileAppBarButton(
            icon: Icons.verified_rounded,
            color: cs.primary,
            onTap: () {
              BadgeSelector.show(
                context,
                repoOwner: _controller.repoOwner,
                repoName: _controller.repoName,
                initialSelectedKeys: _controller.selectedBadges,
                onApply: _controller.applyBadges,
              );
            },
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────

  Widget _buildDrawer(ColorScheme cs) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: HistoryPanel(key: _historyKey, onSelect: _onHistorySelect),
      ),
    );
  }

  // ── Banners ────────────────────────────────────────────────────────────

  Widget _buildBanners(ColorScheme cs) {
    return Column(
      children: [
        if (_controller.errorMessage != null)
          _MobileBanner(
            icon: Icons.error_outline_rounded,
            message: _controller.errorMessage!,
            color: const Color(0xFFEF4444),
            onDismiss: _controller.clearError,
          ),
        if (_controller.isMock)
          const _MobileBanner(
            icon: Icons.warning_amber_rounded,
            message: 'GitHub API limit reached. Using mock data.',
            color: Color(0xFFF59E0B),
          ),
      ],
    );
  }

  // ── Output Toggle ──────────────────────────────────────────────────────

  Widget _buildOutputToggle(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withAlpha(isDark ? 10 : 15)),
        ),
        child: Row(
          children: [
            _ToggleTab(
              label: 'Edit Raw',
              icon: Icons.code_rounded,
              isActive: !_isPreview,
              cs: cs,
              onTap: () => setState(() => _isPreview = false),
            ),
            _ToggleTab(
              label: 'Preview',
              icon: Icons.visibility_rounded,
              isActive: _isPreview,
              cs: cs,
              onTap: () => setState(() => _isPreview = true),
            ),
          ],
        ),
      ),
    );
  }

  // ── Output Area ────────────────────────────────────────────────────────

  Widget _buildOutputArea(ColorScheme cs, bool hasOutput) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withAlpha(isDark ? 10 : 18)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: !hasOutput
              ? Center(
                  child: FadeTransition(
                    opacity: _pulseController.drive(
                      Tween(begin: 0.3, end: 0.7),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primary.withAlpha(8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 36,
                            color: cs.onSurface.withAlpha(40),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Your generated README will appear here',
                          style: TextStyle(
                            color: cs.onSurface.withAlpha(60),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _isPreview
                  ? Markdown(
                      data: _controller.generatedMarkdown,
                      padding: const EdgeInsets.all(16),
                      styleSheet: _buildMarkdownStyle(cs),
                    )
                  : TextField(
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
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
        ),
      ),
    );
  }

  // ── Bottom Action Bar ──────────────────────────────────────────────────

  Widget _buildBottomBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.onSurface.withAlpha(8)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BottomAction(
              icon: Icons.content_copy_rounded,
              label: 'Copy',
              cs: cs,
              onTap: () => _controller.copyToClipboard(_showSnack),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BottomAction(
              icon: Icons.call_merge_rounded,
              label: 'Create PR',
              cs: cs,
              onTap: () => _controller.createPullRequest(_showSnack),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BottomAction(
              icon: Icons.download_rounded,
              label: 'Export',
              cs: cs,
              onTap: () => _controller.downloadFile(_showSnack),
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

// ── Mobile AppBar Button ─────────────────────────────────────────────────

class _MobileAppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _MobileAppBarButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(
          icon,
          size: 20,
          color: color ?? cs.onSurface.withAlpha(120),
        ),
      ),
    );
  }
}

// ── Toggle Tab ───────────────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isActive ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? cs.primary : cs.onSurface.withAlpha(80),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? cs.onSurface : cs.onSurface.withAlpha(80),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Action Button ─────────────────────────────────────────────────

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHigh
              : cs.surfaceContainerHigh.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withAlpha(isDark ? 10 : 15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile Banner ────────────────────────────────────────────────────────

class _MobileBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback? onDismiss;

  const _MobileBanner({
    required this.icon,
    required this.message,
    required this.color,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
