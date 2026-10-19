import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/niva_button.dart';

enum _SheetStep { selectIntent, needForm, helpForm, success }

/// Modal bottom sheet presented upon tapping the central "+" action.
/// Handles the complete dual-facet flow: "I Need" and "I Can Help".
/// Engineered for Android mobile performance and Web responsive layouts (max-width capped).
class CreateNeedSheet extends StatefulWidget {
  const CreateNeedSheet({
    super.key,
    this.onNeedSelected,
    this.onHelpSelected,
    this.onNeedCreated,
    this.onHelpCreated,
  });

  final VoidCallback? onNeedSelected;
  final VoidCallback? onHelpSelected;
  final ValueChanged<String>? onNeedCreated;
  final ValueChanged<String>? onHelpCreated;

  static void show(
    BuildContext context, {
    VoidCallback? onNeedSelected,
    VoidCallback? onHelpSelected,
    ValueChanged<String>? onNeedCreated,
    ValueChanged<String>? onHelpCreated,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreateNeedSheet(
        onNeedSelected: onNeedSelected,
        onHelpSelected: onHelpSelected,
        onNeedCreated: onNeedCreated,
        onHelpCreated: onHelpCreated,
      ),
    );
  }

  @override
  State<CreateNeedSheet> createState() => _CreateNeedSheetState();
}

class _CreateNeedSheetState extends State<CreateNeedSheet> {
  _SheetStep _currentStep = _SheetStep.selectIntent;

  // I Need Form State
  final TextEditingController _needController = TextEditingController();
  final TextEditingController _needLocationController = TextEditingController();
  final TextEditingController _needBudgetController = TextEditingController();
  String? _selectedNeedCategory;
  String? _selectedNeedUrgency;
  bool _showNeedDetails = false;

  // I Can Help Form State
  final TextEditingController _helpController = TextEditingController();
  final TextEditingController _helpSkillsController = TextEditingController();
  final TextEditingController _helpLocationController = TextEditingController();
  String? _selectedHelpAvailability;
  String? _selectedHelpExperience;
  bool _showHelpDetails = false;

  // Success state message
  String _successTitle = '';
  String _successSubtitle = '';

  static const List<String> _needExamples = [
    'I need a Java tutor',
    'Looking for a photographer',
    'Need help choosing a laptop',
    'Looking for a remote frontend opportunity',
    'Want to join a React community',
  ];

  static const List<String> _helpExamples = [
    'I can teach Java',
    'I can help with React',
    'I can repair laptops',
    'I can help with photography',
    'I can mentor beginners',
  ];

  static const List<String> _categories = [
    'Education',
    'Technology',
    'Creative',
    'Hardware',
    'Career',
    'Communities',
  ];

  static const List<String> _urgencies = ['Flexible', 'This week', 'Urgent'];

  static const List<String> _availabilities = [
    'Available today',
    'Weekends',
    'Part-time',
    'Flexible',
  ];

  static const List<String> _experiences = [
    'Beginner friendly',
    'Intermediate',
    'Expert specialist',
  ];

  @override
  void dispose() {
    _needController.dispose();
    _needLocationController.dispose();
    _needBudgetController.dispose();
    _helpController.dispose();
    _helpSkillsController.dispose();
    _helpLocationController.dispose();
    super.dispose();
  }

  void _submitNeed() {
    final text = _needController.text.trim();
    if (text.isEmpty) return;

    widget.onNeedCreated?.call(text);
    setState(() {
      _successTitle = 'Need Published!';
      _successSubtitle = 'NIVA is discovering matching people, communities, opportunities, and services for your need.';
      _currentStep = _SheetStep.success;
    });
  }

