import 'package:flutter/material.dart';

class BadgeOption {
  final String label;
  final String key;
  final String markdownTemplate; // Uses {owner} and {repo}

  const BadgeOption({
    required this.label,
    required this.key,
    required this.markdownTemplate,
  });
}

class BadgeSelector extends StatefulWidget {
  final String repoOwner;
  final String repoName;
  final List<String> initialSelectedKeys;
  final void Function(List<String> selectedKeys, String markdownToInject) onApply;

  const BadgeSelector({
    super.key,
    required this.repoOwner,
    required this.repoName,
    required this.initialSelectedKeys,
    required this.onApply,
  });

  static const List<BadgeOption> availableBadges = [
    BadgeOption(
      label: 'License',
      key: 'license',
      markdownTemplate: '![License](https://img.shields.io/github/license/{owner}/{repo}?style=for-the-badge)',
    ),
    BadgeOption(
      label: 'Stars',
      key: 'stars',
      markdownTemplate: '![Stars](https://img.shields.io/github/stars/{owner}/{repo}?style=for-the-badge)',
    ),
    BadgeOption(
      label: 'Forks',
      key: 'forks',
      markdownTemplate: '![Forks](https://img.shields.io/github/forks/{owner}/{repo}?style=for-the-badge)',
    ),
    BadgeOption(
      label: 'Issues',
      key: 'issues',
      markdownTemplate: '![Issues](https://img.shields.io/github/issues/{owner}/{repo}?style=for-the-badge)',
    ),
    BadgeOption(
      label: 'Last Commit',
      key: 'last_commit',
      markdownTemplate: '![Last Commit](https://img.shields.io/github/last-commit/{owner}/{repo}?style=for-the-badge)',
    ),
    BadgeOption(
      label: 'Code Size',
      key: 'code_size',
      markdownTemplate: '![Code Size](https://img.shields.io/github/languages/code-size/{owner}/{repo}?style=for-the-badge)',
    ),
  ];

  static void show(
    BuildContext context, {
    required String repoOwner,
    required String repoName,
    required List<String> initialSelectedKeys,
    required void Function(List<String> selectedKeys, String markdownToInject) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BadgeSelector(
        repoOwner: repoOwner,
        repoName: repoName,
        initialSelectedKeys: initialSelectedKeys,
        onApply: onApply,
      ),
    );
  }

  @override
  State<BadgeSelector> createState() => _BadgeSelectorState();
}

class _BadgeSelectorState extends State<BadgeSelector> {
  late Set<String> _selectedKeys;

  @override
  void initState() {
    super.initState();
    _selectedKeys = Set.from(widget.initialSelectedKeys);
  }

  void _apply() {
    // Generate the markdown string for the selected badges
    final selectedBadges = BadgeSelector.availableBadges
        .where((b) => _selectedKeys.contains(b.key))
        .map((b) => b.markdownTemplate
            .replaceAll('{owner}', widget.repoOwner)
            .replaceAll('{repo}', widget.repoName))
        .join('\n');

    final markdownToInject = selectedBadges.isNotEmpty ? '$selectedBadges\n\n' : '';

    widget.onApply(_selectedKeys.toList(), markdownToInject);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.colorScheme.surfaceContainerHigh),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Badges',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withAlpha(150)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Inject live GitHub status badges into your README.',
            style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontSize: 14),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: BadgeSelector.availableBadges.map((badge) {
              final isSelected = _selectedKeys.contains(badge.key);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedKeys.remove(badge.key);
                    } else {
                      _selectedKeys.add(badge.key);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Apply Badges', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
