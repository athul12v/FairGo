// lib/features/home/widgets/service_chip_bar.dart
// Horizontal scrollable service type chips below the map header

import 'package:flutter/material.dart';
import 'package:rider_app/core/theme/app_theme.dart';

const _chips = [
  ('🚗', 'Cab'),
  ('🛺', 'Auto'),
  ('🏍️', 'Bike'),
  ('📦', 'Parcel'),
  ('🧑‍✈️', 'Hire Driver'),
  ('🏢', 'Corporate'),
];

class ServiceChipBar extends StatefulWidget {
  const ServiceChipBar({super.key});

  @override
  State<ServiceChipBar> createState() => _ServiceChipBarState();
}

class _ServiceChipBarState extends State<ServiceChipBar> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = _chips[i];
          final isSelected = i == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(chip.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    chip.$2,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
