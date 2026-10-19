import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/niva_avatar.dart';

class NeedItem {
  const NeedItem({
    required this.id,
    required this.title,
    required this.category,
    required this.authorName,
    required this.location,
    required this.timeAgo,
    required this.responsesCount,
    this.tagColor = AppColors.primaryPurple,
    this.tagBg = AppColors.servicesBg,
  });

  final String id;
  final String title;
  final String category;
  final String authorName;
  final String location;
  final String timeAgo;
  final int responsesCount;
  final Color tagColor;
  final Color tagBg;
}

/// Recent needs list on the Home screen with filter chips and compact cards.
class RecentNeedsSection extends StatefulWidget {
  const RecentNeedsSection({super.key, this.onNeedTap});

  final ValueChanged<NeedItem>? onNeedTap;

  @override
  State<RecentNeedsSection> createState() => _RecentNeedsSectionState();
}

class _RecentNeedsSectionState extends State<RecentNeedsSection> {
  int _selectedFilterIndex = 0;
  static const List<String> _filters = ['All', 'Nearby', 'Trending'];

  static const List<NeedItem> _allNeeds = [
    NeedItem(
      id: '1',
      title: 'Need a Java & DSA tutor',
      category: 'Education',
      authorName: 'Priya S',
      location: 'Chennai',
      timeAgo: '4h ago',
      responsesCount: 12,
      tagColor: AppColors.infoIcon,
      tagBg: AppColors.infoBg,
    ),
    NeedItem(
      id: '2',
      title: 'Looking for a documentary videographer',
      category: 'Creative',
      authorName: 'Alex M',
      location: 'Bengaluru',
      timeAgo: '6h ago',
      responsesCount: 18,
      tagColor: AppColors.servicesIcon,
      tagBg: AppColors.servicesBg,
    ),
    NeedItem(
      id: '3',
      title: 'Need open-source mobile contributors',
      category: 'Technology',
      authorName: 'Marcus K',
      location: 'Remote',
      timeAgo: '8h ago',
      responsesCount: 25,
      tagColor: AppColors.opportunitiesIcon,
      tagBg: AppColors.opportunitiesBg,
    ),
    NeedItem(
      id: '4',
      title: 'Advice on university relocation',
      category: 'Advice',
      authorName: 'Elena R',
      location: 'Remote',
      timeAgo: '10h ago',
      responsesCount: 31,
      tagColor: AppColors.peopleIcon,
      tagBg: AppColors.peopleBg,
    ),
  ];

  List<NeedItem> get _filteredNeeds {
    if (_selectedFilterIndex == 1) {
      // Nearby sample filter
      return _allNeeds
          .where((n) => n.location != 'Remote')
          .toList(growable: false);
    } else if (_selectedFilterIndex == 2) {
      // Trending sample filter
      return _allNeeds
          .where((n) => n.responsesCount >= 20)
          .toList(growable: false);
    }
    return _allNeeds;
  }

  @override
  Widget build(BuildContext context) {
    final needs = _filteredNeeds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Text('Recent Needs', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.md),
        // Filter Chips Row
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _filters.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final isSelected = _selectedFilterIndex == index;
              return GestureDetector(
                onTap: () {
                  if (_selectedFilterIndex != index) {
                    setState(() {
                      _selectedFilterIndex = index;
                    });
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.minTouchTarget,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryPurple
                        : AppColors.card,
                    borderRadius: AppSpacing.borderRadiusFull,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryPurple
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _filters[index],
                      style: AppTextStyles.captionSmall.copyWith(
                        color: isSelected
                            ? AppColors.textOnPrimary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // List of Compact Need Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: needs.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final need = needs[index];
            return _NeedCard(
              need: need,
              onTap: () => widget.onNeedTap?.call(need),
            );
          },
        ),
      ],
    );
  }
}

class _NeedCard extends StatelessWidget {
  const _NeedCard({required this.need, required this.onTap});

  final NeedItem need;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                NivaAvatar(
                  name: need.authorName,
                  size: 42,
                  backgroundColor: need.tagBg,
                  textColor: need.tagColor,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        need.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: need.tagBg,
                              borderRadius: AppSpacing.borderRadiusSm,
                            ),
                            child: Text(
                              need.category,
                              style: AppTextStyles.captionSmall.copyWith(
                                color: need.tagColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '${need.location} • ${need.timeAgo}',
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 15,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${need.responsesCount}',
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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
