import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_avatar.dart';
import '../../../core/widgets/niva_button.dart';
import '../../../core/widgets/niva_search_bar.dart';

/// The 5 core discovery facets supported across NIVA.
enum DiscoveryType {
  people,
  services,
  information,
  opportunities,
  communities;

  String get label => switch (this) {
    DiscoveryType.people => 'People',
    DiscoveryType.services => 'Services',
    DiscoveryType.information => 'Information',
    DiscoveryType.opportunities => 'Opportunities',
    DiscoveryType.communities => 'Communities',
  };

  Color get iconColor => switch (this) {
    DiscoveryType.people => AppColors.peopleIcon,
    DiscoveryType.services => AppColors.servicesIcon,
    DiscoveryType.information => AppColors.infoIcon,
    DiscoveryType.opportunities => AppColors.opportunitiesIcon,
    DiscoveryType.communities => AppColors.communitiesIcon,
  };

  Color get backgroundColor => switch (this) {
    DiscoveryType.people => AppColors.peopleBg,
    DiscoveryType.services => AppColors.servicesBg,
    DiscoveryType.information => AppColors.infoBg,
    DiscoveryType.opportunities => AppColors.opportunitiesBg,
    DiscoveryType.communities => AppColors.communitiesBg,
  };

  IconData get icon => switch (this) {
    DiscoveryType.people => Icons.person_outline_rounded,
    DiscoveryType.services => Icons.business_center_outlined,
    DiscoveryType.information => Icons.menu_book_outlined,
    DiscoveryType.opportunities => Icons.lightbulb_outline_rounded,
    DiscoveryType.communities => Icons.groups_outlined,
  };
}

/// Model for a universal discovery item in NIVA.
class DiscoveryModel {
  const DiscoveryModel({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.location,
    required this.meta,
    required this.actionLabel,
    this.authorName,
    this.tags = const [],
  });

  final String id;
  final String title;
  final DiscoveryType type;
  final String description;
  final String location;
  final String meta;
  final String actionLabel;
  final String? authorName;
  final List<String> tags;
}

