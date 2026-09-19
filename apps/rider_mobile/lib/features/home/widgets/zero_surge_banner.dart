// lib/features/home/widgets/zero_surge_banner.dart

import 'package:flutter/material.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class ZeroSurgeBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const ZeroSurgeBanner({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE1E2E4),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Ambient wave decorative background
            Positioned.fill(
              child: CustomPaint(
                painter: _BannerWavePainter(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Tag
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0058BB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: Color(0xFF0058BB),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'FairGO Promise',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0058BB),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 13,
                              color: Color(0xFF059669),
                            ),
                            SizedBox(width: 3),
                            Text(
                              '100% Electric Option',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  const Text(
                    'Zero Surge Pricing. Ever.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: Color(0xFF191C1E),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Subtitle
                  const Text(
                    'No 2x or 3x multiplier surprises during peak hours, rain, or busy weekends. Consistent & transparent fares for every commute.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = const Color(0xFF0058BB).withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.4, 0)
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.35,
        size.width * 0.55,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
