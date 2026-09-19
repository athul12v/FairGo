// lib/features/auth/screens/phone_entry_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/providers/auth_provider.dart';
import 'package:rider_app/core/router/app_router.dart';

enum AuthMethod { mobile, email }

class PhoneEntryScreen extends ConsumerStatefulWidget {
  final String? initialMode;
  const PhoneEntryScreen({super.key, this.initialMode});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _mobileFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  late AuthMethod _authMethod;

  // Mobile state
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'IN');

  // Email state
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authMethod = widget.initialMode == 'email'
        ? AuthMethod.email
        : AuthMethod.mobile;
  }

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
      // Dev / offline mode fallback
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
        // Router redirect handles navigation to AppRoutes.home upon authentication
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

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    HapticFeedback.lightImpact();

    try {
      await ref.read(authStateNotifierProvider.notifier).signInWithGoogle();
      if (mounted) {
        // Router redirect handles navigation to AppRoutes.home
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Google sign in failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
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
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.welcome);
                      }
                    },
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

              // Fast & Fair Mobility Pill Tag
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.bolt_rounded,
                        size: 13, color: Color(0xFF0058BB)),
                    SizedBox(width: 4),
                    Text(
                      'FAST & FAIR MOBILITY',
                      style: TextStyle(
                        color: Color(0xFF001A41),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 12),

              // Title
              const Text(
                'Welcome back',
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

              const Text(
                'Sign in to manage your rides, fares, and saved locations.',
                style: TextStyle(
                  color: Color(0xFF4C4546),
                  fontSize: 14.5,
                  fontFamily: 'Inter',
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Segmented Control (Inline Switcher)
              _buildSegmentedControl()
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Inline Form Switcher
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _authMethod == AuthMethod.mobile
                    ? _buildMobileForm()
                    : _buildEmailForm(),
              ),

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

              const SizedBox(height: 24),

              // Primary Black CTA
              Material(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                elevation: 2,
                shadowColor: Colors.black38,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isLoading
                      ? null
                      : (_authMethod == AuthMethod.mobile
                          ? _sendOtp
                          : _loginWithEmail),
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
                                _authMethod == AuthMethod.mobile
                                    ? 'Send Verification Code'
                                    : 'Sign In',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ],
                          ),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

              const SizedBox(height: 20),

              // Split Divider: OR CONTINUE WITH
              Row(
                children: const [
                  Expanded(
                    child: Divider(
                      color: Color(0xFFE1E2E4),
                      thickness: 0.8,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: TextStyle(
                        color: Color(0xFF7E7576),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Color(0xFFE1E2E4),
                      thickness: 0.8,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Google Sign-In Secondary CTA
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE1E2E4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: _isGoogleLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFF0058BB),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGoogleLogoSvg(),
                                const SizedBox(width: 12),
                                const Text(
                                  'Google',
                                  style: TextStyle(
                                    color: Color(0xFF191C1E),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // End-to-End Encrypted Trust Pill
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE1E2E4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8E2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF0058BB),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'End-to-End Encrypted',
                            style: TextStyle(
                              color: Color(0xFF191C1E),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'FairGO never sells ride tracking or contact telemetry.',
                            style: TextStyle(
                              color: Color(0xFF7E7576),
                              fontSize: 11.5,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Footer: New to FairGO? Create an account
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'New to FairGO? ',
                      style: TextStyle(
                        color: Color(0xFF7E7576),
                        fontFamily: 'Inter',
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.signup),
                      child: const Text(
                        'Create an account',
                        style: TextStyle(
                          color: Color(0xFF0058BB),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Segmented Tab Switcher: [ Mobile Number ] [ Email & Password ]
  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(14),
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
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _authMethod == AuthMethod.mobile
                      ? Colors.black
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _authMethod == AuthMethod.mobile
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_iphone_rounded,
                      size: 17,
                      color: _authMethod == AuthMethod.mobile
                          ? Colors.white
                          : const Color(0xFF4C4546),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mobile Number',
                      style: TextStyle(
                        color: _authMethod == AuthMethod.mobile
                            ? Colors.white
                            : const Color(0xFF4C4546),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
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
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _authMethod == AuthMethod.email
                      ? Colors.black
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _authMethod == AuthMethod.email
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 17,
                      color: _authMethod == AuthMethod.email
                          ? Colors.white
                          : const Color(0xFF4C4546),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email & Password',
                      style: TextStyle(
                        color: _authMethod == AuthMethod.email
                            ? Colors.white
                            : const Color(0xFF4C4546),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
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

  // Mobile Number Form
  Widget _buildMobileForm() {
    return Form(
      key: _mobileFormKey,
      child: Column(
        key: const ValueKey('mobile_form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phone Number',
            style: TextStyle(
              color: Color(0xFF191C1E),
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1E2E4)),
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
                hintText: '(555) 019-2834',
                hintStyle: TextStyle(
                  color: Color(0xFF7E7576),
                  fontSize: 15,
                  fontFamily: 'Inter',
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              textStyle: const TextStyle(
                color: Color(0xFF191C1E),
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.1,
              ),
              selectorTextStyle: const TextStyle(
                color: Color(0xFF191C1E),
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              keyboardType: const TextInputType.numberWithOptions(),
              formatInput: true,
              countries: const ['IN', 'US', 'GB', 'AE', 'SG'],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.shield_outlined,
                  size: 14, color: Color(0xFF10B981)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'We\'ll text a 6-digit verification code. Standard rates apply.',
                  style: TextStyle(
                    color: Color(0xFF7E7576),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Email & Password Form
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
              color: Color(0xFF191C1E),
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1E2E4)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                color: Color(0xFF191C1E),
                fontFamily: 'Inter',
                fontSize: 15,
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
                hintText: 'alex.chen@fairgo.city',
                hintStyle: TextStyle(
                  color: Color(0xFF7E7576),
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
                icon: Icon(Icons.email_outlined,
                    color: Color(0xFF4C4546), size: 20),
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
                  color: Color(0xFF191C1E),
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
                    color: Color(0xFF0058BB),
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
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1E2E4)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(
                color: Color(0xFF191C1E),
                fontFamily: 'Inter',
                fontSize: 15,
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
                  color: Color(0xFF7E7576),
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
                icon: const Icon(Icons.lock_outline_rounded,
                    color: Color(0xFF4C4546), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF4C4546),
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

  Widget _buildGoogleLogoSvg() {
    const googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="22" height="22">
  <path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17z"/>
  <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z"/>
  <path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.18 0 10.04 0 12s.45 3.82 1.25 5.42l4.03-3.15z"/>
  <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"/>
</svg>
''';
    return SvgPicture.string(
      googleSvg,
      width: 20,
      height: 20,
    );
  }
}
