import 'package:flutter/material.dart';
import 'package:rider_app/core/theme/app_theme.dart';

/// 1. Retro Scooter Rider (Hero Card & Onboarding Splash)
class RetroScooterRiderIllustration extends StatelessWidget {
  final double width;
  final double height;
  final bool showPassenger;

  const RetroScooterRiderIllustration({
    super.key,
    this.width = 180,
    this.height = 140,
    this.showPassenger = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _ScooterRiderPainter(showPassenger: showPassenger),
      ),
    );
  }
}

class _ScooterRiderPainter extends CustomPainter {
  final bool showPassenger;

  _ScooterRiderPainter({required this.showPassenger});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1B1D21)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillCream = Paint()
      ..color = const Color(0xFFFAF7F2)
      ..style = PaintingStyle.fill;

    final fillTeal = Paint()
      ..color = const Color(0xFF4FA090)
      ..style = PaintingStyle.fill;

    final fillTerracotta = Paint()
      ..color = const Color(0xFFD95A47)
      ..style = PaintingStyle.fill;

    final fillOchre = Paint()
      ..color = const Color(0xFFE2A654)
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 180;
    final scaleY = size.height / 140;
    canvas.scale(scaleX, scaleY);

    // 1. Scooter wheels
    // Back wheel
    canvas.drawCircle(const Offset(45, 110), 16, strokePaint);
    canvas.drawCircle(const Offset(45, 110), 8, fillCream);
    canvas.drawCircle(const Offset(45, 110), 8, strokePaint);
    canvas.drawCircle(const Offset(45, 110), 3, strokePaint);

    // Front wheel
    canvas.drawCircle(const Offset(140, 110), 16, strokePaint);
    canvas.drawCircle(const Offset(140, 110), 8, fillCream);
    canvas.drawCircle(const Offset(140, 110), 8, strokePaint);
    canvas.drawCircle(const Offset(140, 110), 3, strokePaint);

    // 2. Scooter body chassis
    final bodyPath = Path()
      ..moveTo(35, 110)
      ..quadraticBezierTo(40, 85, 75, 88)
      ..lineTo(95, 105)
      ..lineTo(125, 105)
      ..quadraticBezierTo(135, 90, 138, 70)
      ..lineTo(145, 110)
      ..close();
    canvas.drawPath(bodyPath, fillCream);
    canvas.drawPath(bodyPath, strokePaint);

    // Scooter footboard
    final footboard = Path()
      ..moveTo(80, 106)
      ..lineTo(125, 106);
    canvas.drawPath(footboard, strokePaint);

    // Scooter seat
    final seatPath = Path()
      ..moveTo(48, 84)
      ..quadraticBezierTo(70, 78, 85, 84)
      ..lineTo(85, 88)
      ..lineTo(48, 88)
      ..close();
    canvas.drawPath(seatPath, strokePaint);

    // Steering column & handlebars
    final steerPath = Path()
      ..moveTo(135, 98)
      ..lineTo(130, 58)
      ..lineTo(124, 56);
    canvas.drawPath(steerPath, strokePaint);

    // Headlight
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(136, 62), width: 10, height: 14),
      fillCream,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(136, 62), width: 10, height: 14),
      strokePaint,
    );

    // Exhaust pipe with gentle speed lines
    final exhaust = Path()
      ..moveTo(55, 114)
      ..lineTo(22, 114)
      ..quadraticBezierTo(18, 114, 18, 110);
    canvas.drawPath(exhaust, strokePaint);

    // Speed puffs
    canvas.drawLine(const Offset(12, 110), const Offset(4, 110), strokePaint);
    canvas.drawLine(const Offset(14, 116), const Offset(8, 116), strokePaint);

    // 3. Driver (Scooter Driver)
    // Driver Torso (Teal jacket)
    final driverTorso = Path()
      ..moveTo(96, 52)
      ..lineTo(112, 52)
      ..lineTo(115, 85)
      ..lineTo(92, 85)
      ..close();
    canvas.drawPath(driverTorso, fillTeal);
    canvas.drawPath(driverTorso, strokePaint);

    // Driver Arm reaching to handlebar
    final driverArm = Path()
      ..moveTo(102, 58)
      ..quadraticBezierTo(116, 65, 126, 59);
    canvas.drawPath(driverArm, strokePaint);

    // Driver Leg
    final driverLeg = Path()
      ..moveTo(98, 85)
      ..lineTo(104, 104);
    canvas.drawPath(driverLeg, strokePaint);

    // Driver Head & Sunglasses
    // Neck
    canvas.drawLine(const Offset(104, 52), const Offset(104, 46), strokePaint);
    // Face outline
    final faceRect = Rect.fromCenter(center: const Offset(105, 38), width: 18, height: 20);
    canvas.drawOval(faceRect, fillCream);
    canvas.drawOval(faceRect, strokePaint);
    // Cool retro sunglasses
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(101, 35, 11, 6), const Radius.circular(2)),
      Paint()..color = const Color(0xFF1B1D21),
    );
    // Helmet / Cap
    final helmetPath = Path()
      ..moveTo(95, 38)
      ..quadraticBezierTo(105, 24, 115, 36)
      ..close();
    canvas.drawPath(helmetPath, fillOchre);
    canvas.drawPath(helmetPath, strokePaint);

    // 4. Passenger (if requested for hero banner)
    if (showPassenger) {
      // Passenger Torso (Terracotta jacket)
      final passTorso = Path()
        ..moveTo(68, 56)
        ..lineTo(84, 56)
        ..lineTo(86, 85)
        ..lineTo(68, 85)
        ..close();
      canvas.drawPath(passTorso, fillTerracotta);
      canvas.drawPath(passTorso, strokePaint);

      // Passenger Arm around driver
      final passArm = Path()
        ..moveTo(76, 62)
        ..quadraticBezierTo(88, 64, 94, 60);
      canvas.drawPath(passArm, strokePaint);

      // Passenger Head
      canvas.drawLine(const Offset(76, 56), const Offset(76, 50), strokePaint);
      final passFace = Rect.fromCenter(center: const Offset(76, 42), width: 17, height: 19);
      canvas.drawOval(passFace, fillCream);
      canvas.drawOval(passFace, strokePaint);

      // Passenger hair / headband
      final passHair = Path()
        ..moveTo(67, 43)
        ..quadraticBezierTo(76, 30, 85, 41)
        ..close();
      canvas.drawPath(passHair, fillOchre);
      canvas.drawPath(passHair, strokePaint);
    } else {
      // Single rider with backpack (matches onboarding screen)
      final backpack = Path()
        ..moveTo(88, 56)
        ..quadraticBezierTo(80, 65, 84, 80)
        ..lineTo(92, 80)
        ..close();
      canvas.drawPath(backpack, fillOchre);
      canvas.drawPath(backpack, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScooterRiderPainter oldDelegate) =>
      oldDelegate.showPassenger != showPassenger;
}

