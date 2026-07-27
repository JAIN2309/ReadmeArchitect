import 'package:flutter/material.dart';

class GenerateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final double height;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Widget? icon;
  final String text;

  const GenerateButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.height = 56,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.borderRadius = 14,
    this.icon,
    this.text = 'Generate README',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          ),
          padding: WidgetStatePropertyAll(padding),
          elevation: WidgetStatePropertyAll(isLoading ? 0 : 0),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Theme.of(context).colorScheme.surface,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
