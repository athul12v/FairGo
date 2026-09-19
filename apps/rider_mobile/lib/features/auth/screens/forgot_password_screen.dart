// lib/features/auth/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      await ref
          .read(authStateNotifierProvider.notifier)
          .sendPasswordReset(email: email);

      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() {
          _emailSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage =
              'Could not send reset email. Please check your address and try again.';
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

              _emailSent ? _buildSuccessView() : _buildFormView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Central Iconic Accent
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2F4F6),
                border: Border.all(
                  color: const Color(0xFFD8E2FF).withOpacity(0.6),
                  width: 6,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_reset_rounded,
                  color: Color(0xFF0058BB),
                  size: 32,
                ),
              ),
            ),
          )
              .animate()
              .scale(duration: 400.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 350.ms),

          const SizedBox(height: 24),

          // Title
          const Center(
            child: Text(
              'Forgot password?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF191C1E),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
                letterSpacing: -0.6,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              'Don\'t worry, it happens. Enter the email address associated with your FairGO account and we\'ll send you a password reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4C4546),
                fontSize: 14.5,
                fontFamily: 'Inter',
                height: 1.45,
              ),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

          const SizedBox(height: 32),

          // Email Input Field
          const Text(
            'FairGO Account Email',
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

          const SizedBox(height: 10),

          // Minimal Helper Text
          Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: Color(0xFF0058BB)),
              SizedBox(width: 6),
              Text(
                'Reset link expires 10 minutes after generation.',
                style: TextStyle(
                  color: Color(0xFF7E7576),
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ],
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

          const SizedBox(height: 32),

          // Primary Black Button: Send Reset Link
          Material(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            shadowColor: Colors.black38,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isLoading ? null : _handleResetPassword,
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
                            'Send Reset Link',
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

          const SizedBox(height: 28),

          // Back to Sign In Link
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Remembered your password? ',
                  style: TextStyle(
                    color: Color(0xFF7E7576),
                    fontFamily: 'Inter',
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text(
                    'Back to Login',
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
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF86EFAC).withOpacity(0.5),
              width: 6,
            ),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF16A34A),
            size: 40,
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 24),

        const Text(
          'Check your inbox',
          style: TextStyle(
            color: Color(0xFF191C1E),
            fontSize: 26,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

        const SizedBox(height: 10),

        Text(
          'We sent a password reset link to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF4C4546),
            fontSize: 14.5,
            fontFamily: 'Inter',
            height: 1.45,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 36),

        Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.pop(),
            child: Container(
              width: double.infinity,
              height: 54,
              alignment: Alignment.center,
              child: const Text(
                'Return to Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }
}
