// lib/features/home/widgets/home_map_background.dart

import 'package:flutter/material.dart';

class HomeMapBackground extends StatefulWidget {
  final VoidCallback? onSafetyTap;
  final VoidCallback? onRecenterTap;

  const HomeMapBackground({
    super.key,
    this.onSafetyTap,
    this.onRecenterTap,
  });

  @override
  State<HomeMapBackground> createState() => _HomeMapBackgroundState();
}

class _HomeMapBackgroundState extends State<HomeMapBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _radarAnimation = CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeOutQuad,
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Lightweight Map Background Canvas
        Positioned.fill(
          child: Container(
            color: const Color(0xFFF1EFEA),
            child: CustomPaint(
              painter: _MapGridPainter(),
            ),
          ),
        ),

        // Centered Pulsing User Location Beacon (Image 3 pattern)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: AnimatedBuilder(
              animation: _radarAnimation,
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer radar ring
                    Container(
                      width: 32 + (_radarAnimation.value * 64),
                      height: 32 + (_radarAnimation.value * 64),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0058BB).withValues(
                          alpha: (1.0 - _radarAnimation.value) * 0.22,
                        ),
                      ),
                    ),
                    // Inner accent aura
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0058BB).withValues(alpha: 0.15),
                      ),
                    ),
                    // Solid location dot
                    Container(
                      width: 18,
                      height: 18,
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
        ),

        // Floating Map Action Buttons (Bottom Right, directly above bottom sheet)
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Safety Center FAB
              _buildMapFab(
                icon: Icons.shield_outlined,
                color: const Color(0xFF0058BB),
                tooltip: 'Safety Center',
                onTap: widget.onSafetyTap,
              ),
              const SizedBox(height: 10),
              // Recenter GPS FAB
              _buildMapFab(
                icon: Icons.my_location_rounded,
                color: const Color(0xFF191C1E),
                tooltip: 'Recenter GPS',
                onTap: widget.onRecenterTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapFab({
    required IconData icon,
    required Color color,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final parkPaint = Paint()
      ..color = const Color(0xFFE5EEE2)
      ..style = PaintingStyle.fill;

    final waterPaint = Paint()
      ..color = const Color(0xFFDDE8F4)
      ..style = PaintingStyle.fill;

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFDFDDD4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = const Color(0xFFFAF9F6)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Subtle park shape
    final park = Path()
      ..moveTo(0, size.height * 0.1)
      ..lineTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.28, size.height * 0.35)
      ..lineTo(0, size.height * 0.3)
      ..close();
    canvas.drawPath(park, parkPaint);

    // Subtle river / water bend
    final water = Path()
      ..moveTo(size.width * 0.72, size.height)
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.45,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(water, waterPaint);

    // Major road 1
    final road1 = Path()
      ..moveTo(-10, size.height * 0.45)
      ..lineTo(size.width + 10, size.height * 0.35);
    canvas.drawPath(road1, roadPaint);
    canvas.drawPath(road1, roadBorderPaint);

    // Major road 2 (crossing)
    final road2 = Path()
      ..moveTo(size.width * 0.2, -10)
      ..lineTo(size.width * 0.8, size.height + 10);
    canvas.drawPath(road2, roadPaint);
    canvas.drawPath(road2, roadBorderPaint);

    // Minor cross streets
    final road3 = Path()
      ..moveTo(size.width * 0.45, -10)
      ..lineTo(size.width * 0.35, size.height + 10);
    canvas.drawPath(road3, minorRoadPaint);

    final road4 = Path()
      ..moveTo(-10, size.height * 0.7)
      ..lineTo(size.width + 10, size.height * 0.6);
    canvas.drawPath(road4, minorRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
