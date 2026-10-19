import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

enum NivaButtonVariant { primary, secondary, text }

/// Reusable NIVA action button supporting primary, secondary, and text variants.
/// Follows 48dp minimum touch target for accessibility and clean feedback.
class NivaButton extends StatelessWidget {
  const NivaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = NivaButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = AppSpacing.minTouchTarget,
  });

  final String label;
  final VoidCallback? onPressed;
  final NivaButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;

    Widget content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == NivaButtonVariant.primary
                    ? AppColors.textOnPrimary
                    : AppColors.primaryPurple,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: variant == NivaButtonVariant.primary
                      ? AppColors.textOnPrimary
                      : AppColors.primaryPurple,
                ),
              ),
            ],
          );

    final Widget buttonWidget = switch (variant) {
      NivaButtonVariant.primary => ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(
            isFullWidth ? double.infinity : AppSpacing.minTouchTarget,
            height,
          ),
        ),
        child: content,
      ),
      NivaButtonVariant.secondary => OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(
            isFullWidth ? double.infinity : AppSpacing.minTouchTarget,
            height,
          ),
        ),
        child: content,
      ),
      NivaButtonVariant.text => TextButton(
        onPressed: isEnabled ? onPressed : null,
        style: TextButton.styleFrom(
          minimumSize: Size(
            isFullWidth ? double.infinity : AppSpacing.minTouchTarget,
            height,
          ),
        ),
        child: content,
      ),
    };

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: buttonWidget);
    }

    return buttonWidget;
  }
}
