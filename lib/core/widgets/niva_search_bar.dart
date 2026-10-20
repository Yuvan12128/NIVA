import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

/// Reusable NIVA search/need input bar.
/// Visually dominant entry point for universal need-to-solution discovery.
class NivaSearchBar extends StatelessWidget {
  const NivaSearchBar({
    super.key,
    this.controller,
    this.hintText = 'What do you need today?',
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onFilterTap,
    this.hasActiveFilters = false,
    this.filterCount = 0,
    this.readOnly = false,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;
  final int filterCount;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A171725),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppSpacing.borderRadiusFull,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg, right: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryPurple,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: readOnly
                      ? Text(
                          hintText,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 15.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : TextField(
                          controller: controller,
                          autofocus: autofocus,
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 15.5,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hintText: hintText,
                            hintStyle: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                ),
                // Optional Clear Button
                if (onClear != null && (controller?.text.isNotEmpty ?? false))
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                // Optional Filter Button
                if (onFilterTap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            size: 22,
                            color: hasActiveFilters
                                ? AppColors.primaryPurple
                                : AppColors.textSecondary,
                          ),
                          tooltip: 'Filter results',
                          onPressed: onFilterTap,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 38,
                            minHeight: 38,
                          ),
                        ),
                        if (hasActiveFilters)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryPurple,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                // Circular Purple Search / Discovery Action Button
                Semantics(
                  button: true,
                  label: 'Search need',
                  child: GestureDetector(
                    onTap: () {
                      if (onSubmitted != null && controller != null) {
                        onSubmitted!(controller!.text);
                      } else if (onTap != null) {
                        onTap!();
                      }
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textOnPrimary,
                        size: 22,
                      ),
                    ),
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
