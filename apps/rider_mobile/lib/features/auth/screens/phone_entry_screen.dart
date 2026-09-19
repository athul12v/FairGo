// lib/features/auth/screens/phone_entry_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/providers/auth_provider.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/gradient_button.dart';
import 'package:rider_app/core/widgets/fairgo_logo.dart';

enum AuthMethod { mobile, email }

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _mobileFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  AuthMethod _authMethod = AuthMethod.mobile;

  // Mobile state
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'IN');

  // Email state
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_mobileFormKey.currentState?.validate() ?? false)) return;

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
    } catch (_) {
      // Dev mode fallback navigate if backend unreachable
      if (mounted) {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.otpVerification, extra: phone);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithEmail() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateNotifierProvider.notifier).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = e.toString().contains('user-not-found')
              ? 'No account found with this email.'
              : e.toString().contains('wrong-password')
                  ? 'Incorrect password. Please try again.'
                  : 'Failed to sign in. Please check your credentials.';
        });
      }
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
          // Top ambient gradient blob
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const FairGoLogo()
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 32),

                  // Header Title
                  Text(
                    _authMethod == AuthMethod.mobile
                        ? 'Enter your\nmobile number'
                        : 'Sign in with\nyour email',
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
                    _authMethod == AuthMethod.mobile
                        ? 'We\'ll send you a 6-digit verification code'
                        : 'Enter your credentials to access your account',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                  const SizedBox(height: 28),

                  // Segmented Auth Method Switcher
                  _buildSegmentedControl()
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 28),

                  // Dynamic Auth Form
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _authMethod == AuthMethod.mobile
                        ? _buildMobileForm()
                        : _buildEmailForm(),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 16),
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
                    ).animate().fadeIn(duration: 300.ms).shakeX(duration: 300.ms),
                  ],

                  const SizedBox(height: 28),

                  // Primary Action Button
                  GradientButton(
                    onPressed: _isLoading
                        ? null
                        : (_authMethod == AuthMethod.mobile
                            ? _sendOtp
                            : _loginWithEmail),
                    isLoading: _isLoading,
                    label: _authMethod == AuthMethod.mobile
                        ? 'Get OTP'
                        : 'Sign In',
                    gradient: AppColors.primaryGradient,
                  ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Sign Up Link for Email Mode
                  if (_authMethod == AuthMethod.email) ...[
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account? ',
                            style: TextStyle(
                              color: AppColors.onSurfaceMuted,
                              fontFamily: 'Inter',
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.signup),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 24),
                  ],

                  Center(
                    child: Text(
                      'By continuing, you agree to our\nTerms of Service & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceDisabled,
                            height: 1.6,
                          ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _authMethod = AuthMethod.mobile;
                  _errorMessage = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _authMethod == AuthMethod.mobile
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 18,
                      color: _authMethod == AuthMethod.mobile
                          ? Colors.white
                          : AppColors.onSurfaceMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mobile Number',
                      style: TextStyle(
                        color: _authMethod == AuthMethod.mobile
                            ? Colors.white
                            : AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _authMethod = AuthMethod.email;
                  _errorMessage = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _authMethod == AuthMethod.email
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: _authMethod == AuthMethod.email
                          ? Colors.white
                          : AppColors.onSurfaceMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email Address',
                      style: TextStyle(
                        color: _authMethod == AuthMethod.email
                            ? Colors.white
                            : AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileForm() {
    return Form(
      key: _mobileFormKey,
      child: Container(
        key: const ValueKey('mobile_form'),
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
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email_form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Field
          const Text(
            'Email Address',
            style: TextStyle(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontFamily: 'Inter',
                fontSize: 16,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(val.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'name@example.com',
                hintStyle: TextStyle(
                  color: AppColors.onSurfaceDisabled,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
                icon: Icon(Icons.email_outlined,
                    color: AppColors.onSurfaceMuted, size: 20),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Password Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Password',
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.forgotPassword),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontFamily: 'Inter',
                fontSize: 16,
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter password',
                hintStyle: const TextStyle(
                  color: AppColors.onSurfaceDisabled,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
                icon: const Icon(Icons.lock_outline,
                    color: AppColors.onSurfaceMuted, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.onSurfaceMuted,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
