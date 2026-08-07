/// Responsive Profile & Account Info Modal for README Architect.
///
/// Displays signed-in user details, authentication provider info,
/// Cloud Sync status, and a confirmation modal for logging out.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

class ProfileDialog extends StatefulWidget {
  final AppUser user;
  final VoidCallback? onSignedOut;

  const ProfileDialog({
    super.key,
    required this.user,
    this.onSignedOut,
  });

  static Future<void> show(
    BuildContext context, {
    required AppUser user,
    VoidCallback? onSignedOut,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ProfileDialog(user: user, onSignedOut: onSignedOut),
      );
    } else {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withAlpha(170),
        builder: (context) => ProfileDialog(user: user, onSignedOut: onSignedOut),
      );
    }
  }

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _copyUid() {
    Clipboard.setData(ClipboardData(text: widget.user.uid));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Future<void> _confirmSignOut() async {
    final cs = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withAlpha(180),
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.onSurface.withAlpha(15)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out? Your generated README history will remain safely stored in your Cloud account.',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withAlpha(160),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.onSurface.withAlpha(20)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: cs.onSurface.withAlpha(180),
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.signOut();
      widget.onSignedOut?.call();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = _buildContent(cs, isDark);

    if (isMobile) {
      return FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              MediaQuery.of(context).viewInsets.bottom + 28,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withAlpha(30),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  content,
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 440,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.onSurface.withAlpha(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Gradient accent bar
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary,
                          const Color(0xFF8B5CF6),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: SingleChildScrollView(child: content),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, bool isDark) {
    final user = widget.user;
    final authType = user.isAnonymous
        ? 'Guest Session'
        : (user.email != null && user.email!.contains('@gmail.com')
            ? 'Google Account'
            : 'Email & Password');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header Bar ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Developer Profile',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.4,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: cs.onSurface.withAlpha(8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurface.withAlpha(80), size: 18),
                onPressed: () => Navigator.pop(context),
                splashRadius: 18,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // ── User Avatar Card ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHigh.withAlpha(70)
                : cs.surfaceContainerHigh.withAlpha(90),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.onSurface.withAlpha(12)),
          ),
          child: Row(
            children: [
              // Avatar Circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary,
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: user.photoUrl != null
                      ? ClipOval(
                          child: Image.network(user.photoUrl!,
                              width: 52, height: 52, fit: BoxFit.cover),
                        )
                      : Text(
                          (user.displayName ?? 'D')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'Developer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? 'Guest Developer',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurface.withAlpha(140),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Live Sync Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFF10B981).withAlpha(30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Cloud Sync Active',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Detail Cards ──
        _buildInfoRow(
          icon: Icons.shield_outlined,
          label: 'Auth Method',
          value: authType,
          cs: cs,
          isDark: isDark,
        ),

        const SizedBox(height: 10),

        _buildInfoRow(
          icon: Icons.fingerprint_rounded,
          label: 'Account UID',
          value: user.uid.length > 18
              ? '${user.uid.substring(0, 16)}...'
              : user.uid,
          cs: cs,
          isDark: isDark,
          trailing: InkWell(
            onTap: _copyUid,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isCopied
                        ? Icons.check_circle_rounded
                        : Icons.copy_rounded,
                    size: 14,
                    color: _isCopied ? const Color(0xFF10B981) : cs.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isCopied ? 'Copied' : 'Copy',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isCopied ? const Color(0xFF10B981) : cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 26),

        // ── Sign Out Button ──
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout_rounded,
                size: 18, color: Color(0xFFEF4444)),
            label: const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: const Color(0xFFEF4444).withAlpha(40)),
              backgroundColor: const Color(0xFFEF4444).withAlpha(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme cs,
    required bool isDark,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHigh.withAlpha(40)
            : cs.surfaceContainerHigh.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withAlpha(8)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurface.withAlpha(100)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withAlpha(140),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }
}
