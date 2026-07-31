/// Responsive Authentication Modal for README Architect.
///
/// Prompts users to log in before generating READMEs or accessing Cloud Sync.
/// Matches the Slate/Zinc design system.
library;

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AuthDialog extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthDialog({super.key, this.onAuthSuccess});

  static Future<bool> show(BuildContext context, {VoidCallback? onAuthSuccess}) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AuthDialog(onAuthSuccess: onAuthSuccess),
          ) ??
          false;
    } else {
      return await showDialog<bool>(
            context: context,
            barrierColor: Colors.black54,
            builder: (context) => AuthDialog(onAuthSuccess: onAuthSuccess),
          ) ??
          false;
    }
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _error;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await AuthService.signUpWithEmail(email, password);
      } else {
        await AuthService.signInWithEmail(email, password);
      }
      if (!mounted) return;
      widget.onAuthSuccess?.call();
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthService.signInAsGuest();
      if (!mounted) return;
      widget.onAuthSuccess?.call();
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not start guest session: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final content = _buildContent(cs);

    if (isMobile) {
      return FadeTransition(
        opacity: _fadeIn,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: SingleChildScrollView(child: content),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeIn,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.onSurface.withAlpha(15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: SingleChildScrollView(child: content),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              child: Icon(Icons.lock_rounded, color: cs.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSignUp ? 'Create Account' : 'Sign In Required',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign in to generate & sync READMEs across devices',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded,
                  color: cs.onSurface.withAlpha(100), size: 20),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Error Banner ───────────────────────────────────
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444).withAlpha(40)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Email Input ─────────────────────────────────────
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withAlpha(180),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHigh
                : cs.surfaceContainerHigh.withAlpha(120),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withAlpha(isDark ? 12 : 20)),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'developer@example.com',
              hintStyle: TextStyle(
                color: cs.onSurface.withAlpha(50),
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.email_outlined,
                  size: 18, color: cs.onSurface.withAlpha(80)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Password Input ──────────────────────────────────
        Text(
          'Password',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withAlpha(180),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHigh
                : cs.surfaceContainerHigh.withAlpha(120),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withAlpha(isDark ? 12 : 20)),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(
                color: cs.onSurface.withAlpha(50),
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.lock_outline_rounded,
                  size: 18, color: cs.onSurface.withAlpha(80)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Submit Button ────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isSignUp ? 'Create Account' : 'Sign In & Continue',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 14),

        // ── Toggle Sign Up / Sign In ───────────────────────
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _isSignUp = !_isSignUp),
            child: Text(
              _isSignUp
                  ? 'Already have an account? Sign In'
                  : 'New developer? Create an account',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Divider ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: cs.onSurface.withAlpha(15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withAlpha(60),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: cs.onSurface.withAlpha(15),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Guest Session Option ───────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleGuestLogin,
            icon: Icon(Icons.person_outline_rounded,
                size: 18, color: cs.onSurface.withAlpha(160)),
            label: Text(
              'Continue as Guest',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withAlpha(180),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.onSurface.withAlpha(25)),
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
}
