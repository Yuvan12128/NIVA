import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/url_validator.dart';
import '../../../auth/data/auth_service.dart';
import '../../../user/data/user_model.dart';
import '../../../user/data/user_repository.dart';

/// Modal bottom sheet to edit user profile information and save to Firestore.
/// Built with an Apple-minimalist design, inline URL validation, and comprehensive fields.
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
  // Basic Information
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _cityController;
  late final TextEditingController _languageController;

  // Professional Background
  late final TextEditingController _professionController;
  late final TextEditingController _educationController;
  late final TextEditingController _experienceController;

  // Skills & Capabilities
  late final TextEditingController _skillsController;
  late final TextEditingController _helpController;
  late final TextEditingController _lookingForController;

  // Social & Professional Links
  late final TextEditingController _linkedInController;
  late final TextEditingController _githubController;
  late final TextEditingController _portfolioController;
  late final TextEditingController _otherSocialController;

  // URL Validation Errors
  String? _linkedInError;
  String? _githubError;
  String? _portfolioError;
  String? _otherSocialError;

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

    _professionController =
        TextEditingController(text: widget.user.profession);
    _educationController = TextEditingController(text: widget.user.education);
    _experienceController =
        TextEditingController(text: widget.user.experience);

    _skillsController =
        TextEditingController(text: widget.user.skills.join(', '));
    _helpController =
        TextEditingController(text: widget.user.canHelpWith.join(', '));
    _lookingForController =
        TextEditingController(text: widget.user.lookingFor.join(', '));

    _linkedInController =
        TextEditingController(text: widget.user.linkedInUrl);
    _githubController = TextEditingController(text: widget.user.githubUrl);
    _portfolioController =
        TextEditingController(text: widget.user.portfolioUrl);
    _otherSocialController =
        TextEditingController(text: widget.user.otherSocialUrl);

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
    _professionController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    _helpController.dispose();
    _lookingForController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    _otherSocialController.dispose();
    super.dispose();
  }

  List<String> _parseCsv(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool _validateFormUrls() {
    final linkedInErr = UrlValidator.validateUrl(
      _linkedInController.text,
      platform: 'LinkedIn',
    );
    final githubErr = UrlValidator.validateUrl(
      _githubController.text,
      platform: 'GitHub',
    );
    final portfolioErr = UrlValidator.validateUrl(_portfolioController.text);
    final otherErr = UrlValidator.validateUrl(_otherSocialController.text);

    setState(() {
      _linkedInError = linkedInErr;
      _githubError = githubErr;
      _portfolioError = portfolioErr;
      _otherSocialError = otherErr;
    });

    return linkedInErr == null &&
        githubErr == null &&
        portfolioErr == null &&
        otherErr == null;
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

    if (!_validateFormUrls()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the invalid URL format(s).'),
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

      final cleanLinkedIn = UrlValidator.normalize(_linkedInController.text);
      final cleanGithub = UrlValidator.normalize(_githubController.text);
      final cleanPortfolio =
          UrlValidator.normalize(_portfolioController.text);
      final cleanOtherSocial =
          UrlValidator.normalize(_otherSocialController.text);

      final updateMap = <String, dynamic>{
        'name': name,
        'bio': _bioController.text.trim(),
        'profession': _professionController.text.trim(),
        'education': _educationController.text.trim(),
        'experience': _experienceController.text.trim(),
        'city': _cityController.text.trim(),
        'language': _languageController.text.trim().isNotEmpty
            ? _languageController.text.trim()
            : 'English',
        'skills': updatedSkills,
        'canHelpWith': updatedHelp,
        'lookingFor': updatedLookingFor,
        'linkedInUrl': cleanLinkedIn,
        'githubUrl': cleanGithub,
        'portfolioUrl': cleanPortfolio,
        'otherSocialUrl': cleanOtherSocial,
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
        profession: _professionController.text.trim(),
        education: _educationController.text.trim(),
        experience: _experienceController.text.trim(),
        city: _cityController.text.trim(),
        language: _languageController.text.trim().isNotEmpty
            ? _languageController.text.trim()
            : 'English',
        skills: updatedSkills,
        canHelpWith: updatedHelp,
        lookingFor: updatedLookingFor,
        linkedInUrl: cleanLinkedIn,
        githubUrl: cleanGithub,
        portfolioUrl: cleanPortfolio,
        otherSocialUrl: cleanOtherSocial,
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
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
          decoration: const BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
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
                  // Apple Drag Handle
                  Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: AppColors.appleBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: AppColors.appleTextPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.appleTextSecondary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.appleBorder, height: 1),

                  // Scrollable form fields
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.md),

                          // SECTION: BASIC INFORMATION
                          _buildSectionHeader('Basic Information'),
                          const SizedBox(height: AppSpacing.sm),

                          // Name
                          _buildLabel('Full Name *'),
                          TextField(
                            controller: _nameController,
                            style: AppTextStyles.bodyMedium,
                            decoration: _buildInputDecoration(
                              hintText: 'Your display name',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Profession / Headline
                          _buildLabel('Profession / Headline'),
                          TextField(
                            controller: _professionController,
                            style: AppTextStyles.bodyMedium,
                            decoration: _buildInputDecoration(
                              hintText: 'e.g. Software Architect, Product Designer',
                              prefixIcon: Icons.work_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Bio
                          _buildLabel('Bio / Summary'),
                          TextField(
                            controller: _bioController,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 3,
                            minLines: 2,
                            decoration: _buildInputDecoration(
                              hintText:
                                  'A brief summary of your work, interests, and background...',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // SECTION: PROFESSIONAL BACKGROUND
                          _buildSectionHeader('Professional Background'),
                          const SizedBox(height: AppSpacing.sm),

                          // Education
                          _buildLabel('Education'),
                          TextField(
                            controller: _educationController,
                            style: AppTextStyles.bodyMedium,
                            decoration: _buildInputDecoration(
                              hintText:
                                  'e.g. B.Tech in CS, Anna University',
                              prefixIcon: Icons.school_outlined,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Experience
                          _buildLabel('Experience'),
                          TextField(
                            controller: _experienceController,
                            style: AppTextStyles.bodyMedium,
                            decoration: _buildInputDecoration(
                              hintText:
                                  'e.g. 4+ years in Mobile & Cloud Architecture',
                              prefixIcon: Icons.timeline_rounded,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Location
                          _buildLabel('City / Location'),
                          TextField(
                            controller: _cityController,
                            style: AppTextStyles.bodyMedium,
                            decoration: _buildInputDecoration(
                              hintText: 'e.g. Chennai, Bengaluru, Remote',
                              prefixIcon: Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // SECTION: SKILLS & AVAILABILITY
                          _buildSectionHeader('Skills & Capabilities'),
                          const SizedBox(height: AppSpacing.sm),

                          _buildLabel('Skills (comma separated)'),
                          TextField(
                            controller: _skillsController,
                            style: AppTextStyles.bodyMedium,
                            decoration: _buildInputDecoration(
                              hintText: 'e.g. Flutter, Firebase, Python, UI Design',
                              prefixIcon: Icons.psychology_outlined,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          _buildLabel('I Can Help With (comma separated)'),
                          TextField(
                            controller: _helpController,
                            style: AppTextStyles.bodyMedium,
                            decoration: _buildInputDecoration(
                              hintText:
                                  'e.g. Mentoring, Architecture Review, Debugging',
                              prefixIcon: Icons.volunteer_activism_outlined,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          _buildLabel('I Am Looking For (comma separated)'),
                          TextField(
                            controller: _lookingForController,
                            style: AppTextStyles.bodyMedium,
                            decoration: _buildInputDecoration(
                              hintText: 'e.g. Cloud Engineers, Startup Mentors',
                              prefixIcon: Icons.search_rounded,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          _buildLabel('Availability'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availabilityOptions.map((opt) {
                              final isSelected = _selectedAvailability == opt;
                              return ChoiceChip(
                                label: Text(opt),
                                selected: isSelected,
                                selectedColor: AppColors.appleBlueSubtle,
                                backgroundColor: AppColors.appleSecondaryBg,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.appleBlue
                                      : AppColors.appleTextPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.appleBlue
                                      : AppColors.appleBorder,
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
                          const SizedBox(height: AppSpacing.lg),

                          // SECTION: SOCIAL & PROFESSIONAL LINKS
                          _buildSectionHeader('Professional & Social Links'),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'All links are optional and verified before opening.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.appleTextSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // LinkedIn
                          _buildLabel('LinkedIn Profile URL'),
                          TextField(
                            controller: _linkedInController,
                            style: AppTextStyles.bodyMedium,
                            keyboardType: TextInputType.url,
                            decoration: _buildInputDecoration(
                              hintText: 'https://linkedin.com/in/username',
                              prefixIcon: Icons.link_rounded,
                              errorText: _linkedInError,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // GitHub
                          _buildLabel('GitHub Profile URL'),
                          TextField(
                            controller: _githubController,
                            style: AppTextStyles.bodyMedium,
                            keyboardType: TextInputType.url,
                            decoration: _buildInputDecoration(
                              hintText: 'https://github.com/username',
                              prefixIcon: Icons.code_rounded,
                              errorText: _githubError,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Portfolio
                          _buildLabel('Portfolio Website URL'),
                          TextField(
                            controller: _portfolioController,
                            style: AppTextStyles.bodyMedium,
                            keyboardType: TextInputType.url,
                            decoration: _buildInputDecoration(
                              hintText: 'https://yourportfolio.com',
                              prefixIcon: Icons.language_rounded,
                              errorText: _portfolioError,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Other Social
                          _buildLabel('Other Social Link (X, Substack, etc.)'),
                          TextField(
                            controller: _otherSocialController,
                            style: AppTextStyles.bodyMedium,
                            keyboardType: TextInputType.url,
                            decoration: _buildInputDecoration(
                              hintText: 'https://x.com/username',
                              prefixIcon: Icons.public_rounded,
                              errorText: _otherSocialError,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),

                  // Save Action Button
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appleBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.appleTextPrimary,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.appleTextSecondary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.appleTextTertiary,
      ),
      errorText: errorText,
      errorMaxLines: 2,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.appleTextSecondary, size: 20)
          : null,
      filled: true,
      fillColor: AppColors.appleSecondaryBg,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.appleBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.appleBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.appleBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1),
      ),
    );
  }
}
