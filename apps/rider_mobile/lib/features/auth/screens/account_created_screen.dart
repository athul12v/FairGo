// lib/features/auth/screens/account_created_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/router/app_router.dart';

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0058BB),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Center(
                          child: Text(
                            'F',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Fair',
                              style: TextStyle(
                                color: Color(0xFF191C1E),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'GO',
                              style: TextStyle(
                                color: Color(0xFF0058BB),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Inter',
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: ' •',
                              style: TextStyle(
                                color: Color(0xFF1471E6),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // Success Icon with Radiant Ripple
              Center(
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFDCFCE7),
                    border: Border.all(
                      color: const Color(0xFF86EFAC).withOpacity(0.5),
                      width: 8,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                      size: 58,
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Account Created! ✅',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF191C1E),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                  letterSpacing: -0.6,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Welcome to FairGO. Your rider profile is ready with transparent fares, zero-surge guarantees, and reliable rides.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF4C4546),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Inter',
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const Spacer(flex: 3),

              // Single Primary CTA: Start Riding
              Material(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                elevation: 2,
                shadowColor: Colors.black38,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go(AppRoutes.home);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Start Riding',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
