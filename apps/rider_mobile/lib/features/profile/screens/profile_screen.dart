// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/providers/auth_provider.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/app_bottom_nav.dart';
import 'package:rider_app/core/widgets/cross_platform_shell.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).valueOrNull;

    return CrossPlatformShell(
      backgroundColor: AppColors.background,
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go(AppRoutes.home);
              break;
            case 1:
              context.push(AppRoutes.tripHistory);
              break;
            case 2:
              context.push(AppRoutes.wallet);
              break;
            case 3:
              break;
          }
        },
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onBackground, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
          title: const Text(
            'Account & Profile',
            style: TextStyle(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Info Header Card
              _buildUserCard(context, authState),
              const SizedBox(height: 24),

              // 2. Help & Customer Support Hero Card (Google-style prominent support entry)
              _buildSupportCard(context),
              const SizedBox(height: 24),

              // 3. Safety & Preferences Section
              const Text(
                'Safety & Settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionCard([
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.primary,
                  title: 'Emergency SOS & Contacts',
                  subtitle: 'Instant alert setup and trusted contacts',
                  onTap: () => context.push(AppRoutes.sos),
                ),
                const Divider(height: 1, color: AppColors.surfaceBorder),
                _SettingsTile(
                  icon: Icons.bookmark_border_rounded,
                  iconColor: AppColors.secondary,
                  title: 'Saved Places',
                  subtitle: 'Home, Work and frequent locations',
                  onTap: () => context.push(AppRoutes.savedPlaces),
                ),
                const Divider(height: 1, color: AppColors.surfaceBorder),
                _SettingsTile(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppColors.accent,
                  title: 'FairGo Wallet & Payments',
                  subtitle: 'Fast payments, UPI & auto-recharge',
                  onTap: () => context.push(AppRoutes.wallet),
                ),
              ]),
              const SizedBox(height: 24),

              // 4. Preferences
              const Text(
                'Preferences & About',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionCard([
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  iconColor: Colors.purple,
                  title: 'Notification Preferences',
                  subtitle: 'Trip alerts, offers and receipts',
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                const Divider(height: 1, color: AppColors.surfaceBorder),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.onSurfaceMuted,
                  title: 'About FairGo',
                  subtitle: 'v1.0.0 • Made with Fair Principles for India',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 28),

              // 5. Sign out button
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out from your FairGo account?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              ref.read(authStateProvider.notifier).logout();
                              context.go(AppRoutes.phoneEntry);
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AuthState? state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.secondaryLight,
            child: Icon(Icons.person_rounded, size: 36, color: AppColors.secondaryDark),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FairGo Rider',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state?.userId != null ? 'ID: ${state!.userId!.substring(0, 8)}...' : '+91 Verified Account',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                      SizedBox(width: 4),
                      Text(
                        '4.92 Rating',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSupportCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7F5), Color(0xFFFAF0EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push(AppRoutes.support),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Help & Customer Support',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onBackground,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Live chat, callbacks, FAQs & ticket tracking',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 450.ms);
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
