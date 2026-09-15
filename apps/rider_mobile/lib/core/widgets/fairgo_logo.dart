// lib/core/widgets/fairgo_logo.dart

import 'package:flutter/material.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class FairGoLogo extends StatelessWidget {
  final double size;
  const FairGoLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'F',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: size * 0.55,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'FairGo',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size * 0.65,
            fontWeight: FontWeight.w800,
            color: AppColors.onBackground,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
