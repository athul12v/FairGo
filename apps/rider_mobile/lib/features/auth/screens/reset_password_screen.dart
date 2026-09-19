// lib/features/auth/screens/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/router/app_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  const ResetPasswordScreen({super.key, this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
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
    if (score == 2) return 'Moderate';
    return 'Strong';
  }

  Color get _strengthColor {
    final score = _strengthScore;
    if (score <= 1) return const Color(0xFFEF4444);
    if (score == 2) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_strengthScore < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a stronger password.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Please sign in.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      context.go(AppRoutes.phoneEntry, extra: 'email');
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
                // Header: Back Button + FairGO Logo
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

                const SizedBox(height: 24),

                // Security Step Tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Account Security',
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
                  'Create new password',
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
                  'Your new password must be different from previous passwords for security.',
                  style: TextStyle(
                    color: Color(0xFF4C4546),
                    fontSize: 14.5,
                    fontFamily: 'Inter',
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 28),

                // New Password Field
                const Text(
                  'New Password',
                  style: TextStyle(
                    color: Color(0xFF191C1E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (val.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      color: Color(0xFF191C1E),
                      fontFamily: 'Inter',
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter secure password',
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
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Strength Indicator Bar & Label
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Strength Rating',
                            style: TextStyle(
                              color: Color(0xFF4C4546),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
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
                      const SizedBox(height: 8),
                      Row(
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
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Checklist
                _buildChecklistItem('At least 8 characters', _hasMinLength),
                const SizedBox(height: 6),
                _buildChecklistItem(
                    'At least one capital letter', _hasUpperCase),
                const SizedBox(height: 6),
                _buildChecklistItem(
                    'At least one number or special symbol', _hasDigitOrSpecial),

                const SizedBox(height: 24),

                // Confirm Password Field
                const Text(
                  'Confirm New Password',
                  style: TextStyle(
                    color: Color(0xFF191C1E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    validator: (val) {
                      if (val != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      color: Color(0xFF191C1E),
                      fontFamily: 'Inter',
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Re-enter password',
                      hintStyle: const TextStyle(
                        color: Color(0xFF7E7576),
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                      icon: const Icon(Icons.replay_rounded,
                          color: Color(0xFF4C4546), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF4C4546),
                          size: 20,
                        ),
                        onPressed: () => setState(() =>
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Reset Password CTA
                Material(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  shadowColor: Colors.black38,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading ? null : _handleReset,
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
                                  'Reset Password & Sign In',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: met ? const Color(0xFF10B981) : const Color(0xFF7E7576),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: met ? const Color(0xFF191C1E) : const Color(0xFF4C4546),
            fontSize: 13,
            fontWeight: met ? FontWeight.w500 : FontWeight.w400,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}