/// 2. Sleek Retro Coupe Car Illustration (Car Details / Reservation Screen)
class RetroCoupeCarIllustration extends StatelessWidget {
  final double width;
  final double height;

  const RetroCoupeCarIllustration({
    super.key,
    this.width = 320,
    this.height = 130,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _RetroCoupePainter()),
    );
  }
}

class _RetroCoupePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1B1D21)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillBody = Paint()
      ..color = const Color(0xFFFAF7F2)
      ..style = PaintingStyle.fill;

    final fillWheelRim = Paint()
      ..color = const Color(0xFFE2A654)
      ..style = PaintingStyle.fill;

    final fillGlass = Paint()
      ..color = const Color(0xFFE9F1F5)
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 320;
    final scaleY = size.height / 130;
    canvas.scale(scaleX, scaleY);

    // Ground shadow
    canvas.drawLine(
      const Offset(20, 105),
      const Offset(300, 105),
      Paint()
        ..color = const Color(0xFFE5DFD5)
        ..strokeWidth = 2,
    );

    // Car Body Silhouette
    final body = Path()
      ..moveTo(25, 88)
      ..lineTo(40, 88)
      // Front wheel arch
      ..arcToPoint(const Offset(85, 88), radius: const Radius.circular(24), clockwise: false)
      ..lineTo(215, 88)
      // Rear wheel arch
      ..arcToPoint(const Offset(260, 88), radius: const Radius.circular(24), clockwise: false)
      ..lineTo(295, 88)
      ..quadraticBezierTo(305, 80, 302, 68)
      // Trunk line
      ..lineTo(260, 64)
      // Fastback roofline
      ..lineTo(195, 36)
      // Roof
      ..lineTo(130, 36)
      // Windshield
      ..lineTo(95, 62)
      // Hood
      ..lineTo(32, 65)
      // Front grille
      ..quadraticBezierTo(22, 70, 25, 88)
      ..close();

    canvas.drawPath(body, fillBody);
    canvas.drawPath(body, strokePaint);

    // Windows
    final windows = Path()
      ..moveTo(100, 60)
      ..lineTo(132, 39)
      ..lineTo(190, 39)
      ..lineTo(245, 62)
      ..close();
    canvas.drawPath(windows, fillGlass);
    canvas.drawPath(windows, strokePaint);

    // Center door post
    canvas.drawLine(const Offset(160, 39), const Offset(160, 88), strokePaint);

    // Door handle & waistline accent
    canvas.drawLine(const Offset(168, 68), const Offset(182, 68), strokePaint);
    canvas.drawLine(
      const Offset(35, 74),
      const Offset(290, 74),
      Paint()
        ..color = const Color(0xFF1B1D21)
        ..strokeWidth = 1.2,
    );

    // Wheels
    void drawWheel(double cx) {
      canvas.drawCircle(Offset(cx, 88), 18, strokePaint);
      canvas.drawCircle(Offset(cx, 88), 11, fillWheelRim);
      canvas.drawCircle(Offset(cx, 88), 11, strokePaint);
      canvas.drawCircle(Offset(cx, 88), 4, Paint()..color = const Color(0xFF1B1D21));
    }

    drawWheel(62);
    drawWheel(238);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Isometric 3D City Preview ("Take a look around you" & Map backdrop)
