import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/niva_avatar.dart';

/// Top branding header, greeting, and profile avatar for NIVA Home Screen.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.userName = 'Arun', this.onAvatarTap});

  final String userName;
  final VoidCallback? onAvatarTap;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

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
            const Text(
              'NIVA',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontFamilyFallback: AppTextStyles.fontFallbacks,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryPurple,
                letterSpacing: 0.6,
              ),
            ),
            GestureDetector(
              onTap: onAvatarTap,
              child: NivaAvatar(
                name: userName,
                size: 42,
                backgroundColor: AppColors.servicesBg,
                textColor: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Greeting & Main Prompt
        Text(
          _getGreeting(),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text('What do you need today?', style: AppTextStyles.h2),
      ],
    );
  }
}
