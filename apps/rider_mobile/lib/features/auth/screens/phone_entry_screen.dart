// lib/features/auth/screens/phone_entry_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/gradient_button.dart';
import 'package:rider_app/core/widgets/fairgo_logo.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'IN');
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _phoneNumber.phoneNumber;
    if (phone == null || phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(apiClientProvider);
      await dio.post<void>(
        '/v1/auth/otp/request',
        data: {'phone': phone},
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.otpVerification, extra: phone);
      }
    } on DioException catch (e) {
      final msg = e.response?.data['error']?['message'] as String? ??
          'Something went wrong. Please try again.';
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top gradient blob
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const FairGoLogo()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 48),

                    Text(
                      'Enter your\nmobile number',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.onBackground,
                            height: 1.15,
                          ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 8),
                    Text(
                      'We\'ll send you a verification code',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 40),

                    // Phone input
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: InternationalPhoneNumberInput(
                        onInputChanged: (val) => _phoneNumber = val,
                        onInputValidated: (_) {},
                        selectorConfig: const SelectorConfig(
                          selectorType: PhoneInputSelectorType.DIALOG,
                          setSelectorButtonAsPrefixIcon: true,
                          leadingPadding: 0,
                          trailingSpace: false,
                        ),
                        initialValue: _phoneNumber,
                        inputDecoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '98765 43210',
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        textStyle: const TextStyle(
                          color: AppColors.onBackground,
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                        selectorTextStyle: const TextStyle(
                          color: AppColors.onBackground,
                          fontFamily: 'Inter',
                          fontSize: 16,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(),
                        formatInput: true,
                        countries: const ['IN'],
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms),
                    ],

                    const SizedBox(height: 32),

                    GradientButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      isLoading: _isLoading,
                      label: 'Get OTP',
                      gradient: AppColors.primaryGradient,
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        'By continuing, you agree to our\nTerms of Service & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceDisabled,
                              height: 1.6,
                            ),
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
