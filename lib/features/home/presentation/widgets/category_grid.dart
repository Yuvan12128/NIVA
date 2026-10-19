import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Item descriptor for the 6 core discovery areas.
class DiscoveryCategoryItem {
  const DiscoveryCategoryItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
}

/// 3x2 Grid displaying the 6 universal discovery areas of NIVA:
/// People, Services, Information, Opportunities, Communities, and I Can Help.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, this.onSelectCategory});

  final ValueChanged<String>? onSelectCategory;

  static const List<DiscoveryCategoryItem> categories = [
    DiscoveryCategoryItem(
      title: 'People',
      icon: Icons.person_rounded,
      iconColor: AppColors.peopleIcon,
      backgroundColor: AppColors.peopleBg,
    ),
    DiscoveryCategoryItem(
      title: 'Services',
      icon: Icons.business_center_rounded,
      iconColor: AppColors.servicesIcon,
      backgroundColor: AppColors.servicesBg,
    ),
    DiscoveryCategoryItem(
      title: 'Information',
      icon: Icons.menu_book_rounded,
      iconColor: AppColors.infoIcon,
      backgroundColor: AppColors.infoBg,
    ),
    DiscoveryCategoryItem(
      title: 'Opportunities',
      icon: Icons.lightbulb_rounded,
      iconColor: AppColors.opportunitiesIcon,
      backgroundColor: AppColors.opportunitiesBg,
    ),
    DiscoveryCategoryItem(
      title: 'Communities',
      icon: Icons.groups_rounded,
      iconColor: AppColors.communitiesIcon,
      backgroundColor: AppColors.communitiesBg,
    ),
    DiscoveryCategoryItem(
      title: 'I Can Help',
      icon: Icons.volunteer_activism_rounded,
      iconColor: AppColors.helpIcon,
      backgroundColor: AppColors.helpBg,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = AppSpacing.md;
        final double itemWidth = (constraints.maxWidth - (spacing * 2)) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: categories
              .map((cat) {
                return SizedBox(
                  width: itemWidth,
                  child: _CategoryTile(
                    item: cat,
                    onTap: () => onSelectCategory?.call(cat.title),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, required this.onTap});

  final DiscoveryCategoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
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
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.xs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 22),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.title,
                  style: AppTextStyles.captionSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
