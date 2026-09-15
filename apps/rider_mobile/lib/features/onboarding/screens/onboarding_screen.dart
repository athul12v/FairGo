// lib/features/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/providers/auth_provider.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/cross_platform_shell.dart';
import 'package:rider_app/core/widgets/fairgo_illustrations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Enjoy with us,\nand discover the\njoy of a hassle\nfree ride.',
      'subtitle':
          'Sit back, relax and enjoy the ride. Your satisfaction is our priority.',
    },
    {
      'title': 'Fair transparent\npricing with zero\nsurge abuse.',
      'subtitle':
          '100% breakdown of your fare upfront. No hidden surges, ever.',
    },
    {
      'title': 'Multiple ways\nto travel and\ndeliver quickly.',
      'subtitle':
          'Cabs, autos, bikes, parcels or hire a chauffeur for your car.',
    },
  ];

  Future<void> _onContinue() async {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      await ref.read(authStateNotifierProvider.notifier).completeOnboarding();
      if (mounted) context.go(AppRoutes.phoneEntry);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CrossPlatformShell(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(authStateNotifierProvider.notifier)
                          .completeOnboarding();
                      if (!mounted) return;
                      context.go(AppRoutes.phoneEntry);
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ],
              ),

              // Page Content (Headline + Subtitle)
              Expanded(
                flex: 4,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slide['title']!,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                color: AppColors.onBackground,
                                letterSpacing: -0.5,
                              ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 16),
                        Text(
                          slide['subtitle']!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.onSurfaceMuted,
                                height: 1.5,
                                fontSize: 15,
                              ),
                        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                      ],
                    );
                  },
                ),
              ),

              // Hero Illustration (Retro Scooter Rider)
              Expanded(
                flex: 5,
                child: Center(
                  child: const RetroScooterRiderIllustration(
                    width: 240,
                    height: 180,
                    showPassenger: false,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                ),
              ),

              // Bottom Indicator & Terracotta CTA
              Row(
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 8),
                    height: 6,
                    width: _currentPage == i ? 24 : 6,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.primary
                          : AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentPage == _slides.length - 1 ? 'Get Started' : 'Continue',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
