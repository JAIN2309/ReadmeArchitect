/// Unified Splash Screen for Automated README Architect.
///
/// A single-source animated splash that works identically on both mobile
/// native and desktop web. Uses [TweenAnimationBuilder], [AnimatedBuilder],
/// and explicit [AnimationController] chains for a premium launch sequence.
///
/// Flow: main.dart → SplashScreen → (platform detect) → MobileScreen / DesktopScreen
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────

  /// Master orchestrator for the icon entrance (scale + rotate).
  late final AnimationController _iconController;

  /// Controls the title text slide-up + fade-in.
  late final AnimationController _titleController;

  /// Controls the subtitle fade-in.
  late final AnimationController _subtitleController;

  /// Controls the progress bar fill animation.
  late final AnimationController _progressController;

  /// Controls the shimmer sweep across the icon.
  late final AnimationController _shimmerController;

  /// Controls the final screen fade-out before navigation.
  late final AnimationController _exitController;

  // ── Tween-driven animations ────────────────────────────────────────────

  late final Animation<double> _iconScale;
  late final Animation<double> _iconRotation;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _progressValue;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // ── Icon: scale from 0 → 1 with a spring-like overshoot, rotate 360° ──
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
    _iconRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutCubic),
    );

    // ── Title: slide up from +30px and fade in ──
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );

    // ── Subtitle: simple fade ──
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn),
    );

    // ── Progress bar: 0% → 100% ──
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // ── Shimmer: continuous sweep over the icon ──
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // ── Exit: fade the whole screen out ──
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInQuad),
    );

    // ── Kick off the staggered sequence ──
    _runSplashSequence();
  }

  Future<void> _runSplashSequence() async {
    // Stage 1: Icon entrance
    _iconController.forward();
    await Future.delayed(const Duration(milliseconds: 600));

    // Stage 2: Title slides up
    _titleController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // Stage 3: Subtitle fades in
    _subtitleController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // Stage 4: Progress bar fills
    await _progressController.forward().orCancel; // wait for it to finish

    // Stage 5: Exit fade
    await Future.delayed(const Duration(milliseconds: 200));
    await _exitController.forward().orCancel;

    // Stage 6: Navigate
    if (mounted) _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _progressController.dispose();
    _shimmerController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _exitFade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Animated icon with shimmer ──
              AnimatedBuilder(
                animation: Listenable.merge([_iconController, _shimmerController]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _iconScale.value,
                    child: Transform.rotate(
                      angle: _iconRotation.value * math.pi,
                      child: _buildShimmerIcon(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 36),

              // ── Title ──
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Text(
                      'README Architect',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // ── Subtitle ──
              FadeTransition(
                opacity: _subtitleFade,
                child: Text(
                  'AI-Powered Documentation Generator',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurface.withAlpha(130),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ── Animated progress bar ──
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return _buildProgressBar(_progressValue.value);
                },
              ),

              const SizedBox(height: 16),

              // ── Loading label ──
              FadeTransition(
                opacity: _subtitleFade,
                child: TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: 3),
                  duration: const Duration(milliseconds: 2000),
                  builder: (context, value, _) {
                    final dots = '.' * ((value % 3) + 1);
                      return Text(
                        'Initializing$dots',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withAlpha(80),
                          letterSpacing: 0.8,
                        ),
                      );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icon container with a sweeping shimmer highlight.
  Widget _buildShimmerIcon() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [theme.colorScheme.surfaceContainerHigh, theme.colorScheme.surface],
          radius: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withAlpha(80),
            blurRadius: 40,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: primary.withAlpha(40),
            blurRadius: 80,
            spreadRadius: 8,
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (bounds) {
          final sweep = _shimmerController.value * 3 - 1; // -1 → 2
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Colors.white24,
              Colors.white70,
              Colors.white24,
            ],
            stops: [
              (sweep - 0.3).clamp(0.0, 1.0),
              sweep.clamp(0.0, 1.0),
              (sweep + 0.3).clamp(0.0, 1.0),
            ],
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcATop,
        child: Center(
          child: Icon(
            Icons.auto_awesome,
            size: 44,
            color: primary,
          ),
        ),
      ),
    );
  }

  /// Custom animated progress bar with gradient fill.
  Widget _buildProgressBar(double value) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: theme.colorScheme.onSurface.withAlpha(15),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [primary, primary.withAlpha(200), primary.withAlpha(150)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withAlpha(100),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