  void _submitHelp() {
    final text = _helpController.text.trim();
    if (text.isEmpty) return;

    widget.onHelpCreated?.call(text);
    setState(() {
      _successTitle = 'Capability Shared!';
      _successSubtitle = 'Your capability is now discoverable across NIVA. When someone expresses a relevant need, they can discover you.';
      _currentStep = _SheetStep.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.screenHorizontal,
                right: AppSpacing.screenHorizontal,
                top: AppSpacing.md,
                bottom: bottomInset > 0
                    ? bottomInset + AppSpacing.md
                    : AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Render current step
                    switch (_currentStep) {
                      _SheetStep.selectIntent => _buildSelectIntentStep(),
                      _SheetStep.needForm => _buildNeedFormStep(),
                      _SheetStep.helpForm => _buildHelpFormStep(),
                      _SheetStep.success => _buildSuccessStep(),
                    },
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // STEP 1: Select Intent (I Need / I Can Help)
  Widget _buildSelectIntentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        const Text('What can NIVA help you with?', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose your discovery intent to get started',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Option 1: I Need
        _IntentOptionTile(
          title: 'I Need',
          subtitle: "Tell NIVA what you're looking for",
          icon: Icons.person_search_rounded,
          iconColor: AppColors.primaryPurple,
          iconBg: AppColors.servicesBg,
          onTap: () {
            widget.onNeedSelected?.call();
            setState(() {
              _currentStep = _SheetStep.needForm;
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Option 2: I Can Help
        _IntentOptionTile(
          title: 'I Can Help',
          subtitle: 'Share what you can offer',
          icon: Icons.volunteer_activism_rounded,
          iconColor: AppColors.helpIcon,
          iconBg: AppColors.helpBg,
          onTap: () {
            widget.onHelpSelected?.call();
            setState(() {
              _currentStep = _SheetStep.helpForm;
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  // STEP 2: "I Need" Form
  Widget _buildNeedFormStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Nav in Sheet
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _currentStep = _SheetStep.selectIntent;
                });
              },
              borderRadius: AppSpacing.borderRadiusFull,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: 4),
                    Text('Back', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        const Text('What do you need?', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Describe your need in plain words. NIVA discovers the right solution.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Primary Natural Language Input
        const Text(
          'What are you looking for?',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _needController,
          autofocus: true,
          maxLines: 3,
          minLines: 2,
          textInputAction: TextInputAction.done,
          style: AppTextStyles.body,
          decoration: const InputDecoration(
            hintText: 'e.g., I need a Java tutor for data structures, or Looking for a photographer...',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),

        // Example Chips for quick filling
        Text(
          'Examples:',
          style: AppTextStyles.captionSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _needExamples
              .map((example) {
                return ActionChip(
                  label: Text(example),
                  labelStyle: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                  backgroundColor: AppColors.surfaceMuted,
                  side: const BorderSide(color: AppColors.border, width: 0.8),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  onPressed: () {
                    _needController.text = example;
                    setState(() {});
                  },
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Progressive Disclosure Toggle
        InkWell(
          onTap: () {
            setState(() {
              _showNeedDetails = !_showNeedDetails;
            });
          },
          borderRadius: AppSpacing.borderRadiusSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  _showNeedDetails
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _showNeedDetails
                      ? 'Hide optional details'
                      : 'Add more details (optional)',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Optional Fields (Progressively disclosed)
        if (_showNeedDetails) ...[
          const SizedBox(height: AppSpacing.md),

          // Category Chips
          const Text('Category (optional)', style: AppTextStyles.captionSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _categories
                .map((cat) {
                  final isSelected = _selectedNeedCategory == cat;
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.servicesBg,
                    checkmarkColor: AppColors.primaryPurple,
                    labelStyle: AppTextStyles.captionSmall.copyWith(
                      color: isSelected
                          ? AppColors.primaryPurple
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    onSelected: (val) {
                      setState(() {
                        _selectedNeedCategory = val ? cat : null;
                      });
                    },
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: AppSpacing.md),

          // Location
          const Text(
            'Location / Nearby (optional)',
            style: AppTextStyles.captionSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _needLocationController,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'e.g., Chennai or Remote',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Urgency
          const Text('Urgency (optional)', style: AppTextStyles.captionSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: _urgencies
                .map((u) {
                  final isSelected = _selectedNeedUrgency == u;
                  return ChoiceChip(
                    label: Text(u),
                    selected: isSelected,
                    selectedColor: AppColors.servicesBg,
                    labelStyle: AppTextStyles.captionSmall.copyWith(
                      color: isSelected
                          ? AppColors.primaryPurple
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    onSelected: (val) {
                      setState(() {
                        _selectedNeedUrgency = val ? u : null;
                      });
                    },
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: AppSpacing.md),

          // Budget (ONLY if relevant)
          const Text(
            'Budget (only if applicable)',
            style: AppTextStyles.captionSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _needBudgetController,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: r'e.g., ₹1,000 / $50 or Flexible',
              prefixIcon: Icon(
                Icons.payments_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // CTA
        NivaButton(
          label: 'Continue',
          isFullWidth: true,
          onPressed: _needController.text.trim().isNotEmpty
              ? _submitNeed
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  // STEP 3: "I Can Help" Form
  Widget _buildHelpFormStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Nav in Sheet
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _currentStep = _SheetStep.selectIntent;
                });
              },
              borderRadius: AppSpacing.borderRadiusFull,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: 4),
                    Text('Back', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        const Text('What can you help with?', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Share your knowledge, skills, or assistance. NIVA connects you with people in need.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Primary Natural Language Offer Input
        const Text('What can you offer?', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _helpController,
          autofocus: true,
          maxLines: 3,
          minLines: 2,
          textInputAction: TextInputAction.done,
          style: AppTextStyles.body,
          decoration: const InputDecoration(
            hintText:
                'e.g., I can teach Java, help with React, or repair laptops...',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),

        // Example Chips
        Text(
          'Examples:',
          style: AppTextStyles.captionSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _helpExamples
              .map((example) {
                return ActionChip(
                  label: Text(example),
                  labelStyle: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                  backgroundColor: AppColors.surfaceMuted,
                  side: const BorderSide(color: AppColors.border, width: 0.8),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  onPressed: () {
                    _helpController.text = example;
                    setState(() {});
                  },
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Progressive Disclosure Toggle
        InkWell(
          onTap: () {
            setState(() {
              _showHelpDetails = !_showHelpDetails;
            });
          },
          borderRadius: AppSpacing.borderRadiusSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  _showHelpDetails
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.helpIcon,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _showHelpDetails
                      ? 'Hide optional details'
                      : 'Add more details (optional)',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.helpIcon,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Optional Fields (Progressively Disclosed)
        if (_showHelpDetails) ...[
          const SizedBox(height: AppSpacing.md),

          // Skills & Topics
          const Text(
            'Skills or Topics (optional)',
            style: AppTextStyles.captionSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _helpSkillsController,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'e.g., Java, Spring Boot, React, Troubleshooting',
              prefixIcon: Icon(
                Icons.psychology_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Availability
          const Text(
            'Availability (optional)',
            style: AppTextStyles.captionSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: _availabilities
                .map((a) {
                  final isSelected = _selectedHelpAvailability == a;
                  return ChoiceChip(
                    label: Text(a),
                    selected: isSelected,
                    selectedColor: AppColors.helpBg,
                    labelStyle: AppTextStyles.captionSmall.copyWith(
                      color: isSelected
                          ? AppColors.helpIcon
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    onSelected: (val) {
                      setState(() {
                        _selectedHelpAvailability = val ? a : null;
                      });
                    },
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: AppSpacing.md),

          // Location
          const Text(
            'Location / Coverage (optional)',
            style: AppTextStyles.captionSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _helpLocationController,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'e.g., Remote or Chennai',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Experience
          const Text(
            'Experience Level (optional)',
            style: AppTextStyles.captionSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: _experiences
                .map((exp) {
                  final isSelected = _selectedHelpExperience == exp;
                  return ChoiceChip(
                    label: Text(exp),
                    selected: isSelected,
                    selectedColor: AppColors.helpBg,
                    labelStyle: AppTextStyles.captionSmall.copyWith(
                      color: isSelected
                          ? AppColors.helpIcon
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    onSelected: (val) {
                      setState(() {
                        _selectedHelpExperience = val ? exp : null;
                      });
                    },
                  );
                })
                .toList(growable: false),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // CTA
        NivaButton(
          label: 'Continue',
          isFullWidth: true,
          onPressed: _helpController.text.trim().isNotEmpty
              ? _submitHelp
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  // STEP 4: Success / Confirmation Step
  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.helpBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.helpIcon,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _successTitle,
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _successSubtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14.5,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          NivaButton(
            label: 'Done',
            isFullWidth: true,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _IntentOptionTile extends StatelessWidget {
  const _IntentOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border, width: 1.2),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.subtitle.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
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
