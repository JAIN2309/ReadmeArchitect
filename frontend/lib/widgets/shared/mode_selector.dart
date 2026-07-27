import 'package:flutter/material.dart';

class ModeSelector extends StatelessWidget {
  final List<String> modes;
  final int selectedIndex;
  final ValueChanged<int> onModeSelected;
  final bool isExpanded;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const ModeSelector({
    super.key,
    required this.modes,
    required this.selectedIndex,
    required this.onModeSelected,
    this.isExpanded = false,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: List.generate(modes.length, (i) {
          final isSelected = selectedIndex == i;

          final item = GestureDetector(
            onTap: () => onModeSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: padding,
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius - 2),
              ),
              alignment: isExpanded ? Alignment.center : null,
              child: Text(
                modes[i],
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: fontSize,
                ),
              ),
            ),
          );

          if (isExpanded) {
            return Expanded(child: item);
          }
          return item;
        }),
      ),
    );
  }
}
