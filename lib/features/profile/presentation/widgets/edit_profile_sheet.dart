import 'package:flutter/material.dart';

import 'package:niva/core/constants/app_colors.dart';
import 'package:niva/core/constants/app_spacing.dart';
import 'package:niva/core/constants/app_text_styles.dart';
import 'package:niva/core/widgets/niva_button.dart';
import 'package:niva/features/auth/data/auth_service.dart';
import 'package:niva/features/user/data/user_model.dart';
import 'package:niva/features/user/data/user_repository.dart';

/// Modal bottom sheet to edit user profile information and save to Firestore.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.user,
    this.userRepository,
    this.onProfileUpdated,
  });

  final UserModel user;
  final UserRepository? userRepository;
  final ValueChanged<UserModel>? onProfileUpdated;

  static Future<UserModel?> show(
    BuildContext context, {
    required UserModel user,
    UserRepository? userRepository,
  }) {
    return showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileSheet(
        user: user,
        userRepository: userRepository,
      ),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _cityController;
  late final TextEditingController _languageController;
  late final TextEditingController _skillsController;
  late final TextEditingController _helpController;
  late final TextEditingController _lookingForController;

  late final UserRepository _userRepo =
      widget.userRepository ?? UserRepository();

  late String _selectedAvailability;
  bool _isSaving = false;

  static const List<String> _availabilityOptions = [
    'Available',
    'Weekends only',
    'Part-time',
    'Busy / On hiatus',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _cityController = TextEditingController(text: widget.user.city);
    _languageController = TextEditingController(text: widget.user.language);
    _skillsController =
        TextEditingController(text: widget.user.skills.join(', '));
    _helpController =
        TextEditingController(text: widget.user.canHelpWith.join(', '));
    _lookingForController =
        TextEditingController(text: widget.user.lookingFor.join(', '));
    _selectedAvailability =
        _availabilityOptions.contains(widget.user.availability)
            ? widget.user.availability
            : 'Available';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _languageController.dispose();
    _skillsController.dispose();
    _helpController.dispose();
    _lookingForController.dispose();
    super.dispose();
  }

  List<String> _parseCsv(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final uid = widget.user.uid.isNotEmpty
          ? widget.user.uid
          : (AuthService.instance.currentUser?.uid ?? '');

      final updatedSkills = _parseCsv(_skillsController.text);
      final updatedHelp = _parseCsv(_helpController.text);
      final updatedLookingFor = _parseCsv(_lookingForController.text);

      final updateMap = <String, dynamic>{
        'name': name,
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'language': _languageController.text.trim().isNotEmpty
            ? _languageController.text.trim()
            : 'English',
        'skills': updatedSkills,
        'canHelpWith': updatedHelp,
        'lookingFor': updatedLookingFor,
        'availability': _selectedAvailability,
      };

      if (uid.isNotEmpty) {
        await _userRepo.updateUserProfile(uid, updateMap);
      }

      final currentAuthUser = AuthService.instance.currentUser;
      if (currentAuthUser != null && currentAuthUser.displayName != name) {
        try {
          await currentAuthUser.updateDisplayName(name);
        } catch (_) {}
      }

      final updatedModel = widget.user.copyWith(
        uid: uid.isNotEmpty ? uid : widget.user.uid,
        name: name,
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        language: _languageController.text.trim().isNotEmpty
            ? _languageController.text.trim()
            : 'English',
        skills: updatedSkills,
        canHelpWith: updatedHelp,
        lookingFor: updatedLookingFor,
        availability: _selectedAvailability,
        updatedAt: DateTime.now(),
      );

      widget.onProfileUpdated?.call(updatedModel);

      if (!mounted) return;
      Navigator.of(context).pop(updatedModel);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edit Profile', style: AppTextStyles.h2),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderSubtle),

                  // Scrollable form fields
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          // Name
                          Text(
                            'Full Name',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _nameController,
                            style: AppTextStyles.bodyMedium,
                            decoration: const InputDecoration(
                              hintText: 'Enter your display name',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Bio / About
                          Text(
                            'About / Bio',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _bioController,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 3,
                            minLines: 2,
                            decoration: const InputDecoration(
                              hintText:
                                  'Share a short intro about yourself, your interests, or what drives you...',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Location / City
                          Text(
                            'City / Location',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _cityController,
                            style: AppTextStyles.bodyMedium,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Chennai, Bengaluru, Mumbai',
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Languages
                          Text(
                            'Languages',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _languageController,
                            style: AppTextStyles.bodyMedium,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Tamil, English',
                              prefixIcon: Icon(
                                Icons.translate_rounded,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Availability
                          Text(
                            'Availability',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availabilityOptions.map((opt) {
                              final isSelected = _selectedAvailability == opt;
                              return ChoiceChip(
                                label: Text(opt),
                                selected: isSelected,
                                selectedColor: AppColors.servicesBg,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.primaryPurple
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _selectedAvailability = opt;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Skills / Capabilities
                          Text(
                            'My Skills (comma separated)',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _skillsController,
                            style: AppTextStyles.bodyMedium,
                            decoration: const InputDecoration(
                              hintText:
                                  'e.g. Flutter, React, Photography, Teaching',
                              prefixIcon: Icon(
                                Icons.psychology_outlined,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // What I can help with
                          Text(
                            'I Can Help With (comma separated)',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _helpController,
                            style: AppTextStyles.bodyMedium,
                            decoration: const InputDecoration(
                              hintText:
                                  'e.g. Mentoring, Code Review, Mobile Apps',
                              prefixIcon: Icon(
                                Icons.volunteer_activism_outlined,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // What I am looking for
                          Text(
                            'I Am Looking For (comma separated)',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _lookingForController,
                            style: AppTextStyles.bodyMedium,
                            decoration: const InputDecoration(
                              hintText:
                                  'e.g. Backend Developer, UI Designer',
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),

                  // Save Button
                  const SizedBox(height: AppSpacing.sm),
                  NivaButton(
                    label: _isSaving ? 'Saving...' : 'Save Profile',
                    isFullWidth: true,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
