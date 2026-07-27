import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsDialog {
  static Future<void> show(
    BuildContext context, {
    required String initialToken,
    required ValueChanged<String> onTokenSaved,
  }) async {
    final TextEditingController tokenController = TextEditingController(
      text: initialToken,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: Text(
          'Settings',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: TextField(
          controller: tokenController,
          obscureText: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'GitHub Personal Access Token',
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
            hintText: 'ghp_...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(50),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = tokenController.text.trim();
              await prefs.setString('github_token', token);
              onTokenSaved(token);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
