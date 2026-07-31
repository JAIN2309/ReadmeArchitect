import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/theme_provider.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // Full-screen bottom sheet on mobile
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SettingsDialog(
          initialToken: initialToken,
          onTokenSaved: onTokenSaved,
        ),
      );
    } else {
      // Centered dialog on desktop/web
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (context) => SettingsDialog(
          initialToken: initialToken,
          onTokenSaved: onTokenSaved,
        ),
      );
    }
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _tokenController;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  bool _obscureToken = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final token = _tokenController.text.trim();
    setState(() => _isSaving = true);
    widget.onTokenSaved(token);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final content = _buildContent(cs, isMobile);

    if (isMobile) {
      return _buildBottomSheet(cs, content);
    } else {
      return _buildDesktopDialog(cs, content, screenWidth);
    }
  }

  Widget _buildBottomSheet(ColorScheme cs, Widget content) {
    return FadeTransition(
      opacity: _fadeIn,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Drag handle ────────────────────────────────
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withAlpha(40),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  content,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopDialog(
      ColorScheme cs, Widget content, double screenWidth) {
    final dialogWidth = screenWidth > 900 ? 520.0 : 440.0;

    return FadeTransition(
      opacity: _fadeIn,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: dialogWidth,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.onSurface.withAlpha(15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasToken = _tokenController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ──────────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.settings_rounded, color: cs.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 24,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Configure your environment',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ),
            _closeButton(cs),
          ],
        ),

        const SizedBox(height: 28),
        _divider(cs),
        const SizedBox(height: 24),

        // ── Section: Authentication ─────────────────────────
        _sectionLabel(cs, 'Authentication', Icons.lock_outline_rounded),
        const SizedBox(height: 10),
        Text(
          'Enter your GitHub Personal Access Token to enable repository integration and automated generation.',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withAlpha(140),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // ── Token Input ────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHigh
                : cs.surfaceContainerHigh.withAlpha(120),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.onSurface.withAlpha(isDark ? 15 : 25),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _tokenController,
            obscureText: _obscureToken,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
              hintStyle: TextStyle(
                color: cs.onSurface.withAlpha(50),
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.vpn_key_rounded,
                color: cs.onSurface.withAlpha(80),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureToken
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: cs.onSurface.withAlpha(80),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureToken = !_obscureToken),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),

        // ── Token status badge ──────────────────────────────
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: hasToken
              ? _statusBadge(
                  cs,
                  icon: Icons.check_circle_rounded,
                  label: 'Token configured',
                  color: const Color(0xFF22C55E),
                )
              : _statusBadge(
                  cs,
                  icon: Icons.info_outline_rounded,
                  label: 'No token set — some features will be limited',
                  color: const Color(0xFFF59E0B),
                ),
        ),

        const SizedBox(height: 28),
        _divider(cs),
        const SizedBox(height: 24),

        // ── Section: Appearance ────────────────────────────
        _sectionLabel(cs, 'Appearance', Icons.palette_outlined),
        const SizedBox(height: 14),
        _buildThemeToggle(cs, isDark),

        const SizedBox(height: 28),
        _divider(cs),
        const SizedBox(height: 24),

        // ── Section: About ──────────────────────────────────
        _sectionLabel(cs, 'About', Icons.info_outline_rounded),
        const SizedBox(height: 14),
        _buildInfoCard(cs, isDark),

        const SizedBox(height: 32),

        // ── Action Buttons ──────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface.withAlpha(180),
                  side: BorderSide(color: cs.onSurface.withAlpha(30)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: cs.primary.withAlpha(120),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'Saving…' : 'Save Changes',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Reusable Components ────────────────────────────────────────────────

  Widget _closeButton(ColorScheme cs) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.onSurface.withAlpha(10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.close_rounded,
            color: cs.onSurface.withAlpha(120),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(ColorScheme cs, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _divider(ColorScheme cs) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.onSurface.withAlpha(0),
            cs.onSurface.withAlpha(20),
            cs.onSurface.withAlpha(0),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      key: ValueKey(label),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withAlpha(12)),
      ),
      child: Row(
        children: [
          _themeOption(
            cs,
            icon: Icons.light_mode_rounded,
            label: 'Light',
            isSelected: !isDark,
            onTap: () => ThemeProvider.setThemeMode(ThemeMode.light),
          ),
          _themeOption(
            cs,
            icon: Icons.dark_mode_rounded,
            label: 'Dark',
            isSelected: isDark,
            onTap: () => ThemeProvider.setThemeMode(ThemeMode.dark),
          ),
          _themeOption(
            cs,
            icon: Icons.auto_mode_rounded,
            label: 'System',
            isSelected: false, // No way to detect "system" state directly
            onTap: () => ThemeProvider.setThemeMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withAlpha(100),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? cs.onSurface
                      : cs.onSurface.withAlpha(100),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHigh
            : cs.surfaceContainerHigh.withAlpha(120),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withAlpha(isDark ? 12 : 20)),
      ),
      child: Column(
        children: [
          _infoRow(cs, 'App', 'README Architect'),
          const SizedBox(height: 10),
          _infoRow(cs, 'Version', '1.0.0'),
          const SizedBox(height: 10),
          _infoRow(
            cs,
            'Platform',
            kIsWeb ? 'Web' : 'Mobile',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ColorScheme cs, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withAlpha(120),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cs.onSurface.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
