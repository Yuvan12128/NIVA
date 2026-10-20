import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/niva_button.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/report_model.dart';
import '../../data/safety_repository.dart';

/// Modal bottom sheet allowing users to report another user securely.
class ReportSheet extends StatefulWidget {
  const ReportSheet({
    super.key,
    required this.reportedUserId,
    required this.reportedUserName,
    this.referenceId,
    this.safetyRepository,
  });

  final String reportedUserId;
  final String reportedUserName;
  final String? referenceId;
  final SafetyRepository? safetyRepository;

  static void show(
    BuildContext context, {
    required String reportedUserId,
    required String reportedUserName,
    String? referenceId,
    SafetyRepository? safetyRepository,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReportSheet(
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
        referenceId: referenceId,
        safetyRepository: safetyRepository,
      ),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final TextEditingController _descController = TextEditingController();
  late final SafetyRepository _safetyRepo =
      widget.safetyRepository ?? SafetyRepository();

  ReportReason _selectedReason = ReportReason.spam;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final currentUid = AuthService.instance.currentUser?.uid;
    if (currentUid == null) {
      setState(() {
        _errorMessage = 'You must be logged in to report a user.';
      });
      return;
    }

    if (currentUid == widget.reportedUserId) {
      setState(() {
        _errorMessage = 'You cannot report yourself.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _safetyRepo.reportUser(
        reporterId: currentUid,
        reportedUserId: widget.reportedUserId,
        reason: _selectedReason.value,
        description: _descController.text.trim(),
        referenceId: widget.referenceId,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isSubmitted ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Report Submitted', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Thank you for helping keep NIVA a safe and trusted space. Our safety system will review this report.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          NivaButton(
            label: 'Done',
            isFullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Report ${widget.reportedUserName}',
                style: AppTextStyles.h2,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderSubtle),

        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),

                const Text(
                  'Why are you reporting this user?',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Select the reason that best describes the issue.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Reason options
                ...ReportReason.values.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return InkWell(
                    onTap: () => setState(() => _selectedReason = reason),
                    borderRadius: AppSpacing.borderRadiusMd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? AppColors.primaryPurple
                                : AppColors.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              reason.label,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.lg),

                // Description text area
                const Text(
                  'Additional Details (Optional)',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _descController,
                  maxLength: 500,
                  maxLines: 3,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Provide any context or explanation to help our review...',
                    hintStyle: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                      borderSide: const BorderSide(
                        color: AppColors.primaryPurple,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Submit button
                NivaButton(
                  label: _isSubmitting ? 'Submitting...' : 'Submit Report',
                  isFullWidth: true,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submitReport,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
