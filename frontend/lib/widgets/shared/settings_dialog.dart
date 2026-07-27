import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsDialog extends StatefulWidget {
  final String initialToken;
  final ValueChanged<String> onTokenSaved;

  const SettingsDialog({
    super.key,
    required this.initialToken,
    required this.onTokenSaved,
  });

  static void show(
    BuildContext context, {
    required String initialToken,
    required ValueChanged<String> onTokenSaved,
  }) {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        initialToken: initialToken,
        onTokenSaved: onTokenSaved,
      ),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _tokenController;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      title: Text(
        'Settings',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      content: TextField(
        controller: _tokenController,
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
          ),
          onPressed: () async {
            final token = _tokenController.text.trim();
            await _storage.write(key: 'github_token', value: token);
            widget.onTokenSaved(token);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: Text(
            'Save',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
