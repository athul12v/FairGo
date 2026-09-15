// lib/features/support/screens/support_screen.dart
// Enhanced Context-First Support Module matching Google Support UX philosophy

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/cross_platform_shell.dart';
import 'package:rider_app/features/support/models/support_models.dart';
import 'package:rider_app/features/support/providers/support_provider.dart';
import 'package:rider_app/features/support/widgets/callback_request_dialog.dart';
import 'package:rider_app/features/support/widgets/email_support_dialog.dart';
import 'package:rider_app/features/support/widgets/support_chat_modal.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _issueDescController = TextEditingController();
  SupportCategoryType _selectedCategory = SupportCategoryType.tripIssue;
  String? _expandedFaqId;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _issueDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(supportAvailabilityProvider);
    final faqsAsync = ref.watch(supportFaqsProvider(_selectedCategory.code));

    final availability = availabilityAsync.valueOrNull ?? SupportAvailabilityModel.fallback();

    return CrossPlatformShell(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onBackground),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.onBackground),
            tooltip: 'My Support Cases',
            onPressed: () => _showMyCasesDialog(context),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Google-Style Context Header & Search
              _buildHeaderSearch(),
              const SizedBox(height: 16),

              // 2. Realtime Support Availability Strip
              _buildAvailabilityStrip(availability),
              const SizedBox(height: 24),

              // 3. What do you need help with? Issue Categories
              _buildCategorySelector(),
              const SizedBox(height: 20),

              // 4. Free-Text Issue Description ("Tell us briefly...")
              _buildIssueInputBox(),
              const SizedBox(height: 24),

              // 5. Context-First Instant Solutions (FAQs Accordion)
              _buildSelfHelpSection(faqsAsync),
              const SizedBox(height: 28),

              // 6. Contact Options Section: Call / Email / Live Chat
              _buildContactOptionsSection(availability),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How can we help today?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.onBackground,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Search for instant answers or connect with 24/7 FairGo support.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search help topics, refunds, lost items…',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.onSurfaceMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildAvailabilityStrip(SupportAvailabilityModel avail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusPill(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Live Chat',
            status: avail.isChatAvailable ? 'Available now' : 'Busy',
            isAvailable: avail.isChatAvailable,
          ),
          Container(width: 1, height: 28, color: AppColors.surfaceBorder),
          _buildStatusPill(
            icon: Icons.phone_in_talk_outlined,
            title: 'Phone',
            status: avail.isCallAvailable ? '24/7 Open' : 'Offline',
            isAvailable: avail.isCallAvailable,
          ),
          Container(width: 1, height: 28, color: AppColors.surfaceBorder),
          _buildStatusPill(
            icon: Icons.mail_outline_rounded,
            title: 'Email',
            status: avail.emailResponseWindow,
            isAvailable: true,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String title,
    required String status,
    required bool isAvailable,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.onSurfaceMuted),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 6,
              color: isAvailable ? const Color(0xFF2E7D32) : AppColors.error,
            ),
            const SizedBox(width: 4),
            Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isAvailable ? const Color(0xFF236C5F) : AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you need help with?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: SupportCategoryType.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final cat = SupportCategoryType.values[index];
              final isSelected = cat == _selectedCategory;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _expandedFaqId = null;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFD7ECE6) : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3CA08D) : AppColors.surfaceBorder,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        cat.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF1F685B) : AppColors.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildIssueInputBox() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Tell us briefly what you\'re having trouble with',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _issueDescController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g., Charged incorrect cancellation fee on yesterday\'s trip…',
              fillColor: Color(0xFFFBF9F5),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildSelfHelpSection(AsyncValue<List<FaqModel>> faqsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Instant Solutions & FAQs',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              ),
            ),
            Text(
              _selectedCategory.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        faqsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (faqs) {
            final filtered = _searchQuery.isEmpty
                ? faqs
                : faqs
                    .where((f) =>
                        f.question.toLowerCase().contains(_searchQuery) ||
                        f.answer.toLowerCase().contains(_searchQuery))
                    .toList();

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Text(
                  'No articles matching your query. Please connect with our support options below.',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
                ),
              );
            }

            return Column(
              children: filtered.map((faq) => _buildFaqTile(faq)).toList(),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 450.ms);
  }

  Widget _buildFaqTile(FaqModel faq) {
    final isExpanded = _expandedFaqId == faq.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key(faq.id),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _expandedFaqId = expanded ? faq.id : null);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            faq.question,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                faq.answer,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.onSurfaceMuted,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOptionsSection(SupportAvailabilityModel avail) {
    final issueDesc = _issueDescController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Still need help? Choose a contact option',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 12),

        // 1. Live Chat Option Card
        _buildContactCard(
          icon: Icons.chat_rounded,
          iconBg: const Color(0xFFD7ECE6),
          iconColor: const Color(0xFF236C5F),
          title: 'Start Live Support Chat',
          subtitle: avail.isChatAvailable
              ? 'Connect in ~${avail.estimatedWaitSeconds}s with a specialist'
              : 'Specialists currently busy. Email recommended.',
          statusBadge: avail.isChatAvailable ? 'Available now' : 'Busy',
          badgeColor: avail.isChatAvailable ? const Color(0xFF2E7D32) : AppColors.error,
          onTap: () {
            SupportChatModal.show(
              context,
              category: _selectedCategory,
              description: issueDesc,
            );
          },
        ),

        const SizedBox(height: 12),

        // 2. Phone Call & Callback Option Card
        _buildContactCard(
          icon: Icons.phone_rounded,
          iconBg: const Color(0xFFFDE8E4),
          iconColor: AppColors.primary,
          title: 'Call Support or Request Callback',
          subtitle: 'Toll-free 24/7: ${avail.callPhoneNumber} or schedule a call',
          statusBadge: '24/7 Line',
          badgeColor: const Color(0xFF2E7D32),
          onTap: () {
            CallbackRequestDialog.show(
              context,
              category: _selectedCategory,
              description: issueDesc,
            );
          },
        ),

        const SizedBox(height: 12),

        // 3. Email Support Option Card
        _buildContactCard(
          icon: Icons.email_rounded,
          iconBg: const Color(0xFFF3EDE4),
          iconColor: const Color(0xFFE67E22),
          title: 'Email Support Ticket',
          subtitle: 'Attach screenshots, receipts, or ride details (${avail.emailResponseWindow})',
          statusBadge: '24/7 Form',
          badgeColor: AppColors.onSurfaceMuted,
          onTap: () {
            EmailSupportDialog.show(
              context,
              category: _selectedCategory,
              description: issueDesc,
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 450.ms);
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String statusBadge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusBadge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
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
            ),
          ],
        ),
      ),
    );
  }

  void _showMyCasesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Support Cases',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EDE4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Color(0xFF236C5F)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Case #FG-2026-10482',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Trip Fare Adjustment • Resolved',
                            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                          ),
                        ],
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
}
