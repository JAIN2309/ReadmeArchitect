/// Mobile-optimized screen for the Automated README Architect.
///
/// Designed for native Android with a single-column vertical layout,
/// large touch targets, scrollable markdown output, and action buttons
/// for copy, download, and history.
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
    Navigator.pop(context); // close the drawer
    _controller.onHistorySelect(entry);
    setState(() => _isPreview = true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final hasOutput = _controller.generatedMarkdown.isNotEmpty;

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
          icon: Icon(
            Icons.history,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: 'History',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (hasOutput && _controller.repoOwner.isNotEmpty && _controller.repoName.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.local_police),
              tooltip: 'Add Badges',
              color: Theme.of(context).colorScheme.primary,
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
          IconButton(
            icon: Icon(
              ThemeProvider.themeModeNotifier.value == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
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
              onPressed: () => _controller.copyToClipboard(_showSnack),
            ),
            IconButton(
              icon: const Icon(Icons.merge_type, size: 20),
              tooltip: 'Push to GitHub (Create PR)',
              onPressed: () => _controller.createPullRequest(_showSnack),
            ),
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              tooltip: 'Download .md',
              onPressed: () => _controller.downloadFile(_showSnack),
            ),
          ],
        ],
      ),

      // ── History drawer ──
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: HistoryPanel(key: _historyKey, onSelect: _onHistorySelect),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── URL Input ──
              UrlInputField(
                controller: _controller.urlController, 
                onSubmitted: () {
                  _controller.generate(() => _historyKey.currentState?.refresh());
                  setState(() => _isPreview = true);
                }
              ),

              const SizedBox(height: 18),

              // ── Mode Selector ──
              ModeSelector(
                modes: _controller.modes,
                selectedIndex: _controller.selectedModeIndex,
                onModeSelected: _controller.setModeIndex,
                isExpanded: true,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(vertical: 12),
                fontSize: 13,
              ),

              const SizedBox(height: 18),

              // ── Generate Button ──
              GenerateButton(
                isLoading: _controller.isLoading,
                onPressed: () {
                  _controller.generate(() => _historyKey.currentState?.refresh());
                  setState(() => _isPreview = true);
                },
                height: 52,
                fontSize: 15,
                borderRadius: 14,
                icon: const Icon(Icons.auto_awesome, size: 20),
              ),

              // ── Error Message ──
              if (_controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withAlpha(80)),
                  ),
                  child: Text(
                    _controller.errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              
              // ── Mock Fallback Banner ──
              if (_controller.isMock) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withAlpha(80)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'GitHub API limit reached. Using mock repository data as a fallback.',
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                        ),
                      ),
                    ],
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
                          backgroundColor: !_isPreview
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                          elevation: 0,
                        ),
                        child: Text(
                          'Edit Raw',
                          style: TextStyle(
                            color: !_isPreview
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => setState(() => _isPreview = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPreview
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                          elevation: 0,
                        ),
                        child: Text(
                          'Preview',
                          style: TextStyle(
                            color: _isPreview
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(15),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(60),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Your generated README will appear here',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(80),
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
                                  data: _controller.generatedMarkdown,
                                  padding: const EdgeInsets.all(16),
                                  styleSheet:
                                      MarkdownStyleSheet.fromTheme(
                                        Theme.of(context),
                                      ).copyWith(
                                        p: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(200),
                                          fontSize: 14.5,
                                          height: 1.6,
                                          letterSpacing: 0.2,
                                        ),
                                        h1: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.5,
                                        ),
                                        h2: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.3,
                                        ),
                                        h3: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha(12),
                                          ),
                                        ),
                                        listBullet: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(150),
                                          fontSize: 14,
                                        ),
                                        blockquoteDecoration: BoxDecoration(
                                          color: Colors.transparent,
                                          border: Border(
                                            left: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withAlpha(30),
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                        blockquote: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(150),
                                          fontStyle: FontStyle.italic,
                                        ),
                                        horizontalRuleDecoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withAlpha(12),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                )
                              : TextField(
                                  controller: _controller.markdownController,
                                  maxLines: null,
                                  expands: true,
                                  onChanged: _controller.updateMarkdown,
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
    },
    );
  }
}
