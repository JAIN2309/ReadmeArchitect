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
    this.borderRadius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: List.generate(modes.length, (i) {
          final isSelected = selectedIndex == i;

          final activeBg = isDark ? const Color(0xFF3F3F46) : Colors.white;
          final activeFg = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF0F172A);
          final inactiveFg = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569);

          final item = GestureDetector(
            onTap: () => onModeSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding: padding,
              decoration: BoxDecoration(
                color: isSelected ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius - 2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withAlpha(70)
                              : Colors.black.withAlpha(18),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ]
                    : null,
              ),
              alignment: isExpanded ? Alignment.center : null,
              child: Text(
                modes[i],
                style: TextStyle(
                  color: isSelected ? activeFg : inactiveFg,
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

