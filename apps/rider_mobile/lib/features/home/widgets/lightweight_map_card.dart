// lib/features/home/widgets/lightweight_map_card.dart

import 'package:flutter/material.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class LightweightMapCard extends StatefulWidget {
  final String locationText;
  final VoidCallback? onTap;

  const LightweightMapCard({
    super.key,
    required this.locationText,
    this.onTap,
  });

  @override
  State<LightweightMapCard> createState() => _LightweightMapCardState();
}

class _LightweightMapCardState extends State<LightweightMapCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutQuad,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EFEA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE5E2DA),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Lightweight Vector Map Graphics (roads, blocks, water)
            Positioned.fill(
              child: CustomPaint(
                painter: _VectorMapPainter(),
              ),
            ),

            // Pulsing Pickup Pin in the center
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer animated ripple
                      Container(
                        width: 24 + (_pulseAnimation.value * 38),
                        height: 24 + (_pulseAnimation.value * 38),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0058BB).withValues(
                            alpha: (1.0 - _pulseAnimation.value) * 0.28,
                          ),
                        ),
                      ),
                      // Inner solid marker dot
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0058BB),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0058BB).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Floating Location Pill (bottom-left)
            Positioned(
              left: 14,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E2DA), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      size: 13,
                      color: Color(0xFF0058BB),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        widget.locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Subtle "Tap to explore" badge (top-right)
            Positioned(
              right: 12,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      size: 11,
                      color: AppColors.onSurfaceMuted,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Live Area',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VectorMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final parkPaint = Paint()
      ..color = const Color(0xFFE2EEDF)
      ..style = PaintingStyle.fill;

    final waterPaint = Paint()
      ..color = const Color(0xFFDCEAF5)
      ..style = PaintingStyle.fill;

    final primaryRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFFFAF9F6)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFDFDDD4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw gentle park polygon on top left
    final parkPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.32, 0)
      ..lineTo(size.width * 0.28, size.height * 0.45)
      ..lineTo(0, size.height * 0.38)
      ..close();
    canvas.drawPath(parkPath, parkPaint);

    // Draw small river/canal curve on bottom right
    final waterPath = Path()
      ..moveTo(size.width * 0.78, size.height)
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.6,
        size.width,
        size.height * 0.5,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // Main Avenue 1 (diagonal left-bottom to right-top)
    final avenue1 = Path()
      ..moveTo(-20, size.height * 0.8)
      ..lineTo(size.width + 20, size.height * 0.2);
    canvas.drawPath(avenue1, primaryRoadPaint);
    canvas.drawPath(avenue1, roadBorderPaint);

    // Main Avenue 2 (diagonal top-left to bottom-right through center)
    final avenue2 = Path()
      ..moveTo(size.width * 0.15, -10)
      ..lineTo(size.width * 0.85, size.height + 10);
    canvas.drawPath(avenue2, primaryRoadPaint);
    canvas.drawPath(avenue2, roadBorderPaint);

    // Cross Street 1
    final street1 = Path()
      ..moveTo(-10, size.height * 0.35)
      ..lineTo(size.width + 10, size.height * 0.55);
    canvas.drawPath(street1, secondaryRoadPaint);

    // Cross Street 2
    final street2 = Path()
      ..moveTo(size.width * 0.48, -10)
      ..lineTo(size.width * 0.35, size.height + 10);
    canvas.drawPath(street2, secondaryRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
