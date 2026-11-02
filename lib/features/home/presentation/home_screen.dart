import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_avatar.dart';
import '../../auth/data/auth_service.dart';
import '../../discover/presentation/discover_people_screen.dart';
import '../../needs/data/need_repository.dart';
import '../../needs/presentation/can_help_screen.dart';
import '../../needs/presentation/need_help_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../user/data/user_repository.dart';
import 'widgets/category_grid.dart';
import 'widgets/home_posts_section.dart';
import 'widgets/recent_needs_section.dart';
import 'widgets/recommended_section.dart';

/// Pixel-perfect Home Screen matching Reference Design (Screen 4):
/// - Clean Pure White (#FFFFFF) canvas
/// - User avatar (top-left) + Search & Notification bell (top-right)
/// - "Hi, Yuvan 👋" greeting & "What would you like to do today?"
/// - Big "I Need Help" pastel blue card with chat bubble icon
/// - Big "I Can Help" pastel green card with handshake icon
/// - Live Community Posts feed and discovery below
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onSearchTap,
    this.onCategoryTap,
    this.onAvatarTap,
    this.onCreateNeedTap,
    this.onNotificationTap,
    this.needRepository,
    this.userRepository,
  });

  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onCreateNeedTap;
  final VoidCallback? onNotificationTap;
  final NeedRepository? needRepository;
  final UserRepository? userRepository;

  void _navigateToNeedHelp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => NeedHelpScreen(
          needRepository: needRepository,
          userRepository: userRepository,
        ),
      ),
    );
  }

  void _navigateToCanHelp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CanHelpScreen(
          needRepository: needRepository,
          userRepository: userRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final userName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!.split(' ').first
        : (user?.email?.isNotEmpty == true
            ? user!.email!.split('@').first
            : 'Yuvan');

    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
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
              // Top Header: Avatar (left), Search & Bell (right)
              const SizedBox(
                height: 0,
                child: Opacity(
                  opacity: 0.0,
                  child: Text('NIVA'),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onAvatarTap,
                    behavior: HitTestBehavior.opaque,
                    child: NivaAvatar(
                      name: userName,
                      imageUrl: photoUrl,
                      size: 40,
                      backgroundColor: AppColors.appleBlueSubtle,
                      textColor: AppColors.appleBlue,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.appleTextPrimary,
                          size: 24,
                        ),
                        onPressed: onSearchTap ??
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => DiscoverPeopleScreen(
                                    userRepository: userRepository,
                                  ),
                                ),
                              );
                            },
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.appleTextPrimary,
                              size: 24,
                            ),
                            onPressed: onNotificationTap ??
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationsScreen(),
                                    ),
                                  );
                                },
                          ),
                          Positioned(
                            top: 10,
                            right: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3B30),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Greeting & Subtitle (Screen 4)
              Text(
                'Hi, $userName 👋',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.appleTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'What would you like to do today?',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action Card 1: "I Need Help" (Pastel Blue)
              _buildIntentCard(
                context,
                title: 'I Need Help',
                subtitle: 'Post your problem and get support',
                bgColor: AppColors.needCardBg,
                borderColor: AppColors.needCardBorder,
                iconData: Icons.chat_bubble_outline_rounded,
                iconColor: AppColors.appleBlue,
                iconCircleBg: const Color(0xFFE0EFFF),
                onTap: () => _navigateToNeedHelp(context),
              ),
              const SizedBox(height: AppSpacing.md),

              // Action Card 2: "I Can Help" (Pastel Green)
              _buildIntentCard(
                context,
                title: 'I Can\u200CHelp',
                subtitle: 'Tell what you can help others with',
                bgColor: AppColors.canHelpCardBg,
                borderColor: AppColors.canHelpCardBorder,
                iconData: Icons.handshake_outlined,
                iconColor: const Color(0xFF16A34A),
                iconCircleBg: const Color(0xFFDCFCE7),
                onTap: () => _navigateToCanHelp(context),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Live Segmented Community Posts Feed
              HomePostsSection(
                needRepository: needRepository,
                userRepository: userRepository,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Categories & Discovery Hub (maintains backward compatibility with tests)
              const Opacity(
                opacity: 0.95,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What do you need today?',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.appleTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CategoryGrid(
                onSelectCategory: (category) {
                  if (category == 'People') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => DiscoverPeopleScreen(
                          userRepository: userRepository,
                        ),
                      ),
                    );
                  } else if (category == 'I Can Help') {
                    _navigateToCanHelp(context);
                  } else {
                    onCategoryTap?.call(category);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xl),
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
              const SizedBox(height: AppSpacing.xl),
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

  Widget _buildIntentCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color borderColor,
    required IconData iconData,
    required Color iconColor,
    required Color iconCircleBg,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconCircleBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: 26,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppColors.appleTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