/// NIVA Explore Screen — universal discovery space for People, Services,
/// Information, Opportunities, and Communities.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DiscoveryType? _selectedCategory;

  static const List<String> _quickSearchHints = [
    'Java tutor',
    'Laptop repair',
    'Frontend developer',
    'Photography',
    'Remote job',
  ];

  static const List<String> _trendingTopics = [
    'MachineLearning',
    'CareerMentorship',
    'SystemDesign',
    'OpenSourceContrib',
    'HardwareDiagnostics',
    'RemoteFellowships',
  ];

  static const List<DiscoveryModel> _allDiscoveries = [
    DiscoveryModel(
      id: 'd1',
      title: 'Java & Algorithms Mentorship',
      type: DiscoveryType.people,
      authorName: 'Suresh Raina',
      description: '1-on-1 practical guidance on core Java, concurrency, and technical interview problem solving.',
      location: 'Chennai',
      meta: 'Available today',
      actionLabel: 'Connect',
      tags: ['Java', 'Mentorship', 'Backend'],
    ),
    DiscoveryModel(
      id: 'd2',
      title: 'React & Mobile Guild',
      type: DiscoveryType.communities,
      description: 'Collaborative global developer collective sharing production code reviews and architecture patterns.',
      location: 'Remote',
      meta: '2.8k members',
      actionLabel: 'Join',
      tags: ['React', 'Mobile', 'Frontend'],
    ),
    DiscoveryModel(
      id: 'd3',
      title: 'Open Source Accessibility Tools',
      type: DiscoveryType.opportunities,
      description: 'Call for contributors to build open-source assistive mobile components and screen-reader integrations.',
      location: 'Remote',
      meta: '6 roles open',
      actionLabel: 'Contribute',
      tags: ['Open Source', 'Flutter', 'Accessibility'],
    ),
    DiscoveryModel(
      id: 'd4',
      title: 'Field Photography & Natural Light Guide',
      type: DiscoveryType.information,
      description: 'Curated handbook covering exposure balance, natural lighting portraiture, and lens calibration.',
      location: 'Curated',
      meta: '15 min read',
      actionLabel: 'Read',
      tags: ['Photography', 'Guide', 'Creative'],
    ),
    DiscoveryModel(
      id: 'd5',
      title: 'Bengaluru Systems Architecture Roundtable',
      type: DiscoveryType.communities,
      description: 'Monthly peer discussions on event-driven backends, distributed systems, and real-time reliability.',
      location: 'Bengaluru',
      meta: 'This Saturday',
      actionLabel: 'RSVP',
      tags: ['Architecture', 'Meetup', 'Systems'],
    ),
    DiscoveryModel(
      id: 'd6',
      title: 'Hardware Diagnostics & Board Repair',
      type: DiscoveryType.services,
      authorName: 'Ravi Kumar',
      description: 'Certified component-level motherboard diagnostics, thermal maintenance, and display troubleshooting.',
      location: 'Chennai',
      meta: 'Available today',
      actionLabel: 'Request',
      tags: ['Laptop repair', 'Hardware', 'Troubleshooting'],
    ),
    DiscoveryModel(
      id: 'd7',
      title: 'Remote Frontend Engineering Fellowship',
      type: DiscoveryType.opportunities,
      description: 'Full-time remote fellowship working alongside senior production engineers on large-scale web apps.',
      location: 'Remote',
      meta: 'Active cohort',
      actionLabel: 'Apply',
      tags: ['Frontend developer', 'Remote job', 'Engineering'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategoryFilterTap(DiscoveryType? type) {
    setState(() {
      _selectedCategory = (_selectedCategory == type) ? null : type;
    });
  }

  void _applyQuickSearch(String term) {
    setState(() {
      _searchController.text = term;
      _searchQuery = term;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
    });
  }

  List<DiscoveryModel> get _filteredDiscoveries {
    return _allDiscoveries
        .where((item) {
          if (_selectedCategory != null && item.type != _selectedCategory) {
            return false;
          }
          if (_searchQuery.trim().isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchTitle = item.title.toLowerCase().contains(query);
            final matchDesc = item.description.toLowerCase().contains(query);
            final matchTags = item.tags.any(
              (t) => t.toLowerCase().contains(query),
            );
            final matchType = item.type.label.toLowerCase().contains(query);
            final matchLoc = item.location.toLowerCase().contains(query);
            return matchTitle ||
                matchDesc ||
                matchTags ||
                matchType ||
                matchLoc;
          }
          return true;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final discoveries = _filteredDiscoveries;
    final isFiltering =
        _searchQuery.trim().isNotEmpty || _selectedCategory != null;

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
              // 1. Header
              const Text('Explore', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Discover people, knowledge, opportunities and more.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Search
              NivaSearchBar(
                controller: _searchController,
                hintText: 'Search anything...',
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                onSubmitted: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick Search Examples
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _quickSearchHints.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final hint = _quickSearchHints[index];
                    final isSelected =
                        _searchQuery.toLowerCase() == hint.toLowerCase();
                    return GestureDetector(
                      onTap: () => _applyQuickSearch(hint),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 6,
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
                            hint,
                            style: AppTextStyles.captionSmall.copyWith(
                              color: isSelected
                                  ? AppColors.textOnPrimary
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 3. Discovery Categories Filter Row
              _CategoryFilterRow(
                selectedType: _selectedCategory,
                onSelectType: _onCategoryFilterTap,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 4. Suggested Discoveries / Search Results
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isFiltering
                        ? 'Discovery Results (${discoveries.length})'
                        : 'Suggested Discoveries',
                    style: AppTextStyles.subtitle,
                  ),
                  if (isFiltering)
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Reset'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              if (discoveries.isEmpty)
                _EmptyDiscoveryState(onClear: _clearFilters)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: discoveries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return _DiscoveryCard(
                      item: discoveries[index],
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Exploring ${discoveries[index].title}...',
                            ),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),

              // 5. Trending / Popular Topics (shown when not actively searching)
              if (!isFiltering) ...[
                const SizedBox(height: AppSpacing.xxl),
                const Text('Trending Topics', style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Useful discovery areas gaining traction',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _trendingTopics
                      .map((topic) {
                        return ActionChip(
                          label: Text('#$topic'),
                          labelStyle: AppTextStyles.captionSmall.copyWith(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: AppColors.servicesBg,
                          side: BorderSide.none,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusFull,
                          ),
                          onPressed: () => _applyQuickSearch(topic),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // 6. Nearby / Regional Discoveries Section
                const Text('Nearby & Regional', style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Discoveries within your broader region',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _RegionalBanner(onTap: () => _applyQuickSearch('Chennai')),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Category filter chips row for quick facet toggling.
class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.selectedType,
    required this.onSelectType,
  });

  final DiscoveryType? selectedType;
  final ValueChanged<DiscoveryType?> onSelectType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // "All" Chip
          _FilterChip(
            label: 'All',
            icon: Icons.auto_awesome_rounded,
            isSelected: selectedType == null,
            onTap: () => onSelectType(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...DiscoveryType.values.map((type) {
            final isSelected = selectedType == type;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _FilterChip(
                label: type.label,
                icon: type.icon,
                iconColor: isSelected
                    ? AppColors.textOnPrimary
                    : type.iconColor,
                isSelected: isSelected,
                onTap: () => onSelectType(type),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minWidth: AppSpacing.minTouchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.card,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.textOnPrimary
                  : (iconColor ?? AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.captionSmall.copyWith(
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Universal Discovery Card communicating its solution type visually.
class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({required this.item, required this.onTap});

  final DiscoveryModel item;
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Solution Type Badge + Meta/Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.type.backgroundColor,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.type.icon,
                            color: item.type.iconColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.type.label,
                            style: AppTextStyles.captionSmall.copyWith(
                              color: item.type.iconColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.location} • ${item.meta}',
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Title & Description
                Text(
                  item.title,
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),

                // Bottom Row: Tag Pills & Action CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.authorName != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NivaAvatar(
                            name: item.authorName!,
                            size: 26,
                            backgroundColor: item.type.backgroundColor,
                            textColor: item.type.iconColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.authorName!,
                            style: AppTextStyles.captionSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      )
                    else if (item.tags.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: item.tags
                            .take(2)
                            .map((tag) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: AppSpacing.borderRadiusSm,
                                  ),
                                  child: Text(
                                    tag,
                                    style: AppTextStyles.captionSmall.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                      )
                    else
                      const SizedBox.shrink(),

                    // Clean Action Button
                    NivaButton(
                      label: item.actionLabel,
                      variant: NivaButtonVariant.secondary,
                      height: 36,
                      onPressed: onTap,
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

/// Fallback state when query yields no discoveries.
class _EmptyDiscoveryState extends StatelessWidget {
  const _EmptyDiscoveryState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.lg,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.servicesBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.primaryPurple,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('No discoveries found', style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try searching for other terms like "Java", "Mentor", or "Open Source".',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          NivaButton(
            label: 'Clear Filters',
            variant: NivaButtonVariant.secondary,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

/// Regional discovery container showcasing location-relevant options.
class _RegionalBanner extends StatelessWidget {
  const _RegionalBanner({required this.onTap});

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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.infoBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.infoIcon,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Regional Hubs & Groups',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Discover local workshops, peer circles, and hardware specialists.',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
