// lib/features/trip/screens/rate_driver_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/gradient_button.dart';
import 'package:dio/dio.dart';

const _quickFeedback = [
  ('🎵', 'Great music'),
  ('💬', 'Good conversation'),
  ('🧹', 'Clean vehicle'),
  ('🛣️', 'Smooth ride'),
  ('⏰', 'On time'),
  ('🗺️', 'Knew the route'),
  ('😊', 'Friendly'),
  ('🔇', 'Quiet & focused'),
];

class RateDriverScreen extends ConsumerStatefulWidget {
  final String tripId;
  const RateDriverScreen({super.key, required this.tripId});

  @override
  ConsumerState<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends ConsumerState<RateDriverScreen> {
  double _rating = 5.0;
  final Set<String> _selectedTags = {};
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post<void>(
        '/v1/trips/${widget.tripId}/rating',
        data: {
          'rating': _rating.round(),
          'tags': _selectedTags.toList(),
          if (_commentController.text.trim().isNotEmpty)
            'comment': _commentController.text.trim(),
        },
      );
      if (mounted) context.go(AppRoutes.home);
    } on DioException catch (_) {
      // Even on error, proceed to home
      if (mounted) context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Trophy icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: const Center(child: Text('🏁', style: TextStyle(fontSize: 48))),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                Text(
                  'Trip Complete!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onBackground,
                      ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 8),
                Text(
                  'How was your trip with your driver?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceMuted),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 36),

                // Star rating
                RatingBar.builder(
                  initialRating: 5,
                  minRating: 1,
                  itemCount: 5,
                  itemSize: 48,
                  glow: true,
                  glowColor: AppColors.accent,
                  itemBuilder: (_, index) => Icon(
                    index < _rating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.accent,
                  ),
                  onRatingUpdate: (v) => setState(() => _rating = v),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // Quick feedback tags
                if (_rating >= 4) ...[
                  Text(
                    'What went well?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickFeedback.asMap().entries.map((e) {
                      final tag = e.value.$2;
                      final emoji = e.value.$1;
                      final isSelected = _selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedTags.remove(tag);
                          } else {
                            _selectedTags.add(tag);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '$emoji $tag',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: isSelected ? AppColors.primary : AppColors.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 450 + e.key * 40));
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Optional comment
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Any additional feedback? (optional)',
                    alignLabelWithHint: true,
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: 32),

                GradientButton(
                  onPressed: _isSubmitting ? null : _submit,
                  isLoading: _isSubmitting,
                  label: 'Submit Rating',
                  gradient: AppColors.primaryGradient,
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: AppColors.onSurfaceMuted, fontFamily: 'Inter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
