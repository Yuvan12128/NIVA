import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class RecommendedItem {
  const RecommendedItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
}

/// Recommended discoveries carousel section for the NIVA Home Screen.
/// Emphasizes diverse discovery paths (People, Opportunities, Communities, Information).
class RecommendedSection extends StatelessWidget {
  const RecommendedSection({super.key, this.onSeeAllTap, this.onItemTap});

  final VoidCallback? onSeeAllTap;
  final ValueChanged<RecommendedItem>? onItemTap;

  static const List<RecommendedItem> items = [
    RecommendedItem(
      title: 'Learn Graphic Design',
      subtitle: '12 people offering guidance',
      category: 'Design',
      icon: Icons.palette_outlined,
      iconColor: AppColors.servicesIcon,
      iconBg: AppColors.servicesBg,
    ),
    RecommendedItem(
      title: 'Open Source Projects',
      subtitle: '8 active community calls',
      category: 'Projects',
      icon: Icons.lightbulb_outline_rounded,
      iconColor: AppColors.opportunitiesIcon,
      iconBg: AppColors.opportunitiesBg,
    ),
    RecommendedItem(
      title: 'Mobile Architecture Guild',
      subtitle: '1.4k members collaborating',
      category: 'Guild',
      icon: Icons.groups_outlined,
      iconColor: AppColors.communitiesIcon,
      iconBg: AppColors.communitiesBg,
    ),
    RecommendedItem(
      title: 'Study & Career Guides',
      subtitle: 'Curated experiences & paths',
      category: 'Guides',
      icon: Icons.menu_book_outlined,
      iconColor: AppColors.infoIcon,
      iconBg: AppColors.infoBg,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'Recommended for you',
                style: AppTextStyles.subtitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(onPressed: onSeeAllTap, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Horizontal discovery cards
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = items[index];
              return _RecommendedCard(
                item: item,
                onTap: () => onItemTap?.call(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.item, required this.onTap});

  final RecommendedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppSpacing.borderRadiusLg,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.iconBg,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        item.category,
                        style: AppTextStyles.captionSmall.copyWith(
                          color: item.iconColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
