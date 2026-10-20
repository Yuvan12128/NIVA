import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
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
              NivaSearchBar(
                readOnly: true,
                hintText: 'What do you need today?',
                onTap: onSearchTap ?? onCreateNeedTap,
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
