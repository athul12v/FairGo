// lib/features/support/widgets/callback_request_dialog.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/features/support/models/support_models.dart';

class CallbackRequestDialog extends ConsumerStatefulWidget {
  final SupportCategoryType initialCategory;
  final String initialDescription;

  const CallbackRequestDialog({
    super.key,
    this.initialCategory = SupportCategoryType.tripIssue,
    this.initialDescription = '',
  });

  static Future<void> show(
    BuildContext context, {
    SupportCategoryType category = SupportCategoryType.tripIssue,
    String description = '',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CallbackRequestDialog(
        initialCategory: category,
        initialDescription: description,
      ),
    );
  }

  @override
  ConsumerState<CallbackRequestDialog> createState() => _CallbackRequestDialogState();
}

class _CallbackRequestDialogState extends ConsumerState<CallbackRequestDialog> {
  final TextEditingController _phoneController = TextEditingController(text: '+91 98765 43210');
  late TextEditingController _summaryController;
  String _selectedWindow = 'Immediately (~3 mins)';
  bool _isSubmitting = false;

  final List<String> _windows = [
    'Immediately (~3 mins)',
    'Within 15 minutes',
    'Within 1 hour',
    'Evening (5:00 PM – 7:00 PM)',
  ];

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final summary = _summaryController.text.trim();
    if (phone.isEmpty || summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your phone number and issue summary.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/v1/support/cases/callback', data: {
        'phoneNumber': phone,
        'preferredTimeWindow': _selectedWindow,
        'category': widget.initialCategory.code,
        'issueSummary': summary,
      });
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD7ECE6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF236C5F), size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Callback Scheduled',
              style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A FairGo support specialist will call you at $phone.',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EDE4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scheduled Window', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted)),
                  const SizedBox(height: 4),
                  Text(
                    _selectedWindow,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onBackground),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Request a Callback',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Skip waiting on hold. We will call you directly with your account and trip context ready.',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 16),

              const Text('Phone Number to Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: AppColors.primary),
                  fillColor: const Color(0xFFFBF9F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              const Text('When should we call?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF9F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedWindow,
                    isExpanded: true,
                    items: _windows.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedWindow = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Issue Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _summaryController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Briefly mention what you would like to discuss',
                  fillColor: const Color(0xFFFBF9F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Callback Request', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
