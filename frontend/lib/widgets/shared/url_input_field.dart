import 'package:flutter/material.dart';

class UrlInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;
  final double? height;
  final double fontSize;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;

  const UrlInputField({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.height,
    this.fontSize = 14,
    this.borderRadius = 14,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final textField = TextField(
      controller: controller,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize,
      ),
      onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
      decoration: InputDecoration(
        hintText: 'https://github.com/owner/repo',
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(90),
        ),
        prefixIcon: Icon(
          Icons.link,
          color: Theme.of(context).colorScheme.primary,
          size: fontSize + 4,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: contentPadding,
      ),
    );

    if (height != null) {
      return SizedBox(height: height, child: textField);
    }

    return textField;
  }
}
