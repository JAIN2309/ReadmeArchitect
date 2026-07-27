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
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding,
          elevation: isLoading ? 0 : 4,
          shadowColor: Theme.of(context).colorScheme.primary.withAlpha(100),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
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
