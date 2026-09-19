// lib/features/auth/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/providers/auth_provider.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/gradient_button.dart';
import 'package:rider_app/core/widgets/fairgo_logo.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
          tooltip: 'Back',
          color: AppColors.onBackground,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
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
          const FairGoLogo()
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.2, end: 0),
          const SizedBox(height: 32),

          Text(
            'Reset your\npassword',
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
            'Enter the email associated with your account and we\'ll send a link to reset your password.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  height: 1.4,
                ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 40),

          // Email Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
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
            ],
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

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
            ).animate().fadeIn(duration: 300.ms),
          ],

          const SizedBox(height: 32),

          GradientButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            isLoading: _isLoading,
            label: 'Send Reset Link',
            gradient: AppColors.primaryGradient,
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

          const Spacer(),

          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Back to Sign In',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  fontSize: 14,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.primary,
            size: 40,
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 24),

        Text(
          'Check your email',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

        const SizedBox(height: 12),

        Text(
          'We sent a password reset link to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceMuted,
                height: 1.4,
              ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 40),

        GradientButton(
          onPressed: () => context.pop(),
          label: 'Return to Sign In',
          gradient: AppColors.primaryGradient,
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }
}