class IsometricCityScene extends StatelessWidget {
  final double width;
  final double height;
  final bool showPins;

  const IsometricCityScene({
    super.key,
    this.width = double.infinity,
    this.height = 190,
    this.showPins = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAE1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _IsometricCityPainter(showPins: showPins),
      ),
    );
  }
}

class _IsometricCityPainter extends CustomPainter {
  final bool showPins;

  _IsometricCityPainter({required this.showPins});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 200;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 10);
    canvas.scale(scale);

    final roadPaint = Paint()
      ..color = const Color(0xFFE5DDD0)
      ..style = PaintingStyle.fill;

    final buildingTop = Paint()..color = const Color(0xFFFAF9F6);
    final buildingLeft = Paint()..color = const Color(0xFFD6D0C5);
    final buildingRight = Paint()..color = const Color(0xFFEDE7DD);

    final stroke = Paint()
      ..color = const Color(0xFFC7BFA3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw Isometric Roads
    final roadPath = Path()
      ..moveTo(-260, -30)
      ..lineTo(0, 100)
      ..lineTo(260, -30)
      ..lineTo(0, -160)
      ..close();
    canvas.drawPath(roadPath, roadPaint);

    // Draw 3D Building block helper
    void drawIsoBuilding(double x, double y, double w, double l, double h) {
      // Top face
      final top = Path()
        ..moveTo(x, y - h)
        ..lineTo(x + w * 0.866, y - h + w * 0.5)
        ..lineTo(x + w * 0.866 - l * 0.866, y - h + w * 0.5 + l * 0.5)
        ..lineTo(x - l * 0.866, y - h + l * 0.5)
        ..close();
      canvas.drawPath(top, buildingTop);
      canvas.drawPath(top, stroke);

      // Left face
      final left = Path()
        ..moveTo(x - l * 0.866, y - h + l * 0.5)
        ..lineTo(x + w * 0.866 - l * 0.866, y - h + w * 0.5 + l * 0.5)
        ..lineTo(x + w * 0.866 - l * 0.866, y + w * 0.5 + l * 0.5)
        ..lineTo(x - l * 0.866, y + l * 0.5)
        ..close();
      canvas.drawPath(left, buildingLeft);
      canvas.drawPath(left, stroke);

      // Right face
      final right = Path()
        ..moveTo(x, y - h)
        ..lineTo(x + w * 0.866, y - h + w * 0.5)
        ..lineTo(x + w * 0.866, y + w * 0.5)
        ..lineTo(x, y)
        ..close();
      canvas.drawPath(right, buildingRight);
      canvas.drawPath(right, stroke);
    }

    // Cluster of 3D Buildings (matching mockup)
    drawIsoBuilding(-120, -50, 40, 45, 65);
    drawIsoBuilding(-70, -85, 35, 35, 90);
    drawIsoBuilding(40, -100, 50, 40, 110);
    drawIsoBuilding(110, -55, 35, 45, 75);
    drawIsoBuilding(-30, 40, 45, 45, 50);

    // Cute Orange/Red Van
    void drawVehicle(double x, double y) {
      final vanPaint = Paint()..color = const Color(0xFFDE5E4E);
      final vanRoof = Paint()..color = const Color(0xFFF38A7D);
      final vanSide = Paint()..color = const Color(0xFFBD4334);

      final vTop = Path()
        ..moveTo(x, y - 16)
        ..lineTo(x + 14, y - 9)
        ..lineTo(x + 6, y - 5)
        ..lineTo(x - 8, y - 12)
        ..close();
      canvas.drawPath(vTop, vanRoof);

      final vSide = Path()
        ..moveTo(x - 8, y - 12)
        ..lineTo(x + 6, y - 5)
        ..lineTo(x + 6, y + 2)
        ..lineTo(x - 8, y - 5)
        ..close();
      canvas.drawPath(vSide, vanPaint);

      final vFront = Path()
        ..moveTo(x + 6, y - 5)
        ..lineTo(x + 14, y - 9)
        ..lineTo(x + 14, y - 2)
        ..lineTo(x + 6, y + 2)
        ..close();
      canvas.drawPath(vFront, vanSide);
    }

    drawVehicle(-85, 15);

    // Map Pins (Coral and Sage/Mint)
    if (showPins) {
      void drawPin(double x, double y, Color color) {
        final pinPath = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x - 8, y - 18, x - 8, y - 24)
          ..arcToPoint(Offset(x + 8, y - 24), radius: const Radius.circular(8))
          ..quadraticBezierTo(x + 8, y - 18, x, y)
          ..close();
        canvas.drawPath(pinPath, Paint()..color = color);
        canvas.drawCircle(Offset(x, y - 24), 3, Paint()..color = Colors.white);
      }

      drawPin(70, -10, const Color(0xFF3CA08D));
      drawPin(-110, -20, const Color(0xFFDE5E4E));
      drawPin(10, -35, const Color(0xFFDE5E4E));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
