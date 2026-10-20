import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_avatar.dart';
import '../../../core/widgets/niva_button.dart';
import '../../../core/widgets/niva_search_bar.dart';
import '../../auth/data/auth_service.dart';
import '../../connect/data/connection_request_repository.dart';
import '../../matching/presentation/widgets/matching_sheet.dart';
import '../../needs/data/need_repository.dart';
import '../../safety/data/safety_repository.dart';
import '../data/discovery_model.dart';
import '../data/search_filter_model.dart';
import '../data/search_service.dart';
import 'widgets/filter_bottom_sheet.dart';

export '../data/discovery_model.dart';

/// NIVA Explore Screen — universal discovery space for People, Services,
/// Information, Opportunities, Communities, and Needs / Help offers.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.needRepository,
    this.searchService,
    this.connectionRequestRepository,
    this.safetyRepository,
  });

  final NeedRepository? needRepository;
  final SearchService? searchService;
  final ConnectionRequestRepository? connectionRequestRepository;
  final SafetyRepository? safetyRepository;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  String _searchQuery = '';
  SearchFilter _searchFilter = SearchFilter.empty;
  bool _isLoading = false;
  String? _errorMessage;

  late final SearchService _searchService =
      widget.searchService ?? SearchService();
  late final ConnectionRequestRepository _connectionRepo =
      widget.connectionRequestRepository ?? ConnectionRequestRepository();
  late final SafetyRepository _safetyRepo =
      widget.safetyRepository ?? SafetyRepository();

  List<DiscoveryModel> _discoveries = [];

  static const List<String> _quickSearchHints = [
    'Java tutor',
    'Laptop repair',
    'React developer',
    'Photography',
    'Remote job',
    'Graphic designer',
  ];

  static const List<String> _trendingTopics = [
    'MachineLearning',
    'CareerMentorship',
    'SystemDesign',
    'OpenSourceContrib',
    'HardwareDiagnostics',
    'RemoteFellowships',
  ];

  @override
  void initState() {
    super.initState();
    _executeSearch();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Debounced search trigger (300ms) to avoid executing queries on every keystroke.
  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    setState(() {
      _searchQuery = val;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch();
    });
  }

  void _onSearchSubmitted(String val) {
    _debounceTimer?.cancel();
    setState(() {
      _searchQuery = val;
    });
    _executeSearch();
  }

  void _clearSearchText() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _executeSearch();
  }

  Future<void> _executeSearch({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUid = AuthService.instance.currentUser?.uid;
      Set<String> blockedIds = const {};
      if (currentUid != null) {
        blockedIds = await _safetyRepo.getBlockedUserIds(currentUid);
      }

      if (forceRefresh) {
        SearchService.clearCache();
      }

      final results = await _searchService.searchDiscoveries(
        query: _searchQuery,
        filter: _searchFilter,
        blockedUserIds: blockedIds,
        limit: 30,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;
      setState(() {
        _discoveries = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load search results. Please try again.';
        _isLoading = false;
      });
      debugPrint('ExploreScreen._executeSearch error: $e');
    }
  }

  void _onCategoryFilterTap(DiscoveryType? type) {
    final newCategory = (_searchFilter.category == type) ? null : type;
    setState(() {
      _searchFilter = _searchFilter.copyWith(category: () => newCategory);
    });
    _executeSearch();
  }

  void _onTypeFilterTap(String? type) {
    final newType = (_searchFilter.type == type) ? null : type;
    setState(() {
      _searchFilter = _searchFilter.copyWith(type: () => newType);
    });
    _executeSearch();
  }

  void _applyQuickSearch(String term) {
    _debounceTimer?.cancel();
    setState(() {
      _searchController.text = term;
      _searchQuery = term;
    });
    _executeSearch();
  }

  void _clearFilters() {
    _debounceTimer?.cancel();
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _searchFilter = SearchFilter.empty;
    });
    _executeSearch();
  }

  void _openFilterBottomSheet() {
    FilterBottomSheet.show(
      context,
      currentFilter: _searchFilter,
      onApply: (updated) {
        setState(() {
          _searchFilter = updated;
        });
        _executeSearch();
      },
    );
  }

  void _handleItemAction(DiscoveryModel item) {
    // 1. If it's a Need: proceed to Matching Sheet
    if (item.needModel != null && item.needModel!.type == 'need') {
      MatchingSheet.show(context, need: item.needModel!);
      return;
    }

    // 2. If it's a Help Offer or Helper Profile: handle Connect
    if (item.itemType == 'help' || item.type == DiscoveryType.people) {
      _showConnectPrompt(item);
      return;
    }

    // 3. Fallback discovery dialog/snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exploring ${item.title}...'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showConnectPrompt(DiscoveryModel item) async {
    final currentUid = AuthService.instance.currentUser?.uid;
    if (currentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to send a connect request.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (item.authorId == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot send a connection request to yourself.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final targetName = item.authorName ?? item.title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        title: Text('Connect with $targetName?', style: AppTextStyles.subtitle),
        content: Text(
          'Send a connection request to collaborate or receive help for this discovery.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final toUid = item.authorId ?? item.id;
        final needId = item.needModel?.needId ?? item.id;
        await _connectionRepo.sendConnectRequest(
          fromUserId: currentUid,
          toUserId: toUid,
          needId: needId,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to $targetName!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send request: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFiltering =
        _searchQuery.trim().isNotEmpty || _searchFilter.hasActiveFilters;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _executeSearch(forceRefresh: true),
          color: AppColors.primaryPurple,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header with Location Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Explore', style: AppTextStyles.h1),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Discover people, knowledge, opportunities and more.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.primaryPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bengaluru, IN',
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2. Search & Filter Bar
                NivaSearchBar(
                  controller: _searchController,
                  hintText: 'Search anything...',
                  onChanged: _onSearchChanged,
                  onSubmitted: _onSearchSubmitted,
                  onClear: _clearSearchText,
                  onFilterTap: _openFilterBottomSheet,
                  hasActiveFilters: _searchFilter.hasActiveFilters,
                  filterCount: _searchFilter.activeFiltersCount,
                ),
                const SizedBox(height: AppSpacing.md),

                // Active Filter Chips (shown when filters are applied)
                if (_searchFilter.hasActiveFilters) ...[
                  _ActiveFilterChipsRow(
                    filter: _searchFilter,
                    onRemoveCategory: () {
                      setState(() {
                        _searchFilter = _searchFilter.copyWith(
                          category: () => null,
                        );
                      });
                      _executeSearch();
                    },
                    onRemoveType: () {
                      setState(() {
                        _searchFilter = _searchFilter.copyWith(
                          type: () => null,
                        );
                      });
                      _executeSearch();
                    },
                    onRemoveLocation: () {
                      setState(() {
                        _searchFilter = _searchFilter.copyWith(
                          location: () => null,
                        );
                      });
                      _executeSearch();
                    },
                    onRemoveAvailability: () {
                      setState(() {
                        _searchFilter = _searchFilter.copyWith(
                          availability: () => null,
                        );
                      });
                      _executeSearch();
                    },
                    onResetSort: () {
                      setState(() {
                        _searchFilter = _searchFilter.copyWith(
                          sortBy: SearchSortBy.relevance,
                        );
                      });
                      _executeSearch();
                    },
                    onClearAll: _clearFilters,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Quick Search Suggestions
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
                  selectedType: _searchFilter.category,
                  onSelectType: _onCategoryFilterTap,
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Intent Filter Pills (Type Row: All Types, I Need, I Can Help)
                _IntentFilterRow(
                  selectedType: _searchFilter.type,
                  onSelectType: _onTypeFilterTap,
                ),
                const SizedBox(height: AppSpacing.lg),

                // 5. Discoveries Header & Result Count + Live Matching
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFiltering
                                ? 'Discovery Results (${_discoveries.length})'
                                : 'Suggested Discoveries',
                            style: AppTextStyles.subtitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Showing ${_discoveries.length} matches near you',
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (isFiltering)
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Reset'),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: AppSpacing.borderRadiusFull,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryPurple,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Live Matching',
                                  style: AppTextStyles.captionSmall.copyWith(
                                    color: AppColors.primaryPurple,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Error State + Retry
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _executeSearch,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),

                // Loading State
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else if (_discoveries.isEmpty)
                  _EmptyDiscoveryState(onClear: _clearFilters)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _discoveries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return _DiscoveryCard(
                        item: _discoveries[index],
                        onTap: () => _handleItemAction(_discoveries[index]),
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
                  const Text(
                    'Nearby & Regional',
                    style: AppTextStyles.subtitle,
                  ),
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
      ),
    );
  }
}

/// Horizontal list of active filter chips with individual dismiss handlers.
class _ActiveFilterChipsRow extends StatelessWidget {
  const _ActiveFilterChipsRow({
    required this.filter,
    required this.onRemoveCategory,
    required this.onRemoveType,
    required this.onRemoveLocation,
    required this.onRemoveAvailability,
    required this.onResetSort,
    required this.onClearAll,
  });

  final SearchFilter filter;
  final VoidCallback onRemoveCategory;
  final VoidCallback onRemoveType;
  final VoidCallback onRemoveLocation;
  final VoidCallback onRemoveAvailability;
  final VoidCallback onResetSort;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          if (filter.category != null)
            _ActiveChip(
              label: 'Category: ${filter.category!.label}',
              onDeleted: onRemoveCategory,
            ),
          if (filter.type != null && filter.type!.isNotEmpty)
            _ActiveChip(
              label: 'Type: ${filter.type == 'need' ? 'I Need' : 'I Can Help'}',
              onDeleted: onRemoveType,
            ),
          if (filter.location != null &&
              filter.location!.trim().isNotEmpty &&
              filter.location!.toLowerCase() != 'all')
            _ActiveChip(
              label: 'Location: ${filter.location}',
              onDeleted: onRemoveLocation,
            ),
          if (filter.availability != null &&
              filter.availability!.trim().isNotEmpty &&
              filter.availability!.toLowerCase() != 'any')
            _ActiveChip(
              label: 'Availability: ${filter.availability}',
              onDeleted: onRemoveAvailability,
            ),
          if (filter.sortBy != SearchSortBy.relevance)
            _ActiveChip(
              label: 'Sort: ${filter.sortBy.label}',
              onDeleted: onResetSort,
            ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: ActionChip(
              label: const Text('Clear All'),
              labelStyle: AppTextStyles.captionSmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
              backgroundColor: AppColors.errorLight,
              side: const BorderSide(color: AppColors.error),
              shape: const RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusFull,
              ),
              onPressed: onClearAll,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Chip(
        label: Text(label),
        labelStyle: AppTextStyles.captionSmall.copyWith(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
        ),
        deleteIcon: const Icon(
          Icons.close_rounded,
          size: 14,
          color: AppColors.primaryPurple,
        ),
        onDeleted: onDeleted,
        backgroundColor: AppColors.servicesBg,
        side: const BorderSide(color: AppColors.secondaryPurple, width: 0.8),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
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

/// Segmented row for switching intent: All Types, I Need, I Can Help.
class _IntentFilterRow extends StatelessWidget {
  const _IntentFilterRow({
    required this.selectedType,
    required this.onSelectType,
  });

  final String? selectedType;
  final ValueChanged<String?> onSelectType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _IntentSegment(
              label: 'All Types',
              isSelected: selectedType == null,
              onTap: () => onSelectType(null),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _IntentSegment(
              label: 'I Need',
              hasDot: true,
              dotColor: AppColors.primaryPurple,
              isSelected: selectedType == 'need',
              onTap: () => onSelectType('need'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _IntentSegment(
              label: 'I Can Help',
              hasDot: true,
              dotColor: const Color(0xFF059669),
              isSelected: selectedType == 'help',
              onTap: () => onSelectType('help'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentSegment extends StatelessWidget {
  const _IntentSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.hasDot = false,
    this.dotColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasDot;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasDot && dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.captionSmall.copyWith(
                  color: isSelected
                      ? AppColors.primaryPurple
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
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
    final isHelp = item.itemType == 'help';
    final isNeed = item.itemType == 'need';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A5B4BDB),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Creator Profile + Trust Score & Intent Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              NivaAvatar(
                                name: item.authorName ?? item.title,
                                size: 40,
                                backgroundColor: item.type.backgroundColor,
                                textColor: item.type.iconColor,
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: isHelp
                                          ? const Color(0xFF10B981)
                                          : AppColors.primaryPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.authorName ?? item.title,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: AppColors.primaryPurple,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      size: 12,
                                      color: AppColors.primaryPurple,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        '${item.trustScore ?? 96}% Trust Index',
                                        style: AppTextStyles.captionSmall
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Intent Pill on Right
                    if (isHelp)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF059669),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'I Can Help',
                              style: TextStyle(
                                color: Color(0xFF047857),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isNeed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryPurple,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'I Need',
                              style: TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.type.backgroundColor,
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: Text(
                          item.type.label,
                          style: TextStyle(
                            color: item.type.iconColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Title & Description
                Text(
                  item.title,
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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

                // Attributes Strip
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.type.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: AppColors.secondaryPurple,
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          'Available today',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.secondaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Text('•', style: TextStyle(color: AppColors.border)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item.location,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Bottom Action Buttons: View Details & Connect
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surfaceLow,
                          foregroundColor: AppColors.primaryPurple,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: onTap,
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: AppColors.textOnPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: onTap,
                        icon: Icon(
                          isNeed
                              ? Icons.handshake_outlined
                              : Icons.send_rounded,
                          size: 15,
                        ),
                        label: Text(
                          item.actionLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
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
            'Try adjusting your search terms or clearing some active filters.',
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
