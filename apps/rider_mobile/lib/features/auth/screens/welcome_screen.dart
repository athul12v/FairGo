// lib/features/auth/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/providers/auth_provider.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    HapticFeedback.lightImpact();

    try {
      await ref.read(authStateNotifierProvider.notifier).signInWithGoogle();
      if (mounted) {
        // Router redirect handles navigation to AppRoutes.home upon authentication
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Navigation & Brand Header
              _buildHeader(context)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              // Hero Visual Stage Card
              _buildHeroStage()
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 500.ms)
                  .scale(begin: const Offset(0.97, 0.97)),

              const SizedBox(height: 24),

              // Narrative Header
              _buildNarrativeHeader()
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 450.ms)
                  .slideX(begin: -0.05, end: 0),

              const SizedBox(height: 24),

              // Interactive Action Deck
              _buildActionDeck(context)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 450.ms)
                  .slideY(begin: 0.05, end: 0),

              const SizedBox(height: 20),

              // Trust Indicator Section
              _buildTrustSection()
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: 16),

              // Legal Notice Footer
              _buildLegalFooter(context)
                  .animate()
                  .fadeIn(delay: 450.ms, duration: 400.ms),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Header with Brand Logo & Help Pill Button
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // FairGO Logo Mark
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF0058BB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'F',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
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
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      letterSpacing: -0.6,
                    ),
                  ),
                  TextSpan(
                    text: 'GO',
                    style: TextStyle(
                      color: Color(0xFF0058BB),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                      letterSpacing: -0.6,
                    ),
                  ),
                  TextSpan(
                    text: ' •',
                    style: TextStyle(
                      color: Color(0xFF1471E6),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Help Button
        Material(
          color: const Color(0xFFF2F4F6),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(AppRoutes.support),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Text(
                'Help',
                style: TextStyle(
                  color: Color(0xFF4C4546),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Hero Card with Ambient Waves & Electric Ride Capsule
  Widget _buildHeroStage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Ambient Wave
          Positioned.fill(
            child: CustomPaint(
              painter: _AmbientWavePainter(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                // Top Hero Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sustainability Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF009844),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            '100% Carbon Neutral',
                            style: TextStyle(
                              color: Color(0xFF191C1E),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Zero Surge Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8E2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.verified,
                            color: Color(0xFF0058BB),
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Zero Surge Promise',
                            style: TextStyle(
                              color: Color(0xFF001A41),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Central Ride Capsule Canvas
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Soft Pulse Ring
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFADC7FF).withOpacity(0.2),
                          ),
                        ),

                        // Center Capsule Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Vehicle Icon Square
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDEEF0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.electric_car_rounded,
                                    color: Color(0xFF0058BB),
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Ride Details
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text(
                                          'FairGO Electric',
                                          style: TextStyle(
                                            color: Color(0xFF191C1E),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        Text(
                                          '₹249',
                                          style: TextStyle(
                                            color: Color(0xFF0058BB),
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.eco,
                                          color: Color(0xFF009844),
                                          size: 13,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'Locked flat fare • 3 min pickup',
                                          style: TextStyle(
                                            color: Color(0xFF7E7576),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Floating Fixed Rate Badge (Top Right)
                        Positioned(
                          top: -6,
                          right: 14,
                          child: Transform.rotate(
                            angle: 0.04,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFADC7FF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Fixed Rate',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Floating Surge Multiplier Badge (Bottom Left)
                        Positioned(
                          bottom: -6,
                          left: 14,
                          child: Transform.rotate(
                            angle: -0.02,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.trending_flat,
                                    color: Color(0xFF0058BB),
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '0.0x Surge Multiplier',
                                    style: TextStyle(
                                      color: Color(0xFF191C1E),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Micro City Skyline Ticker
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFE1E2E4),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCityTickerItem(
                          Icons.near_me_outlined, 'Downtown'),
                      _buildCityTickerItem(
                          Icons.flight_takeoff_rounded, 'Airport Express'),
                      _buildCityTickerItem(
                          Icons.domain_rounded, 'Tech District'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityTickerItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF191C1E)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4C4546),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  // Narrative Header: Headline & Subheading
  Widget _buildNarrativeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Everyday mobility,\nfairly priced.',
          style: TextStyle(
            color: Color(0xFF191C1E),
            fontSize: 30,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
            height: 1.18,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'No hidden surge pricing. Transparent fares and clean, reliable rides across your city.',
          style: TextStyle(
            color: Color(0xFF4C4546),
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
            fontFamily: 'Inter',
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // Authentication Actions
  Widget _buildActionDeck(BuildContext context) {
    return Column(
      children: [
        // Primary CTA: Continue with Phone Number
        Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          shadowColor: Colors.black38,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.phoneEntry);
            },
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF222222),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Continue with Phone Number',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFFC6C6C6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Split Divider: OR SIGN IN WITH
        Row(
          children: const [
            Expanded(
              child: Divider(
                color: Color(0xFFE1E2E4),
                thickness: 0.8,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'OR SIGN IN WITH',
                style: TextStyle(
                  color: Color(0xFF7E7576),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Color(0xFFE1E2E4),
                thickness: 0.8,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Secondary CTA: Continue with Google
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE1E2E4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: _isGoogleLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF0058BB),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleLogoSvg(),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: Color(0xFF191C1E),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Tertiary CTA: Continue with Email ->
        Center(
          child: TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.phoneEntry, extra: 'email');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Continue with Email →',
              style: TextStyle(
                color: Color(0xFF0058BB),
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Trust Indicator
  Widget _buildTrustSection() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDEFE2).withOpacity(0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.verified_outlined,
              size: 14,
              color: Color(0xFF009844),
            ),
            SizedBox(width: 6),
            Text(
              'Trusted by riders across Kerala • Zero surge guarantee',
              style: TextStyle(
                color: Color(0xFF4C4546),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Legal Notice Footer
  Widget _buildLegalFooter(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text.rich(
          TextSpan(
            text: 'By continuing, you agree to FairGO\'s ',
            style: const TextStyle(
              color: Color(0xFF7E7576),
              fontSize: 12,
              fontFamily: 'Inter',
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: 'Terms of Service',
                style: const TextStyle(
                  color: Color(0xFF191C1E),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: const TextStyle(
                  color: Color(0xFF191C1E),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Vector Google 4-color 'G' icon
  Widget _buildGoogleLogoSvg() {
    const googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="22" height="22">
  <path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17z"/>
  <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z"/>
  <path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.18 0 10.04 0 12s.45 3.82 1.25 5.42l4.03-3.15z"/>
  <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"/>
</svg>
''';
    return SvgPicture.string(
      googleSvg,
      width: 20,
      height: 20,
    );
  }
}

// Custom Painter for Ambient Wave in Hero Stage
class _AmbientWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFD8E2FF).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.7)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.45,
        size.width * 0.45,
        size.height * 0.9,
        size.width * 0.75,
        size.height * 0.6,
      )
      ..cubicTo(
        size.width * 0.9,
        size.height * 0.4,
        size.width * 0.95,
        size.height * 0.55,
        size.width,
        size.height * 0.45,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFF1471E6).withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height * 0.78)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.55,
        size.width * 0.5,
        size.height * 0.85,
        size.width * 0.75,
        size.height * 0.65,
      )
      ..cubicTo(
        size.width * 0.9,
        size.height * 0.5,
        size.width * 0.95,
        size.height * 0.6,
        size.width,
        size.height * 0.55,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
