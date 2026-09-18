// lib/features/booking/screens/searching_driver_screen.dart
// Shown while matching service is finding a driver

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rider_app/core/constants/app_constants.dart';
import 'dart:convert';

class SearchingDriverScreen extends ConsumerStatefulWidget {
  final String tripId;
  const SearchingDriverScreen({super.key, required this.tripId});

  @override
  ConsumerState<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends ConsumerState<SearchingDriverScreen> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  int _searchElapsed = 0;
  Timer? _timer;
  String _statusMessage = 'Searching for nearby drivers…';

  @override
  void initState() {
    super.initState();
    _startPollingTimer();
    _connectWebSocket();
  }

  void _startPollingTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _searchElapsed++);
        if (_searchElapsed == 30) {
          setState(() => _statusMessage = 'Expanding search radius…');
        } else if (_searchElapsed == 60) {
          setState(() => _statusMessage = 'Still looking — almost there!');
        } else if (_searchElapsed >= AppConstants.driverSearchTimeoutSeconds) {
          _timer?.cancel();
          _handleTimeout();
        }
      }
    });
  }

  void _connectWebSocket() {
    final uri = Uri.parse('${AppConstants.wsUrl}/trips/${widget.tripId}/status');
    _channel = WebSocketChannel.connect(uri);

    _sub = _channel!.stream.listen((msg) {
      try {
        final event = jsonDecode(msg as String) as Map<String, dynamic>;
        final type = event['type'] as String?;

        if (type == 'trip.driver_assigned' && mounted) {
          _cleanup();
          context.go(AppRoutes.liveTrip, extra: widget.tripId);
        } else if (type == 'trip.no_driver_found' && mounted) {
          _cleanup();
          _handleNoDriver();
        }
      } catch (_) {}
    });
  }

  void _handleTimeout() {
    _cleanup();
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _NoDriverDialog(
          onRetry: () {
            Navigator.pop(context);
            context.go(AppRoutes.home);
          },
          onCancel: () {
            Navigator.pop(context);
            context.go(AppRoutes.home);
          },
        ),
      );
    }
  }

  void _handleNoDriver() => _handleTimeout();

  void _cleanup() {
    _timer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
  }

  Future<void> _cancelSearch() async {
    _cleanup();
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post<void>('/v1/trips/${widget.tripId}/cancel', data: {'reason': 'RIDER_CANCELLED'});
    } catch (_) {}
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_searchElapsed / AppConstants.driverSearchTimeoutSeconds).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // Animation
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Lottie.asset(
                    'assets/animations/car_searching.json',
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.search,
                      color: AppColors.primary,
                      size: 80,
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 32),

                Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.onBackground,
                        height: 1.3,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 8),
                Text(
                  'This usually takes under 60 seconds',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Progress indicator
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_searchElapsed}s / ${AppConstants.driverSearchTimeoutSeconds}s',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Tips while waiting
                _SearchTip(elapsed: _searchElapsed),

                const SizedBox(height: 32),

                TextButton(
                  onPressed: _cancelSearch,
                  child: const Text(
                    'Cancel Search',
                    style: TextStyle(
                      color: AppColors.error,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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

class _SearchTip extends StatelessWidget {
  final int elapsed;
  const _SearchTip({required this.elapsed});

  @override
  Widget build(BuildContext context) {
    const tips = [
      '🔒 Your trip is secured — no payment until drop.',
      '⭐ All FairGo drivers are background-verified.',
      '🛡️ SOS button available throughout your journey.',
      '🧾 Receipts are automatically sent after every trip.',
    ];
    final tip = tips[elapsed ~/ 20 % tips.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Text(
        tip,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface,
              height: 1.5,
            ),
        textAlign: TextAlign.center,
      ),
    ).animate(key: ValueKey(elapsed ~/ 20)).fadeIn(duration: 300.ms);
  }
}

class _NoDriverDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _NoDriverDialog({required this.onRetry, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('No drivers found', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.onBackground)),
      content: const Text(
        'No drivers are available in your area right now. Please try again in a few minutes.',
        style: TextStyle(fontFamily: 'Inter', color: AppColors.onSurfaceMuted),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Go Back', style: TextStyle(color: AppColors.onSurfaceMuted))),
        ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
      ],
    );
  }
}
