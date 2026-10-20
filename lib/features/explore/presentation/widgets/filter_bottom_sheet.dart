import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/discovery_model.dart';
import '../../data/search_filter_model.dart';

/// Modal bottom sheet allowing users to filter discovery items by:
/// - Category (People, Services, Information, Opportunities, Communities)
/// - Type (I Need, I Can Help, All)
/// - Location (Remote, Chennai, Bengaluru, or custom)
/// - Availability (Any, Available today, Weekends, Flexible)
/// - Sort order (Relevance, Recent)
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  final SearchFilter initialFilter;
  final ValueChanged<SearchFilter> onApply;

  static void show(
    BuildContext context, {
    required SearchFilter currentFilter,
    required ValueChanged<SearchFilter> onApply,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          FilterBottomSheet(initialFilter: currentFilter, onApply: onApply),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late DiscoveryType? _selectedCategory;
  late String? _selectedType;
  late String _location;
  late String? _selectedAvailability;
  late SearchSortBy _sortBy;
  late final TextEditingController _customLocationController;

  static const List<String> _quickLocations = [
    'All',
    'Remote',
    'Chennai',
    'Bengaluru',
  ];

  static const List<String> _availabilities = [
    'Any',
    'Available today',
    'Weekends',
    'Flexible',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialFilter.category;
    _selectedType = widget.initialFilter.type;
    _location = widget.initialFilter.location ?? 'All';
    _selectedAvailability = widget.initialFilter.availability ?? 'Any';
    _sortBy = widget.initialFilter.sortBy;

    final isPresetLocation = _quickLocations.any(
      (l) => l.toLowerCase() == _location.toLowerCase(),
    );
    _customLocationController = TextEditingController(
      text: isPresetLocation ? '' : _location,
    );
  }

  @override
  void dispose() {
    _customLocationController.dispose();
    super.dispose();
  }

  int get _activeCount {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedType != null && _selectedType != 'All') count++;
    if (_location != 'All' || _customLocationController.text.trim().isNotEmpty) {
      count++;
    }
    if (_selectedAvailability != null && _selectedAvailability != 'Any') {
      count++;
    }
    if (_sortBy != SearchSortBy.relevance) count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedType = null;
      _location = 'All';
      _selectedAvailability = 'Any';
      _sortBy = SearchSortBy.relevance;
      _customLocationController.clear();
    });
  }

  void _applyFilters() {
    final customLoc = _customLocationController.text.trim();
    final effectiveLocation = customLoc.isNotEmpty
        ? customLoc
        : (_location == 'All' ? null : _location);

    final updatedFilter = SearchFilter(
      category: _selectedCategory,
      type: _selectedType == 'All' ? null : _selectedType,
      location: effectiveLocation,
      availability: _selectedAvailability == 'Any'
          ? null
          : _selectedAvailability,
      sortBy: _sortBy,
    );

    widget.onApply(updatedFilter);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Search Filters',
                            style: AppTextStyles.h2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_activeCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '$_activeCount active',
                              style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: Text(
                      'Reset All',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),

            // Filter controls scroll view
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Listing Type (Stitch Segmented Bar)
                    const Text('Listing Type', style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTypeSegment(
                              label: 'All',
                              isSelected: _selectedType == null ||
                                  _selectedType == 'All',
                              onTap: () => setState(() => _selectedType = null),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildTypeSegment(
                              label: 'I Need',
                              isSelected: _selectedType == 'need',
                              onTap: () =>
                                  setState(() => _selectedType = 'need'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildTypeSegment(
                              label: 'I Can Help',
                              isSelected: _selectedType == 'help',
                              onTap: () =>
                                  setState(() => _selectedType = 'help'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 2. Category Filter
                    const Text('Category', style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildChip(
                          label: 'All Categories',
                          isSelected: _selectedCategory == null,
                          onTap: () => setState(() => _selectedCategory = null),
                        ),
                        ...DiscoveryType.values.map((type) {
                          return _buildChip(
                            label: type.label,
                            isSelected: _selectedCategory == type,
                            onTap: () =>
                                setState(() => _selectedCategory = type),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 3. Location Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Location', style: AppTextStyles.subtitle),
                        Text(
                          _location == 'All' ? 'Anywhere' : _location,
                          style: const TextStyle(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _quickLocations
                          .map((loc) {
                            final isSelected =
                                _customLocationController.text.trim().isEmpty &&
                                _location.toLowerCase() == loc.toLowerCase();
                            return _buildChip(
                              label: loc,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _location = loc;
                                  _customLocationController.clear();
                                });
                              },
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _customLocationController,
                      onChanged: (val) {
                        setState(() {
                          _location = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Or enter specific city...',
                        hintStyle: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        prefixIcon: const Icon(
                          Icons.location_city_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                          borderSide: const BorderSide(
                            color: AppColors.primaryPurple,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 4. Availability Filter
                    const Text('Availability', style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _availabilities
                          .map((avail) {
                            final isSelected =
                                _selectedAvailability?.toLowerCase() ==
                                avail.toLowerCase();
                            return _buildChip(
                              label: avail,
                              isSelected: isSelected,
                              hasIcon: avail == 'Available today',
                              icon: Icons.bolt_rounded,
                              onTap: () {
                                setState(() {
                                  _selectedAvailability = avail;
                                });
                              },
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 5. Sort By
                    const Text('Sort By', style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: SearchSortBy.values
                          .map((sort) {
                            final isSelected = _sortBy == sort;
                            return _buildChip(
                              label: sort.label,
                              isSelected: isSelected,
                              onTap: () => setState(() => _sortBy = sort),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons Footer
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLow,
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.captionSmall.copyWith(
              color: isSelected
                  ? AppColors.primaryPurple
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasIcon = false,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.surfaceLow,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIcon && icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.secondaryPurple,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.captionSmall.copyWith(
                color:
                    isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
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
