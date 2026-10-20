import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/niva_button.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/review_repository.dart';

/// Modal bottom sheet allowing users to rate (1–5 stars) and review an interaction.
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({
    super.key,
    required this.connectionRequestId,
    required this.needId,
    required this.revieweeId,
    required this.revieweeName,
    this.reviewRepository,
    this.onReviewSubmitted,
  });

  final String connectionRequestId;
  final String needId;
  final String revieweeId;
  final String revieweeName;
  final ReviewRepository? reviewRepository;
  final VoidCallback? onReviewSubmitted;

  static void show(
    BuildContext context, {
    required String connectionRequestId,
    required String needId,
    required String revieweeId,
    required String revieweeName,
    ReviewRepository? reviewRepository,
    VoidCallback? onReviewSubmitted,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReviewSheet(
        connectionRequestId: connectionRequestId,
        needId: needId,
        revieweeId: revieweeId,
        revieweeName: revieweeName,
        reviewRepository: reviewRepository,
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  final TextEditingController _reviewTextController = TextEditingController();
  late final ReviewRepository _reviewRepo =
      widget.reviewRepository ?? ReviewRepository();

  int _selectedRating = 5;
  bool _isSubmitting = false;
  bool _isSuccess = false;

  static const List<String> _ratingLabels = [
    'Poor',
    'Fair',
    'Good',
    'Very Good',
    'Exceptional',
  ];

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final currentUserId = AuthService.instance.currentUser?.uid ?? 'anonymous';
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _reviewRepo.submitReview(
        connectionRequestId: widget.connectionRequestId,
        needId: widget.needId,
        reviewerId: currentUserId,
        revieweeId: widget.revieweeId,
        rating: _selectedRating,
        reviewText: _reviewTextController.text.trim().isNotEmpty
            ? _reviewTextController.text.trim()
            : null,
      );

      widget.onReviewSubmitted?.call();

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Review error: ${e.toString().replaceAll("Exception: ", "").replaceAll("StateError: ", "")}',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.screenHorizontal,
                right: AppSpacing.screenHorizontal,
                top: AppSpacing.md,
                bottom: bottomInset + AppSpacing.md,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                    ),

                    if (_isSuccess) _buildSuccessView() else _buildFormView(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Leave Review', style: AppTextStyles.h2),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'How was your interaction with ${widget.revieweeName}?',
          style: AppTextStyles.captionSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 1. Star Rating Selector
        Center(
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  final isSelected = starNum <= _selectedRating;
                  return IconButton(
                    iconSize: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      setState(() {
                        _selectedRating = starNum;
                      });
                    },
                    icon: Icon(
                      isSelected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: isSelected
                          ? Colors.amber.shade700
                          : AppColors.textTertiary,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                _ratingLabels[_selectedRating - 1],
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. Optional Short Review Text
        const Text(
          'Short Note (optional, max 500 chars)',
          style: AppTextStyles.captionSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _reviewTextController,
          maxLength: 500,
          maxLines: 3,
          style: AppTextStyles.bodyMedium,
          decoration: const InputDecoration(
            hintText: 'Share a brief, helpful note about this completed assistance...',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 3. Submit Button
        NivaButton(
          label: 'Submit Review',
          isFullWidth: true,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submitReview,
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.helpBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.helpIcon,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Review Submitted!', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Thank you for contributing to community trust. The trust score has been safely updated.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          NivaButton(
            label: 'Done',
            isFullWidth: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
