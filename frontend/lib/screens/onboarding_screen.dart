/// Onboarding guide for the Automated README Architect.
///
/// A premium 5-step walkthrough matching the Settings dialog design language.
/// Responsive: card-based layout on desktop, full-screen swipe on mobile.
/// Flow: SplashScreen → OnboardingScreen → MobileScreen / DesktopScreen
library;

import 'package:flutter/material.dart';
import '../utils/platform_detector.dart';
import 'mobile_screen.dart';
import 'desktop_screen.dart';

// ── Step Data Model ────────────────────────────────────────────────────

class _OnboardingStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<_FeatureItem> features;

  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
  });
}

class _FeatureItem {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});
}

// ── Step Definitions ───────────────────────────────────────────────────

const List<_OnboardingStep> _onboardingSteps = [
  _OnboardingStep(
    icon: Icons.link_rounded,
    title: 'Paste Repository URL',
    subtitle: 'Step 1 of 5',
    description:
        'Enter any public GitHub repository link. Our engine fetches the raw source code and project structure for deep analysis.',
    features: [
      _FeatureItem(icon: Icons.public_rounded, label: 'Any public GitHub repo'),
      _FeatureItem(icon: Icons.speed_rounded, label: 'Instant repo scanning'),
      _FeatureItem(
          icon: Icons.account_tree_rounded, label: 'Full structure analysis'),
    ],
  ),
  _OnboardingStep(
    icon: Icons.tune_rounded,
    title: 'Select Presentation Mode',
    subtitle: 'Step 2 of 5',
    description:
        'Choose between Basic, Advanced, or Professional modes. Each tailored for different documentation needs.',
    features: [
      _FeatureItem(icon: Icons.article_rounded, label: 'Basic — Simple tools'),
      _FeatureItem(
          icon: Icons.dashboard_rounded, label: 'Advanced — Portfolios'),
      _FeatureItem(
          icon: Icons.business_center_rounded,
          label: 'Professional — Enterprise'),
    ],
  ),
  _OnboardingStep(
    icon: Icons.edit_note_rounded,
    title: 'Live Generation & Editing',
    subtitle: 'Step 3 of 5',
    description:
        'Watch AI architect your README in real-time, then refine it in our split-pane markdown editor.',
    features: [
      _FeatureItem(
          icon: Icons.auto_awesome_rounded, label: 'AI-powered generation'),
      _FeatureItem(
          icon: Icons.vertical_split_rounded, label: 'Split-pane editor'),
      _FeatureItem(
          icon: Icons.preview_rounded, label: 'Live markdown preview'),
    ],
  ),
  _OnboardingStep(
    icon: Icons.merge_type_rounded,
    title: 'Direct GitHub PRs',
    subtitle: 'Step 4 of 5',
    description:
        'Connect your Personal Access Token and push your polished README directly to your repository as a Pull Request.',
    features: [
      _FeatureItem(
          icon: Icons.vpn_key_rounded, label: 'Secure token storage'),
      _FeatureItem(
          icon: Icons.call_merge_rounded, label: 'One-click PR creation'),
      _FeatureItem(
          icon: Icons.verified_rounded, label: 'Branch-safe operations'),
    ],
  ),
  _OnboardingStep(
    icon: Icons.inventory_2_rounded,
    title: 'Export & History',
    subtitle: 'Step 5 of 5',
    description:
        'Copy to clipboard, download as .md, or revisit past generations from the history panel anytime.',
    features: [
      _FeatureItem(
          icon: Icons.content_copy_rounded, label: 'Copy to clipboard'),
      _FeatureItem(
          icon: Icons.download_rounded, label: 'Download as .md file'),
      _FeatureItem(
          icon: Icons.history_rounded, label: 'Generation history'),
    ],
  ),
];

