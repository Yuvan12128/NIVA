import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/niva_avatar.dart';
import '../../../needs/data/need_model.dart';
import '../../../needs/data/need_repository.dart';

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

  factory NeedItem.fromNeedModel(NeedModel model) {
    final (color, bg) = _resolveCategoryColors(model.category);
    return NeedItem(
      id: model.needId,
      title: model.title,
      category: model.category,
      authorName: model.authorName?.isNotEmpty == true
          ? model.authorName!
          : (model.type == 'help' ? 'Helper' : 'Requester'),
      location: model.location,
      timeAgo: _formatTimeAgo(model.createdAt),
      responsesCount: 0,
      tagColor: color,
      tagBg: bg,
    );
  }
}

(Color, Color) _resolveCategoryColors(String category) {
  switch (category.toLowerCase()) {
    case 'technology':
    case 'services':
      return (AppColors.servicesIcon, AppColors.servicesBg);
    case 'education':
    case 'information':
      return (AppColors.infoIcon, AppColors.infoBg);
    case 'creative':
    case 'people':
      return (AppColors.peopleIcon, AppColors.peopleBg);
    case 'opportunities':
    case 'career':
      return (AppColors.opportunitiesIcon, AppColors.opportunitiesBg);
    case 'communities':
    case 'hardware':
      return (AppColors.communitiesIcon, AppColors.communitiesBg);
    default:
      return (AppColors.primaryPurple, AppColors.servicesBg);
  }
}

String _formatTimeAgo(DateTime? date) {
  if (date == null) return 'Just now';
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

/// Recent needs list on the Home screen with filter chips and compact cards.
/// Reads real needs from Firestore using pagination-friendly, limited queries.
class RecentNeedsSection extends StatefulWidget {
  const RecentNeedsSection({super.key, this.onNeedTap, this.needRepository});

  final ValueChanged<NeedItem>? onNeedTap;
  final NeedRepository? needRepository;

  @override
  State<RecentNeedsSection> createState() => _RecentNeedsSectionState();
}

class _RecentNeedsSectionState extends State<RecentNeedsSection> {
  int _selectedFilterIndex = 0;
  static const List<String> _filters = ['All', 'Nearby', 'Trending'];

  late final NeedRepository _needRepository =
      widget.needRepository ?? NeedRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<NeedItem> _needs = [];

  @override
  void initState() {
    super.initState();
    _fetchRecentNeeds();
  }

  Future<void> _fetchRecentNeeds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final models = await _needRepository.getRecentNeeds(limit: 10);
      if (!mounted) return;
      setState(() {
        _needs = models.map(NeedItem.fromNeedModel).toList(growable: false);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load recent needs';
        _isLoading = false;
      });
    }
  }

  List<NeedItem> get _filteredNeeds {
    if (_selectedFilterIndex == 1) {
      return _needs
          .where((n) => n.location.toLowerCase() != 'remote')
          .toList(growable: false);
    } else if (_selectedFilterIndex == 2) {
      return _needs.where((n) => n.responsesCount >= 1).toList(growable: false);
    }
    return _needs;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Text('Recent Needs', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.md),

        // 1. Loading State
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryPurple,
                  ),
                ),
              ),
            ),
          )
        // 2. Error State
        else if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _fetchRecentNeeds,
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )
        // 3. Empty State
        else if (_needs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.hourglass_empty_rounded,
                  color: AppColors.textTertiary,
                  size: 28,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'No recent needs published yet',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap the + button below to publish your first need or offer help.',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        // 4. Content / Filtered List
        else ...[
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
            itemCount: _filteredNeeds.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final need = _filteredNeeds[index];
              return _NeedCard(
                need: need,
                onTap: () => widget.onNeedTap?.call(need),
              );
            },
          ),
        ],
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
