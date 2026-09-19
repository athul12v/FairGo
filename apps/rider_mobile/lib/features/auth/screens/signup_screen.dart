// lib/features/auth/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/providers/auth_provider.dart';
import 'package:rider_app/core/router/app_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUpperCase =>
      _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasDigitOrSpecial =>
      _passwordController.text.contains(RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]'));

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUpperCase) score++;
    if (_hasDigitOrSpecial) score++;
    return score;
  }

  String get _strengthLabel {
    final score = _strengthScore;
    if (score == 0) return '';
    if (score == 1) return 'Weak';
    if (score == 2) return 'Fair';
    return 'Strong';
  }

  Color get _strengthColor {
    final score = _strengthScore;
    if (score <= 1) return const Color(0xFFEF4444);
    if (score == 2) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateNotifierProvider.notifier).signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
          );

      if (mounted) {
        HapticFeedback.mediumImpact();
        context.go(AppRoutes.accountCreated);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = e.toString().contains('email-already-in-use')
              ? 'An account already exists with this email.'
              : 'Failed to create account. Please verify details.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Back Button + FairGO Logo
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

                // Fast & Fair Mobility Pill Tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Color(0xFF001A41),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 12),

                // Title
                const Text(
                  'Get started with\nFairGO',
                  style: TextStyle(
                    color: Color(0xFF191C1E),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                    height: 1.18,
                    letterSpacing: -0.6,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideX(begin: -0.05, end: 0),

                const SizedBox(height: 6),

                const Text(
                  'Join thousands of riders enjoying honest, zero-surge travel.',
                  style: TextStyle(
                    color: Color(0xFF4C4546),
                    fontSize: 14.5,
                    fontFamily: 'Inter',
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 28),

                // Full Name
                _buildField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Alex Chen',
                  icon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email Address
                _buildField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'alex.chen@fairgo.city',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
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
                ),

                const SizedBox(height: 16),

                // Mobile Number
                _buildField(
                  controller: _phoneController,
                  label: 'Mobile Number',
                  hint: '98765 43210',
                  icon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                // Password
                _buildField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'At least 8 characters',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
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
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (val.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

                // Clean Minimal Password Strength Feedback
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: List.generate(3, (index) {
                            final filled = index < _strengthScore;
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(
                                    right: index < 2 ? 6.0 : 0.0),
                                decoration: BoxDecoration(
                                  color: filled
                                      ? _strengthColor
                                      : const Color(0xFFE1E2E4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _strengthLabel,
                        style: TextStyle(
                          color: _strengthColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Confirm Password
                _buildField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Icons.replay_rounded,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF4C4546),
                      size: 20,
                    ),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
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

                const SizedBox(height: 28),

                // Primary Black CTA: Create Account
                Material(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  shadowColor: Colors.black38,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading ? null : _handleSignup,
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
                              children: const [
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Footer: Already have an account? Sign In
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Color(0xFF7E7576),
                          fontFamily: 'Inter',
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text(
                          'Sign In',
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

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            validator: validator,
            style: const TextStyle(
              color: Color(0xFF191C1E),
              fontFamily: 'Inter',
              fontSize: 15,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF7E7576),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
              icon: Icon(icon, color: const Color(0xFF4C4546), size: 20),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
