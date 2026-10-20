import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/niva_avatar.dart';

/// Top branding header, greeting, and profile avatar for NIVA Home Screen.
/// Styled according to the Stitch Human-Centered Discovery design system.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.userName = 'Arun',
    this.location = 'Bengaluru, IN',
    this.onAvatarTap,
    this.onNotificationTap,
    this.onLocationTap,
  });

  final String userName;
  final String location;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Top Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/niva_mark.png',
                    height: 32,
                    width: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NIVA',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontFamilyFallback: AppTextStyles.fontFallbacks,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPurple,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Home',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontFamilyFallback: AppTextStyles.fontFallbacks,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                      tooltip: 'Notifications',
                      onPressed: onNotificationTap,
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryFixed,
                        width: 2,
                      ),
                    ),
                    child: NivaAvatar(
                      name: userName,
                      size: 32,
                      backgroundColor: AppColors.surfaceLow,
                      textColor: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Interactive Welcome Sub-bar (Stitch)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Hi, $userName',
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('👋', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: onLocationTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.primaryPurple,
                            size: 15,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              location,
                              style: AppTextStyles.captionSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 15,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Active Impact Metric Chip (Stitch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: AppColors.primaryFixed,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.primaryPurple,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '99.4% Trust Index',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontFamilyFallback: AppTextStyles.fontFallbacks,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimaryFixed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
