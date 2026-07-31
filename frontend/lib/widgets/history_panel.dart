/// Premium history panel widget.
///
/// Displays past README generations with search, date grouping, and
/// styled entry cards with direct View, Copy, Download, and Delete actions.
/// Responsive: sidebar panel on desktop, drawer on mobile.
library;

import 'package:flutter/material.dart';
import '../models/history_entry.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

/// Callback when the user taps a history entry to restore it.
typedef OnHistorySelect = void Function(HistoryEntry entry);

class HistoryPanel extends StatefulWidget {
  final OnHistorySelect onSelect;

  const HistoryPanel({super.key, required this.onSelect});

  @override
  State<HistoryPanel> createState() => HistoryPanelState();
}

class HistoryPanelState extends State<HistoryPanel>
    with SingleTickerProviderStateMixin {
  List<HistoryEntry> _entries = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Reload history from the backend. Can be called externally.
  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final entries = await ApiService.getHistory();
      if (mounted) {
        setState(() => _entries = entries);
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEntry(int id) async {
    try {
      await ApiService.deleteHistoryEntry(id);
      setState(() => _entries.removeWhere((e) => e.id == id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _copyEntry(HistoryEntry entry) {
    ExportService.copyToClipboard(entry.markdown);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${entry.repoName} README to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _downloadEntry(HistoryEntry entry) {
    final success = ExportService.downloadMarkdownFile(
      content: entry.markdown,
      repoOwner: entry.repoOwner,
      repoName: entry.repoName,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading files is not supported on this platform'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearAll() async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.onSurface.withAlpha(15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFEF4444),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Clear All History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will permanently delete all ${_entries.length} generation records. This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withAlpha(140),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurface.withAlpha(160),
                          side: BorderSide(
                              color: cs.onSurface.withAlpha(25)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.delete_sweep_rounded,
                            size: 16),
                        label: const Text('Clear All',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.clearHistory();
        setState(() => _entries.clear());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear: $e')),
          );
        }
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  List<HistoryEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    final q = _searchQuery.toLowerCase();
    return _entries
        .where((e) =>
            e.repoName.toLowerCase().contains(q) ||
            e.repoOwner.toLowerCase().contains(q) ||
            e.presentationMode.toLowerCase().contains(q))
        .toList();
  }

  Color _modeBadgeColor(String mode) {
    return switch (mode) {
      'Basic' => const Color(0xFF22C55E),
      'Advanced' => const Color(0xFF3B82F6),
      'Professional' => const Color(0xFFF59E0B),
      _ => Theme.of(context).colorScheme.primary,
    };
  }

  IconData _modeIcon(String mode) {
    return switch (mode) {
      'Basic' => Icons.article_rounded,
      'Advanced' => Icons.dashboard_rounded,
      'Professional' => Icons.business_center_rounded,
      _ => Icons.description_rounded,
    };
  }

  String _dateGroupLabel(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      final now = DateTime.now().toUtc();
      final diff = now.difference(dt);

      if (diff.inHours < 24 && dt.day == now.day) return 'Today';
      if (diff.inHours < 48) return 'Yesterday';
      if (diff.inDays < 7) return 'This Week';
      if (diff.inDays < 30) return 'This Month';
      return 'Earlier';
    } catch (_) {
      return 'Earlier';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(cs),
          if (!_isLoading && _error == null && _entries.isNotEmpty)
            _buildSearchBar(cs),
          Expanded(child: _buildBody(cs)),
          if (_entries.isNotEmpty) _buildFooter(cs),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.history_rounded, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generation History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review and manage past generations',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),
          // Refresh
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: refresh,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.onSurface.withAlpha(8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.refresh_rounded,
                    color: cs.onSurface.withAlpha(100), size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────

  Widget _buildSearchBar(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHigh
              : cs.surfaceContainerHigh.withAlpha(120),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.onSurface.withAlpha(isDark ? 12 : 20)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(fontSize: 13, color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Search history…',
            hintStyle: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withAlpha(60),
            ),
            prefixIcon: Icon(Icons.search_rounded,
                size: 18, color: cs.onSurface.withAlpha(60)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 16, color: cs.onSurface.withAlpha(80)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────

  Widget _buildBody(ColorScheme cs) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading history…',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(80),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState(cs);
    }

    if (_entries.isEmpty) {
      return _buildEmptyState(cs);
    }

    final filtered = _filteredEntries;
    if (filtered.isEmpty) {
      return _buildNoResultsState(cs);
    }

    return FadeTransition(
      opacity: _fadeIn,
      child: _buildGroupedList(filtered, cs),
    );
  }

  Widget _buildErrorState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load history',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(100),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: refresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary.withAlpha(50)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded,
                  color: cs.primary.withAlpha(80), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'No generations yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Generate your first README to see it here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(100),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                color: cs.onSurface.withAlpha(40), size: 32),
            const SizedBox(height: 12),
            Text(
              'No results for "$_searchQuery"',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withAlpha(100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grouped List ──────────────────────────────────────────────────────

  Widget _buildGroupedList(List<HistoryEntry> entries, ColorScheme cs) {
    // Group entries by date
    final Map<String, List<HistoryEntry>> groups = {};
    for (final entry in entries) {
      final label = _dateGroupLabel(entry.createdAt);
      groups.putIfAbsent(label, () => []).add(entry);
    }

    final groupOrder = ['Today', 'Yesterday', 'This Week', 'This Month', 'Earlier'];
    final orderedKeys =
        groupOrder.where((k) => groups.containsKey(k)).toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: orderedKeys.length,
      itemBuilder: (context, groupIndex) {
        final label = orderedKeys[groupIndex];
        final items = groups[label]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withAlpha(60),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            // Entry cards
            ...items.map((entry) => _HistoryEntryCard(
                  entry: entry,
                  modeColor: _modeBadgeColor(entry.presentationMode),
                  modeIcon: _modeIcon(entry.presentationMode),
                  onTap: () => widget.onSelect(entry),
                  onCopy: () => _copyEntry(entry),
                  onDownload: () => _downloadEntry(entry),
                  onDelete: () => _deleteEntry(entry.id),
                )),
          ],
        );
      },
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────

  Widget _buildFooter(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.onSurface.withAlpha(10)),
        ),
      ),
      child: Column(
        children: [
          // Count badge
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${_entries.length} generation${_entries.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withAlpha(60),
              ),
            ),
          ),
          // Clear all button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearAll,
              icon: Icon(Icons.delete_sweep_rounded,
                  size: 16, color: cs.onSurface.withAlpha(100)),
              label: Text(
                'Clear History',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withAlpha(140),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.onSurface.withAlpha(20)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Entry Card ──────────────────────────────────────────────────

class _HistoryEntryCard extends StatefulWidget {
  final HistoryEntry entry;
  final Color modeColor;
  final IconData modeIcon;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _HistoryEntryCard({
    required this.entry,
    required this.modeColor,
    required this.modeIcon,
    required this.onTap,
    required this.onCopy,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  State<_HistoryEntryCard> createState() => _HistoryEntryCardState();
}

class _HistoryEntryCardState extends State<_HistoryEntryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isHovered
                  ? (isDark
                      ? cs.surfaceContainerHigh
                      : cs.surfaceContainerHigh.withAlpha(100))
                  : (isDark
                      ? cs.surface
                      : cs.surfaceContainerHigh.withAlpha(50)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? cs.primary.withAlpha(30)
                    : cs.onSurface.withAlpha(isDark ? 10 : 15),
              ),
            ),
            child: Row(
              children: [
                // ── Mode icon container ──
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.modeColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: widget.modeColor.withAlpha(25)),
                  ),
                  child: Icon(widget.modeIcon,
                      size: 18, color: widget.modeColor),
                ),
                const SizedBox(width: 12),

                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.repoName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Mode badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.modeColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.entry.presentationMode,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: widget.modeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dot separator
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: cs.onSurface.withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Time ago
                          Expanded(
                            child: Text(
                              widget.entry.timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withAlpha(80),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Quick action buttons (View, Copy, Download, Delete) ──
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CardActionButton(
                      icon: Icons.content_copy_rounded,
                      tooltip: 'Copy Markdown',
                      cs: cs,
                      onTap: widget.onCopy,
                    ),
                    _CardActionButton(
                      icon: Icons.download_rounded,
                      tooltip: 'Download .md',
                      cs: cs,
                      onTap: widget.onDownload,
                    ),
                    _CardActionButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Delete',
                      cs: cs,
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _CardActionButton({
    required this.icon,
    required this.tooltip,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(
              icon,
              size: 15,
              color: cs.onSurface.withAlpha(100),
            ),
          ),
        ),
      ),
    );
  }
}
