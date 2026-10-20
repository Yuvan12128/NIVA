import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_search_bar.dart';
import '../../auth/data/auth_service.dart';
import '../../notifications/presentation/notifications_screen.dart';
import 'widgets/category_grid.dart';
import 'widgets/home_header.dart';
import 'widgets/recent_needs_section.dart';
import 'widgets/recommended_section.dart';

/// Primary Home Screen for NIVA — the universal need-to-solution discovery platform.
/// Optimized for 60 FPS performance, fast startup, and clean layout hierarchy.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onSearchTap,
    this.onCategoryTap,
    this.onAvatarTap,
    this.onCreateNeedTap,
    this.onNotificationTap,
  });

  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onCreateNeedTap;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                userName:
                    AuthService.instance.currentUser?.displayName?.isNotEmpty ==
                        true
                    ? AuthService.instance.currentUser!.displayName!
                          .split(' ')
                          .first
                    : (AuthService.instance.currentUser?.email != null
                          ? AuthService.instance.currentUser!.email!
                                .split('@')
                                .first
                          : 'Arun'),
                onAvatarTap: onAvatarTap,
                onNotificationTap:
                    onNotificationTap ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Hero Connection Studio (Stitch design system)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white,
                      AppColors.surfaceLow,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x145B4BDB),
                      blurRadius: 24,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Flexible(
                                child: Text(
                                  'What do you need today?',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontFamilyFallback:
                                        AppTextStyles.fontFallbacks,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: const Text(
                            'Peer Verified',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontFamilyFallback: AppTextStyles.fontFallbacks,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    NivaSearchBar(
                      readOnly: true,
                      hintText: 'Find people, services, info...',
                      onTap: onSearchTap ?? onCreateNeedTap,
                      onFilterTap: onSearchTap,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Dual Primary Intent Modes
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onCreateNeedTap,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x335B4BDB),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'I Need',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontFamilyFallback:
                                              AppTextStyles.fontFallbacks,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onCreateNeedTap,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A171725),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.volunteer_activism_rounded,
                                      color: AppColors.tertiary,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Offer Help',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontFamilyFallback:
                                              AppTextStyles.fontFallbacks,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryPurple,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              CategoryGrid(
                onSelectCategory: (category) {
                  if (category == 'I Can Help') {
                    onCreateNeedTap?.call();
                  } else {
                    onCategoryTap?.call(category);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              RecommendedSection(
                onSeeAllTap: onSearchTap,
                onItemTap: (item) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exploring ${item.title}...'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              RecentNeedsSection(
                onNeedTap: (need) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected "${need.title}"'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