// ── Onboarding Screen ──────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _contentAnim;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _contentAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade = CurvedAnimation(
      parent: _contentAnim,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnim,
      curve: Curves.easeOutCubic,
    ));
    _contentAnim.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentAnim.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _contentAnim.reset();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    _contentAnim.forward();
  }

  void _nextPage() {
    if (_currentPage < _onboardingSteps.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _finishOnboarding() {
    final platform = PlatformDetector.detect();
    final destination = switch (platform) {
      AppPlatform.mobileNative => const MobileScreen(),
      AppPlatform.desktopWeb => const DesktopScreen(),
    };

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  // ── Desktop Layout ──────────────────────────────────────────────────

  Widget _buildDesktopLayout() {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth > 1000 ? 560.0 : 480.0).clamp(400.0, 600.0);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Main Card ──
          Container(
            width: cardWidth,
            constraints: const BoxConstraints(maxHeight: 560),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header bar ──
                _buildCardHeader(cs, cardWidth),
                Divider(height: 1, color: cs.onSurface.withAlpha(12)),

                // ── Step Content (PageView) ──
                Flexible(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) {
                      setState(() => _currentPage = idx);
                      _contentAnim.reset();
                      _contentAnim.forward();
                    },
                    itemCount: _onboardingSteps.length,
                    itemBuilder: (context, index) {
                      return SlideTransition(
                        position: _contentSlide,
                        child: FadeTransition(
                          opacity: _contentFade,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
                            child: _buildStepContent(
                                _onboardingSteps[index], cs, false),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Divider(height: 1, color: cs.onSurface.withAlpha(12)),

                // ── Footer ──
                _buildCardFooter(cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(ColorScheme cs, double cardWidth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 16),
      child: Row(
        children: [
          // Logo + Title
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to README Architect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quick walkthrough • ${_currentPage + 1} of ${_onboardingSteps.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),
          // Skip
          TextButton(
            onPressed: _finishOnboarding,
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurface.withAlpha(120),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Skip',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFooter(ColorScheme cs) {
    final isLast = _currentPage == _onboardingSteps.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
      child: Row(
        children: [
          // ── Step dots ──
          Row(
            children: List.generate(
              _onboardingSteps.length,
              (i) => GestureDetector(
                onTap: () => _goToPage(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(right: 6),
                  height: 6,
                  width: _currentPage == i ? 24 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? cs.primary
                        : cs.onSurface.withAlpha(30),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),

          // ── Back button ──
          if (_currentPage > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: OutlinedButton(
                onPressed: _prevPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface.withAlpha(160),
                  side: BorderSide(color: cs.onSurface.withAlpha(25)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Back',
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ),
            ),

          // ── Next / Get Started button ──
          ElevatedButton.icon(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            icon: Icon(
              isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
              size: 16,
            ),
            label: Text(
              isLast ? 'Get Started' : 'Next',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile Layout ────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ── Top bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: cs.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'README Architect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              TextButton(
                onPressed: _finishOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: cs.onSurface.withAlpha(120),
                ),
                child: const Text('Skip',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),

        // ── Progress bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _buildProgressBar(cs),
        ),

        // ── Content (PageView) ──
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) {
              setState(() => _currentPage = idx);
              _contentAnim.reset();
              _contentAnim.forward();
            },
            itemCount: _onboardingSteps.length,
            itemBuilder: (context, index) {
              return SlideTransition(
                position: _contentSlide,
                child: FadeTransition(
                  opacity: _contentFade,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: _buildStepContent(
                        _onboardingSteps[index], cs, true),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Bottom actions ──
        _buildMobileFooter(cs),
      ],
    );
  }

  Widget _buildProgressBar(ColorScheme cs) {
    final progress = (_currentPage + 1) / _onboardingSteps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _onboardingSteps[_currentPage].subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.primary,
              ),
            ),
            Text(
              '${(_currentPage + 1)}/${_onboardingSteps.length}',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(80),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: cs.onSurface.withAlpha(15),
            borderRadius: BorderRadius.circular(2),
          ),
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withAlpha(180)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooter(ColorScheme cs) {
    final isLast = _currentPage == _onboardingSteps.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.onSurface.withAlpha(10)),
        ),
      ),
      child: Row(
        children: [
          // ── Back ──
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface.withAlpha(160),
                  side: BorderSide(color: cs.onSurface.withAlpha(25)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back',
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),

          // ── Next / Get Started ──
          Expanded(
            flex: _currentPage > 0 ? 2 : 1,
            child: ElevatedButton.icon(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: Icon(
                isLast
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: Text(
                isLast ? 'Get Started' : 'Continue',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Step Content ──────────────────────────────────────────────

  Widget _buildStepContent(
      _OnboardingStep step, ColorScheme cs, bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Icon badge ──
        Center(
          child: Container(
            width: isMobile ? 80 : 72,
            height: isMobile ? 80 : 72,
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(15),
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary.withAlpha(30), width: 1.5),
            ),
            child: Icon(
              step.icon,
              size: isMobile ? 36 : 32,
              color: cs.primary,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Step label ──
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.primary.withAlpha(30)),
            ),
            child: Text(
              step.subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.primary,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Title ──
        Center(
          child: Text(
            step.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 22 : 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Description ──
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              step.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withAlpha(140),
                height: 1.6,
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ── Feature list card ──
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHigh
                : cs.surfaceContainerHigh.withAlpha(120),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withAlpha(isDark ? 12 : 20)),
          ),
          child: Column(
            children: step.features.asMap().entries.map((entry) {
              final idx = entry.key;
              final feature = entry.value;
              final isLast = idx == step.features.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cs.primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(feature.icon,
                              size: 16, color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface.withAlpha(200),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: const Color(0xFF22C55E).withAlpha(180),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 48,
                      color: cs.onSurface.withAlpha(10),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
