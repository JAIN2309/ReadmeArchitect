/// Reusable history panel widget.
///
/// Displays past README generations in a scrollable list. Supports:
/// - Tapping an entry to restore its markdown
/// - Swiping / icon-button to delete individual entries
/// - Clear-all button in the header
library;

import 'package:flutter/material.dart';
import '../models/history_entry.dart';
import '../services/api_service.dart';

/// Callback when the user taps a history entry to restore it.
typedef OnHistorySelect = void Function(HistoryEntry entry);

class HistoryPanel extends StatefulWidget {
  final OnHistorySelect onSelect;

  const HistoryPanel({super.key, required this.onSelect});

  @override
  State<HistoryPanel> createState() => HistoryPanelState();
}

class HistoryPanelState extends State<HistoryPanel> {
  List<HistoryEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Reload history from the backend. Can be called externally.
  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final entries = await ApiService.getHistory();
      if (mounted) setState(() => _entries = entries);
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

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A36),
        title: const Text('Clear History', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Delete all past generations? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Clear All'),
          ),
        ],
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

  Color _modeBadgeColor(String mode) {
    return switch (mode) {
      'Basic' => const Color(0xFF22C55E),
      'Advanced' => const Color(0xFF3B82F6),
      'Professional' => const Color(0xFFF59E0B),
      _ => const Color(0xFF6C63FF),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF14142B),
              border: Border(
                bottom: BorderSide(color: Colors.white.withAlpha(15)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF6C63FF), size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Generation History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (_entries.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.delete_sweep,
                      color: Colors.white.withAlpha(100),
                      size: 20,
                    ),
                    tooltip: 'Clear all',
                    onPressed: _clearAll,
                  ),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6C63FF),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off, color: Colors.white.withAlpha(60), size: 36),
                              const SizedBox(height: 12),
                              Text(
                                'Could not load history',
                                style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: refresh,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _entries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined, color: Colors.white.withAlpha(40), size: 44),
                                const SizedBox(height: 12),
                                Text(
                                  'No generations yet',
                                  style: TextStyle(color: Colors.white.withAlpha(60), fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _entries.length,
                            separatorBuilder: (_, i) => Divider(
                              color: Colors.white.withAlpha(8),
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              return _HistoryTile(
                                entry: entry,
                                badgeColor: _modeBadgeColor(entry.presentationMode),
                                onTap: () => widget.onSelect(entry),
                                onDelete: () => _deleteEntry(entry.id),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Individual history tile ──────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final Color badgeColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.entry,
    required this.badgeColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0xFF6C63FF).withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Repo info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.repoOwner}/${entry.repoName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Mode badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.presentationMode,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Timestamp
                      Text(
                        entry.timeAgo,
                        style: TextStyle(
                          color: Colors.white.withAlpha(60),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: Icon(
                Icons.close,
                size: 16,
                color: Colors.white.withAlpha(50),
              ),
              onPressed: onDelete,
              tooltip: 'Remove',
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}
