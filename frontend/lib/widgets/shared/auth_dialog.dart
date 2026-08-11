/// Premium Responsive Authentication Modal for README Architect.
///
/// Features a glassmorphism card with gradient accent strip, animated
/// transitions, real Google "G" logo SVG, and polished micro-interactions.
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
            barrierColor: Colors.black.withAlpha(170),
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
  bool _obscurePassword = true;
  String? _error;
  String? _activeButton; // Track which button is loading

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
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
      _activeButton = 'email';
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
          _error = e.toString().replaceAll('Exception: ', '').replaceAll('[firebase_auth/', '').replaceAll(']', '');
          _isLoading = false;
          _activeButton = null;
        });
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _activeButton = 'google';
      _error = null;
    });
    try {
      await AuthService.signInWithGoogle();
      if (!mounted) return;
      widget.onAuthSuccess?.call();
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _activeButton = null;
        });
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
      _activeButton = 'guest';
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
          _activeButton = null;
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
        child: SlideTransition(
          position: _slideUp,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              MediaQuery.of(context).viewInsets.bottom + 28,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Drag Handle ──
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
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
              width: 460,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cs.onSurface.withAlpha(10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: cs.primary.withAlpha(8),
                    blurRadius: 80,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top Gradient Accent Strip ──
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary,
                          cs.primary.withAlpha(180),
                          const Color(0xFF8B5CF6),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
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

  Widget _buildContent(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ──────────────────────────────────────────
        Row(
          children: [
            // Animated gradient icon container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withAlpha(25),
                    const Color(0xFF8B5CF6).withAlpha(15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.primary.withAlpha(20)),
              ),
              child: Icon(Icons.shield_rounded, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSignUp ? 'Create Your Account' : 'Welcome Back',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _isSignUp
                        ? 'Join to generate & sync READMEs across devices'
                        : 'Sign in to continue generating READMEs',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cs.onSurface.withAlpha(100),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            _buildCloseButton(cs),
          ],
        ),

        const SizedBox(height: 28),

        // ── 1-Click Google Sign-In (FIRST — most prominent) ──
        _buildGoogleButton(cs, isDark),

        const SizedBox(height: 20),

        // ── Divider ──
        _buildDivider(cs),

        const SizedBox(height: 20),

        // ── Error Banner ───────────────────────────────────
        if (_error != null) ...[
          _buildErrorBanner(cs),
          const SizedBox(height: 16),
        ],

        // ── Email Input ─────────────────────────────────────
        _buildInputLabel('Email Address', cs),
        const SizedBox(height: 6),
        _buildEmailField(cs, isDark),

        const SizedBox(height: 14),

        // ── Password Input ──────────────────────────────────
        _buildInputLabel('Password', cs),
        const SizedBox(height: 6),
        _buildPasswordField(cs, isDark),

        const SizedBox(height: 22),

        // ── Submit Button ────────────────────────────────────
        _buildSubmitButton(cs),

        const SizedBox(height: 14),

        // ── Toggle Sign Up / Sign In ───────────────────────
        _buildToggleLink(cs),

        const SizedBox(height: 20),

        // ── Guest Session ───────────────────────────────────
        _buildGuestButton(cs, isDark),

        const SizedBox(height: 4),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ── Individual Widget Builders ──
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCloseButton(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(Icons.close_rounded,
            color: cs.onSurface.withAlpha(80), size: 18),
        onPressed: () => Navigator.pop(context, false),
        splashRadius: 18,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  Widget _buildGoogleButton(ColorScheme cs, bool isDark) {
    final isActive = _activeButton == 'google' && _isLoading;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleGoogleLogin,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? cs.onSurface.withAlpha(18)
                    : const Color(0xFFDADCE0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 20 : 8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isActive) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                ] else ...[
                  // Real Google "G" logo using colored containers
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                ],
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF3C4043),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  cs.onSurface.withAlpha(18),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with email',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withAlpha(50),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.onSurface.withAlpha(18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text, ColorScheme cs) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: cs.onSurface.withAlpha(150),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildEmailField(ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHigh.withAlpha(80)
            : cs.surfaceContainerHigh.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withAlpha(isDark ? 10 : 15)),
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(color: cs.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'developer@example.com',
          hintStyle: TextStyle(
            color: cs.onSurface.withAlpha(40),
            fontSize: 13.5,
          ),
          prefixIcon: Icon(Icons.email_outlined,
              size: 17, color: cs.onSurface.withAlpha(60)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField(ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHigh.withAlpha(80)
            : cs.surfaceContainerHigh.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withAlpha(isDark ? 10 : 15)),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(color: cs.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: TextStyle(
            color: cs.onSurface.withAlpha(40),
            fontSize: 13.5,
          ),
          prefixIcon: Icon(Icons.lock_outline_rounded,
              size: 17, color: cs.onSurface.withAlpha(60)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 17,
              color: cs.onSurface.withAlpha(50),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme cs) {
    final isActive = _activeButton == 'email' && _isLoading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
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
        child: isActive
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSignUp ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isSignUp ? 'Create Account' : 'Sign In & Continue',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleLink(ColorScheme cs) {
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() {
            _isSignUp = !_isSignUp;
            _error = null;
          }),
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(100)),
              children: [
                TextSpan(
                  text: _isSignUp ? 'Already have an account? ' : 'New developer? ',
                ),
                TextSpan(
                  text: _isSignUp ? 'Sign In' : 'Create an account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestButton(ColorScheme cs, bool isDark) {
    final isActive = _activeButton == 'guest' && _isLoading;
    return Center(
      child: TextButton.icon(
        onPressed: _isLoading ? null : _handleGuestLogin,
        icon: isActive
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: cs.onSurface.withAlpha(80),
                ),
              )
            : Icon(Icons.explore_outlined,
                size: 16, color: cs.onSurface.withAlpha(80)),
        label: Text(
          'Try as Guest',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withAlpha(80),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ── Google "G" Logo Painter (4-color arc logo) ──
// ═══════════════════════════════════════════════════════════════════

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Blue (right quadrant)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.4, 1.2, true, paint,
    );

    // Green (bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.8, 1.2, true, paint,
    );

    // Yellow (left-bottom)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.0, 1.0, true, paint,
    );

    // Red (top-left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.0, 1.8, true, paint,
    );

    // Inner white circle (donut cutout)
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);

    // Blue bar on the right
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.48, h * 0.38, w * 0.52, h * 0.24),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
