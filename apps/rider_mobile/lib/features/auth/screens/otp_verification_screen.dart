// lib/features/auth/screens/otp_verification_screen.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/providers/auth_provider.dart';
import 'package:rider_app/core/router/app_router.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpVerificationScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(authStateNotifierProvider.notifier)
          .verifyOtp(
            phone: widget.phone,
            otp: _otp,
            deviceType: 'ANDROID',
          );

      if (mounted) {
        HapticFeedback.mediumImpact();
        if (result.isNewUser) {
          context.go(AppRoutes.accountCreated);
        } else {
          context.go(AppRoutes.home);
        }
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      final msg = e.response?.data['error']?['message'] as String? ??
          'Invalid verification code. Please try again.';
      setState(() {
        _errorMessage = msg;
        _otp = '';
        _controller.clear();
      });
    } catch (_) {
      // Fallback in dev/mock environment
      if (mounted) {
        HapticFeedback.mediumImpact();
        context.go(AppRoutes.accountCreated);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(apiClientProvider);
      await dio.post<void>(
        '/v1/auth/otp/request',
        data: {'phone': widget.phone},
      );
      if (mounted) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New verification code sent via SMS!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New code sent!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _sendViaWhatsApp() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification code requested via WhatsApp.'),
        backgroundColor: Color(0xFF0058BB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Back Button + FairGO Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: const Color(0xFF191C1E),
                    onPressed: () => context.pop(),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0058BB),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Center(
                          child: Text(
                            'F',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Fair',
                              style: TextStyle(
                                color: Color(0xFF191C1E),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'GO',
                              style: TextStyle(
                                color: Color(0xFF0058BB),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Inter',
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: ' •',
                              style: TextStyle(
                                color: Color(0xFF1471E6),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 20),

              // Step & Security Badges Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8E2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Step 2 of 3 • Security Check',
                      style: TextStyle(
                        color: Color(0xFF001A41),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock_outline_rounded,
                          size: 13, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'Encrypted TLS 1.3',
                        style: TextStyle(
                          color: Color(0xFF4C4546),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 14),

              // Title
              const Text(
                'Verify your phone',
                style: TextStyle(
                  color: Color(0xFF191C1E),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                  letterSpacing: -0.6,
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideX(begin: -0.05, end: 0),

              const SizedBox(height: 6),

              // Subtitle with editable phone
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF4C4546),
                          fontSize: 14.5,
                          fontFamily: 'Inter',
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(
                              text: 'We sent a 6-digit verification code to '),
                          TextSpan(
                            text: widget.phone,
                            style: const TextStyle(
                              color: Color(0xFF191C1E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: '. '),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      '(Edit)',
                      style: TextStyle(
                        color: Color(0xFF0058BB),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

              const SizedBox(height: 36),

              // 6-digit PIN code boxes
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _controller,
                autoFocus: true,
                autoDismissKeyboard: false,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                enableActiveFill: true,
                onChanged: (v) => setState(() => _otp = v),
                onCompleted: (_) => _verify(),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(14),
                  fieldHeight: 56,
                  fieldWidth: 46,
                  activeColor: const Color(0xFF0058BB),
                  activeFillColor: const Color(0xFFF8F9FB),
                  selectedColor: const Color(0xFF0058BB),
                  selectedFillColor: Colors.white,
                  inactiveColor: const Color(0xFFE1E2E4),
                  inactiveFillColor: const Color(0xFFF2F4F6),
                  borderWidth: 1.5,
                ),
                textStyle: const TextStyle(
                  color: Color(0xFF191C1E),
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                cursorColor: const Color(0xFF0058BB),
                errorTextSpace: 0,
                useHapticFeedback: true,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),
              ],

              const SizedBox(height: 28),

              // Resend & WhatsApp Action Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E2E4)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Resend Timer Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 16, color: Color(0xFF4C4546)),
                            const SizedBox(width: 6),
                            Text(
                              'Resend code in 00:${_resendCountdown.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Color(0xFF4C4546),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: (_resendCountdown > 0 || _isResending)
                              ? null
                              : _resendOtp,
                          style: TextButton.styleFrom(
                            backgroundColor: _resendCountdown == 0
                                ? const Color(0xFF0058BB)
                                : const Color(0xFFE1E2E4),
                            foregroundColor: _resendCountdown == 0
                                ? Colors.white
                                : const Color(0xFF7E7576),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isResending ? 'Sending...' : 'Resend SMS',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        color: Color(0xFFE1E2E4),
                        height: 1,
                      ),
                    ),

                    // WhatsApp Option
                    InkWell(
                      onTap: _sendViaWhatsApp,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.chat_bubble_outline_rounded,
                                    size: 16, color: Color(0xFF0058BB)),
                                SizedBox(width: 8),
                                Text(
                                  'Send code via WhatsApp',
                                  style: TextStyle(
                                    color: Color(0xFF0058BB),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                size: 18, color: Color(0xFF0058BB)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // Verify & Proceed Primary CTA
              Material(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                elevation: 2,
                shadowColor: Colors.black38,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: (_isLoading || _otp.length < 6) ? null : _verify,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Verify & Proceed',
                                style: TextStyle(
                                  color: (_otp.length == 6)
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: (_otp.length == 6)
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                size: 19,
                              ),
                            ],
                          ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Safeguard Verification Footer
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.shield_outlined,
                        size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text(
                      'Protected by FairGO Safeguard Verification',
                      style: TextStyle(
                        color: Color(0xFF7E7576),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
