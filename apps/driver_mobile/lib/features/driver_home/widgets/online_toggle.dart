// lib/features/driver_home/widgets/online_toggle.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:driver_app/core/theme/driver_theme.dart';

class OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onToggle;

  const OnlineToggle({
    super.key,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: isOnline
              ? DriverColors.primaryGradient
              : const LinearGradient(colors: [DriverColors.surfaceElevated, DriverColors.surface]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOnline ? DriverColors.primary : DriverColors.surfaceBorder,
            width: 1.5,
          ),
          boxShadow: isOnline
              ? [
                  BoxShadow(
                    color: DriverColors.primary.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Pulsing dot
            if (isOnline)
              _PulsingDot()
            else
              const Icon(Icons.radio_button_off_rounded, color: DriverColors.onSurfaceMuted, size: 20),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'You\'re Online' : 'You\'re Offline',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isOnline ? Colors.white : DriverColors.onSurfaceMuted,
                    ),
                  ),
                  Text(
                    isOnline ? 'Receiving trip requests' : 'Tap to go online',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: isOnline ? Colors.white70 : DriverColors.onSurfaceDisabled,
                    ),
                  ),
                ],
              ),
            ),

            // Toggle pill
            Container(
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: isOnline ? Colors.white.withOpacity(0.3) : DriverColors.surfaceBorder,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(3),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.white : DriverColors.onSurfaceDisabled,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2 + 0.8 * _ctrl.value),
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
