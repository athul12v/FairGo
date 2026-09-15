// lib/features/auth/screens/otp_verification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:rider_app/core/providers/auth_provider.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/gradient_button.dart';
import 'package:dio/dio.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpVerificationScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _controller = TextEditingController();
  String _otp = '';
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            t.cancel();
          }
        });
      }
    });
  }

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final result = await ref.read(authStateNotifierProvider.notifier).verifyOtp(
        phone: widget.phone,
        otp: _otp,
        deviceType: 'ANDROID', // TODO: detect platform
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        if (result.isNewUser) {
          context.go(AppRoutes.profileSetup);
        } else {
          context.go(AppRoutes.home);
        }
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      final msg = e.response?.data['error']?['message'] as String? ?? 'Invalid OTP. Please try again.';
      setState(() {
        _errorMessage = msg;
        _otp = '';
        _controller.clear();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() { _isResending = true; _errorMessage = null; });

    try {
      final dio = ref.read(apiClientProvider);
      await dio.post<void>('/v1/auth/otp/request', data: {'phone': widget.phone});
      if (mounted) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New OTP sent!')),
        );
      }
    } on DioException catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to resend OTP. Please wait and try again.');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone = widget.phone.replaceRange(
      widget.phone.length - 4,
      widget.phone.length,
      '****',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
          tooltip: 'Back',
          color: AppColors.onBackground,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Verify your\nnumber',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(height: 1.15),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Code sent to ',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceMuted),
                  children: [
                    TextSpan(
                      text: maskedPhone,
                      style: const TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 48),

              // OTP Pin field
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _controller,
                autoFocus: true,
                autoDismissKeyboard: false,
                keyboardType: TextInputType.number,
                animationType: AnimationType.scale,
                enableActiveFill: true,
                onChanged: (v) => setState(() => _otp = v),
                onCompleted: (_) => _verify(),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeColor: AppColors.primary,
                  activeFillColor: AppColors.primary.withOpacity(0.12),
                  selectedColor: AppColors.primary,
                  selectedFillColor: AppColors.surfaceElevated,
                  inactiveColor: AppColors.surfaceBorder,
                  inactiveFillColor: AppColors.surfaceElevated,
                  borderWidth: 1.5,
                ),
                textStyle: const TextStyle(
                  color: AppColors.onBackground,
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                cursorColor: AppColors.primary,
                errorTextSpace: 0,
                useHapticFeedback: true,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Inter'),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms).shakeX(duration: 400.ms),
              ],

              const SizedBox(height: 32),

              GradientButton(
                onPressed: (_isLoading || _otp.length < 6) ? null : _verify,
                isLoading: _isLoading,
                label: 'Verify',
                gradient: AppColors.primaryGradient,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Resend
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _resendCountdown > 0
                      ? Text(
                          'Resend code in 0:${_resendCountdown.toString().padLeft(2, '0')}',
                          key: const ValueKey('countdown'),
                          style: const TextStyle(color: AppColors.onSurfaceMuted, fontFamily: 'Inter', fontSize: 14),
                        )
                      : TextButton(
                          key: const ValueKey('resend'),
                          onPressed: _isResending ? null : _resendOtp,
                          child: Text(
                            _isResending ? 'Sending...' : 'Resend OTP',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
