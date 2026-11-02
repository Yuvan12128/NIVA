import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/url_validator.dart';
import '../../../core/widgets/niva_avatar.dart';
import '../../../core/widgets/niva_button.dart';
import '../../auth/data/auth_service.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/presentation/conversation_screen.dart';
import '../../connect/data/connection_request_model.dart';
import '../../connect/data/connection_request_repository.dart';
import '../../safety/data/safety_repository.dart';
import '../../safety/presentation/widgets/report_sheet.dart';
import '../../user/data/user_model.dart';
import '../../user/data/user_repository.dart';
import 'widgets/edit_profile_sheet.dart';

/// User Profile Screen for NIVA.
/// Built around Apple minimal aesthetics (white & blue) and dual identity discovery:
/// 1. "What does this person need?"
/// 2. "What can this person help with?"
/// Features personal professional identity: Photo, Name, Private Gmail, Bio,
/// Profession, Education, Experience, Skills, and validated Social Links.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.targetUserId,
    this.targetUserName,
    this.initialProfile,
    this.isOwnProfileOverride,
    this.safetyRepository,
    this.userRepository,
    this.connectionRequestRepository,
    this.chatRepository,
    this.currentUserId,
  });

  final String? targetUserId;
  final String? targetUserName;
  final UserModel? initialProfile;
  final bool? isOwnProfileOverride;
  final SafetyRepository? safetyRepository;
  final UserRepository? userRepository;
  final ConnectionRequestRepository? connectionRequestRepository;
  final ChatRepository? chatRepository;
  final String? currentUserId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserRepository _userRepo =
      widget.userRepository ?? UserRepository();
  late final ConnectionRequestRepository _connectionRepo =
      widget.connectionRequestRepository ?? ConnectionRequestRepository();
  late final ChatRepository _chatRepo =
      widget.chatRepository ?? ChatRepository();
  late final SafetyRepository _safetyRepo =
      widget.safetyRepository ?? SafetyRepository();

  UserModel? _userProfile;
  ConnectionRequestModel? _connectionRequest;
  bool _isBlocked = false;

  static const List<String> _defaultActiveNeeds = [
    'Looking for a Java & distributed systems mentor',
    'Looking for a photographer for local tech meetup',
    'Looking for a React & Flutter contributor community',
  ];

  static const List<String> _defaultHelpCapabilities = [
    'Java',
    'React',
    'Flutter',
    'Laptop repair',
    'Mentoring beginners',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _userProfile = widget.initialProfile;
    }
    _loadProfile();
    _loadConnectionStatus();
  }

  Future<void> _loadConnectionStatus() async {
    final currentUid =
        widget.currentUserId ?? AuthService.instance.currentUser?.uid;
    final targetUid = widget.targetUserId ?? _userProfile?.uid;
    if (currentUid == null ||
        currentUid.isEmpty ||
        targetUid == null ||
        targetUid.isEmpty ||
        currentUid == targetUid) {
      return;
    }

    try {
      final blocked = await _safetyRepo.isBlocked(
        userA: currentUid,
        userB: targetUid,
      );
      final req = await _connectionRepo.getConnectionRequestBetween(
        userA: currentUid,
        userB: targetUid,
      );
      if (mounted) {
        setState(() {
          _isBlocked = blocked;
          _connectionRequest = req;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    final uid = widget.targetUserId ?? AuthService.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        final profile = await _userRepo.getUserProfile(uid);
        if (mounted && profile != null) {
          String email = profile.email;
          if (email.isEmpty &&
              (widget.targetUserId == null ||
                  widget.targetUserId ==
                      AuthService.instance.currentUser?.uid)) {
            email = AuthService.instance.currentUser?.email ?? '';
            if (email.isEmpty) {
              final privateEmail = await _userRepo.getUserPrivateEmail(uid);
              if (privateEmail != null) email = privateEmail;
            }
          }
          setState(() {
            _userProfile = profile.copyWith(email: email);
          });
        }
      } catch (e) {
        debugPrint('ProfileScreen._loadProfile notice: $e');
      }
    }
  }

  Future<void> _openEditProfile() async {
    final currentUser = AuthService.instance.currentUser;
    final isGuestOrTest = currentUser == null && widget.targetUserId == null;
    final fallbackName = currentUser?.displayName?.isNotEmpty == true
        ? currentUser!.displayName!
        : (currentUser?.email?.isNotEmpty == true
              ? currentUser!.email!.split('@').first
              : 'Arun Kumar');

    final baseUser =
        _userProfile ??
        UserModel(
          uid: currentUser?.uid ?? '',
          name: fallbackName,
          email: currentUser?.email ?? '',
          photoUrl: currentUser?.photoURL,
          bio:
              isGuestOrTest
                  ? 'Building accessible tools, collaborating on needs, and connecting with community peers across NIVA.'
                  : '',
          city: isGuestOrTest ? 'Chennai' : '',
          language: isGuestOrTest ? 'English, Tamil' : 'English',
          skills: isGuestOrTest ? _defaultHelpCapabilities : const [],
          canHelpWith: isGuestOrTest ? _defaultHelpCapabilities : const [],
          lookingFor: isGuestOrTest ? _defaultActiveNeeds : const [],
          availability: 'Available',
        );

    final updated = await EditProfileSheet.show(
      context,
      user: baseUser,
      userRepository: _userRepo,
    );

    if (updated != null && mounted) {
      setState(() {
        _userProfile = updated;
      });
    }
  }

  Future<void> _launchSocialUrl(String rawUrl) async {
    final cleanUrl = UrlValidator.normalize(rawUrl);
    if (cleanUrl.isEmpty) return;

    try {
      final uri = Uri.parse(cleanUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showFeedback('Could not open $cleanUrl');
      }
    } catch (e) {
      _showFeedback('Invalid link: $cleanUrl');
    }
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final isGuestOrTest = currentUser == null && widget.targetUserId == null;
    final isOwnProfile = widget.isOwnProfileOverride ??
        (widget.targetUserId == null || widget.targetUserId == currentUser?.uid);

    final fallbackName =
        currentUser?.displayName?.isNotEmpty == true
            ? currentUser!.displayName!
            : (currentUser?.email != null
                ? currentUser!.email!.split('@').first
                : 'Arun Kumar');

    final displayName =
        _userProfile?.name.isNotEmpty == true
            ? _userProfile!.name
            : (widget.targetUserName ?? fallbackName);

    final photoUrl =
        _userProfile?.photoUrl?.isNotEmpty == true
            ? _userProfile!.photoUrl
            : (isOwnProfile ? currentUser?.photoURL : null);

    final profession = _userProfile?.profession ?? '';
    final education = _userProfile?.education ?? '';
    final experience = _userProfile?.experience ?? '';

    final displayEmail =
        _userProfile?.email.isNotEmpty == true
            ? _userProfile!.email
            : (isOwnProfile ? (currentUser?.email ?? '') : '');

    final city =
        _userProfile?.city.isNotEmpty == true
            ? _userProfile!.city
            : (isGuestOrTest ? 'Chennai (Remote flexible)' : 'Location not set');

    final language =
        _userProfile?.language.isNotEmpty == true
            ? _userProfile!.language
            : (isGuestOrTest ? 'English, Tamil' : 'English');

    final availability =
        _userProfile?.availability.isNotEmpty == true
            ? _userProfile!.availability
            : 'Available for discovery';

    final activeNeeds =
        _userProfile?.lookingFor.isNotEmpty == true
            ? _userProfile!.lookingFor
            : (isGuestOrTest ? _defaultActiveNeeds : const <String>[]);

    final helpCapabilities =
        _userProfile?.canHelpWith.isNotEmpty == true
            ? _userProfile!.canHelpWith
            : (_userProfile?.skills.isNotEmpty == true
                ? _userProfile!.skills
                : (isGuestOrTest ? _defaultHelpCapabilities : const <String>[]));

    final skills =
        _userProfile?.skills.isNotEmpty == true
            ? _userProfile!.skills
            : const <String>[];

    final bioText =
        _userProfile?.bio.isNotEmpty == true
            ? _userProfile!.bio
            : (isGuestOrTest
                ? 'Building accessible tools, collaborating on needs, and connecting with community peers across NIVA.'
                : 'No bio added yet. Tap Edit Profile to introduce yourself to the community.');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile', style: AppTextStyles.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _showFeedback('Opening Settings...'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header (Photo, Name, Profession, Private Gmail, Social Links, Bio)
                  _buildHeader(
                    context,
                    displayName: displayName,
                    photoUrl: photoUrl,
                    profession: profession,
                    displayEmail: displayEmail,
                    city: city,
                    language: language,
                    bio: bioText,
                    hasCustomBio:
                        _userProfile?.bio.isNotEmpty == true || isGuestOrTest,
                    isOwnProfile: isOwnProfile,
                    linkedInUrl: _userProfile?.linkedInUrl ?? '',
                    githubUrl: _userProfile?.githubUrl ?? '',
                    portfolioUrl: _userProfile?.portfolioUrl ?? '',
                    otherSocialUrl: _userProfile?.otherSocialUrl ?? '',
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 2. Professional Background (Education & Experience)
                  if (education.isNotEmpty || experience.isNotEmpty) ...[
                    _buildProfessionalSection(
                      education: education,
                      experience: experience,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // 3. Skills & Expertise (if distinct and populated)
                  if (skills.isNotEmpty) ...[
                    _buildSkillsSection(skills: skills),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // 4. Trust Indicators (Non-vanity)
                  _buildTrustSection(),
                  const SizedBox(height: AppSpacing.xl),

                  // 5. Availability
                  _buildAvailabilitySection(availability: availability),
                  const SizedBox(height: AppSpacing.xl),

                  // 6. I Need (Active Needs)
                  _buildNeedsSection(context, activeNeeds: activeNeeds),
                  const SizedBox(height: AppSpacing.xl),

                  // 7. I Can Help (Capabilities)
                  _buildHelpSection(context, capabilities: helpCapabilities),
                  const SizedBox(height: AppSpacing.xl),

                  // 8. Profile Actions
                  _buildActionsSection(context, isOwnProfile: isOwnProfile),
                  _buildSafetyActions(context, isOwnProfile: isOwnProfile),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. HEADER
  Widget _buildHeader(
    BuildContext context, {
    required String displayName,
    required String? photoUrl,
    required String profession,
    required String displayEmail,
    required String city,
    required String language,
    required String bio,
    required bool hasCustomBio,
    required bool isOwnProfile,
    required String linkedInUrl,
    required String githubUrl,
    required String portfolioUrl,
    required String otherSocialUrl,
  }) {
    final hasSocialLinks =
        linkedInUrl.isNotEmpty ||
        githubUrl.isNotEmpty ||
        portfolioUrl.isNotEmpty ||
        otherSocialUrl.isNotEmpty;

    final isCanHelp = _userProfile?.canHelpWith.isNotEmpty == true ||
        (_userProfile?.skills.isNotEmpty == true &&
            _userProfile?.lookingFor.isEmpty == true);

    String subtitle = '';
    if (_userProfile?.skills.isNotEmpty == true) {
      subtitle = _userProfile!.skills.take(3).join(' • ');
    } else if (profession.isNotEmpty) {
      subtitle = profession;
    } else {
      subtitle = 'Java • Spring Boot • Projects';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.appleBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Soft blue gradient wash behind avatar (Reference Screen 8)
          Container(
            height: 90,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE4F0FF), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Centered Circular Avatar
          Transform.translate(
            offset: const Offset(0, -44),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: NivaAvatar(
                  name: displayName,
                  imageUrl: photoUrl,
                  size: 82,
                  isVerified: true,
                  backgroundColor: AppColors.appleBlueSubtle,
                  textColor: AppColors.appleBlue,
                ),
              ),
            ),
          ),

          // Name, Badge & Subtitle
          Transform.translate(
            offset: const Offset(0, -32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppColors.appleTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.appleBlue,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Centered Status Badge (Screen 8)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isCanHelp ? AppColors.badgeGreenBg : AppColors.badgeBlueBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      isCanHelp ? 'Can Help' : 'Need Help',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCanHelp ? AppColors.badgeGreenText : AppColors.badgeBlueText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Centered Subtitle / Skills
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13.5,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (profession.isNotEmpty && profession != subtitle) ...[
                    const SizedBox(height: 2),
                    Text(
                      profession,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.appleBlue,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  if (isOwnProfile && displayEmail.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.appleSecondaryBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.appleBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              displayEmail,
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Private',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              city,
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.translate_rounded,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              language,
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1, color: AppColors.appleBorder),
                  const SizedBox(height: AppSpacing.md),

                  // "About" Section (Screen 8)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'About',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.appleTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      bio,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: AppColors.appleTextPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),

                  if (hasSocialLinks) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (linkedInUrl.isNotEmpty)
                          _buildSocialPill(
                            icon: Icons.business_center_outlined,
                            label: 'LinkedIn',
                            url: linkedInUrl,
                            accentColor: const Color(0xFF0077B5),
                          ),
                        if (githubUrl.isNotEmpty)
                          _buildSocialPill(
                            icon: Icons.code_rounded,
                            label: 'GitHub',
                            url: githubUrl,
                            accentColor: const Color(0xFF24292E),
                          ),
                        if (portfolioUrl.isNotEmpty)
                          _buildSocialPill(
                            icon: Icons.language_rounded,
                            label: 'Portfolio',
                            url: portfolioUrl,
                            accentColor: AppColors.appleBlue,
                          ),
                        if (otherSocialUrl.isNotEmpty)
                          _buildSocialPill(
                            icon: Icons.link_rounded,
                            label: 'Website',
                            url: otherSocialUrl,
                            accentColor: AppColors.primaryPurple,
                          ),
                      ],
                    ),
                  ],

                  if (isOwnProfile) ...[
                    const SizedBox(height: AppSpacing.lg),
                    NivaButton(
                      label: 'Edit Profile',
                      variant: NivaButtonVariant.secondary,
                      isFullWidth: true,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: _openEditProfile,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialPill({
    required IconData icon,
    required String label,
    required String url,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: () => _launchSocialUrl(url),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.appleSecondaryBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.arrow_outward_rounded,
              size: 11,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  // 2. PROFESSIONAL BACKGROUND (Education & Experience)
  Widget _buildProfessionalSection({
    required String education,
    required String experience,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Professional Background', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Column(
            children: [
              if (experience.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.appleBlue.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: const Icon(
                        Icons.work_outline_rounded,
                        color: AppColors.appleBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Experience',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            experience,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (education.isNotEmpty)
                  const Divider(height: 24, thickness: 0.8),
              ],
              if (education.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: AppColors.primaryPurple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Education',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            education,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. SKILLS & EXPERTISE
  Widget _buildSkillsSection({required List<String> skills}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Skills & Expertise', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children:
              skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    skill,
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  // 4. TRUST SECTION (Useful trust indicators only)
  Widget _buildTrustSection() {
    final trustScore = _userProfile?.trustScore ?? 100;
    final completedConnections = _userProfile?.completedConnections ?? 0;
    final helpfulInteractions = _userProfile?.helpfulInteractions ?? 0;
    final reviewCount = _userProfile?.reviewCount ?? 0;
    final rating = _userProfile?.rating ?? 5.0;

    final reviewLabel =
        reviewCount == 0
            ? 'No reviews yet'
            : '$reviewCount verified ${reviewCount == 1 ? 'review' : 'reviews'}';
    final ratingText = reviewCount == 0 ? '5.0' : rating.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Trust & Verification', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _TrustMetricCard(
                icon: Icons.handshake_outlined,
                iconColor: AppColors.primaryPurple,
                iconBg: AppColors.servicesBg,
                value: '$completedConnections',
                label: 'Completed connections',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TrustMetricCard(
                icon: Icons.volunteer_activism_outlined,
                iconColor: AppColors.helpIcon,
                iconBg: AppColors.helpBg,
                value: '$helpfulInteractions',
                label: 'Helpful interactions',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _TrustMetricCard(
                icon: Icons.star_rounded,
                iconColor: Colors.amber.shade700,
                iconBg: AppColors.warningLight,
                value: ratingText,
                label: reviewLabel,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TrustMetricCard(
                icon: Icons.verified_user_outlined,
                iconColor: AppColors.appleBlue,
                iconBg: AppColors.infoBg,
                value: '$trustScore Trust',
                label: 'Community score',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 5. AVAILABILITY
  Widget _buildAvailabilitySection({required String availability}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.helpBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.helpIcon,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        availability,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Active this week • Verified Community Member',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Open for: Remote guidance & local community discussions',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. I NEED (Active Needs)
  Widget _buildNeedsSection(
    BuildContext context, {
    required List<String> activeNeeds,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('I Need', style: AppTextStyles.subtitle),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: const BoxDecoration(
                color: AppColors.servicesBg,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
              child: Text(
                '${activeNeeds.length} active',
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (activeNeeds.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: Text(
              'No active needs listed yet. Tap Edit Profile to add what you are looking for.',
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...activeNeeds.map((need) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(color: AppColors.borderSubtle, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.servicesBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_search_rounded,
                        color: AppColors.primaryPurple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        need,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // 7. I CAN HELP (Capabilities)
  Widget _buildHelpSection(
    BuildContext context, {
    required List<String> capabilities,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'I Can Help With',
                style: AppTextStyles.subtitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: const BoxDecoration(
                color: AppColors.helpBg,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
              child: Text(
                '${capabilities.length} capabilities',
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.helpIcon,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (capabilities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: Text(
              'No capabilities listed yet. Tap Edit Profile to add what you can help with.',
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children:
                capabilities.map((capability) {
                  return Container(
                    constraints: const BoxConstraints(maxWidth: 260),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.helpBg,
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(
                        color: AppColors.helpIcon.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: AppColors.helpIcon,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            capability,
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }

  Future<void> _sendConnectionRequestToPeer({
    required String currentUid,
    required String targetUid,
    required String targetName,
  }) async {
    if (currentUid.isEmpty) {
      _showFeedback('Please sign in to send connection requests.');
      return;
    }
    if (currentUid == targetUid) {
      _showFeedback('You cannot send a connection request to yourself.');
      return;
    }

    try {
      final reqId = await _connectionRepo.sendConnectRequest(
        fromUserId: currentUid,
        toUserId: targetUid,
        needId: 'direct_connection',
        fromUserName: AuthService.instance.currentUser?.displayName,
        toUserName: targetName,
      );

      setState(() {
        _connectionRequest = ConnectionRequestModel(
          id: reqId,
          fromUserId: currentUid,
          toUserId: targetUid,
          needId: 'direct_connection',
          status: 'pending',
          toUserName: targetName,
        );
      });

      _showFeedback('Connection request sent to $targetName.');
    } catch (e) {
      _showFeedback('Failed to send request: $e');
    }
  }

  Future<void> _respondToPeerRequest(
    ConnectionRequestModel req,
    String status,
  ) async {
    final currentUid =
        widget.currentUserId ?? AuthService.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) return;

    try {
      await _connectionRepo.respondToRequest(
        requestId: req.id,
        responderUserId: currentUid,
        status: status,
      );

      setState(() {
        _connectionRequest = req.copyWith(status: status);
      });

      _showFeedback(
        status == 'accepted'
            ? 'Connection accepted! You can now chat.'
            : 'Connection request declined.',
      );
    } catch (e) {
      _showFeedback('Action failed: $e');
    }
  }

  Future<void> _openChatWithPeer({
    required String currentUid,
    required String targetUid,
    required String targetName,
    String? targetPhoto,
    required String connectionRequestId,
  }) async {
    if (currentUid.isEmpty) return;

    try {
      final chat = await _chatRepo.getOrCreateChat(
        connectionRequestId: connectionRequestId,
        needId: 'direct_connection',
        user1: currentUid,
        user2: targetUid,
        participantNames: {targetUid: targetName},
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ConversationScreen(
                chat: chat,
                otherUserName: targetName,
                otherUserId: targetUid,
                otherUserPhotoUrl: targetPhoto,
                currentUserId: currentUid,
                chatRepository: _chatRepo,
              ),
        ),
      ).then((_) => _loadConnectionStatus());
    } catch (e) {
      _showFeedback('Could not open conversation: $e');
    }
  }

  // 8. PROFILE ACTIONS
  Widget _buildActionsSection(
    BuildContext context, {
    required bool isOwnProfile,
  }) {
    if (isOwnProfile) {
      return const SizedBox.shrink();
    }

    final currentUid =
        widget.currentUserId ?? AuthService.instance.currentUser?.uid ?? '';
    final targetUid = widget.targetUserId ?? _userProfile?.uid ?? '';
    final targetName = widget.targetUserName ?? _userProfile?.name ?? 'Peer';
    final targetPhoto = _userProfile?.photoUrl;
    final req = _connectionRequest;

    if (_isBlocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.appleSecondaryBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_rounded, size: 16, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'User Blocked',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // 1. If connection request is already accepted:
    if (req != null && req.status == 'accepted') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Color(0xFF2E7D32),
                ),
                SizedBox(width: 6),
                Text(
                  'Connected',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          NivaButton(
            label: 'Direct Message',
            isFullWidth: true,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            onPressed:
                () => _openChatWithPeer(
                  currentUid: currentUid,
                  targetUid: targetUid,
                  targetName: targetName,
                  targetPhoto: targetPhoto,
                  connectionRequestId: req.id,
                ),
          ),
        ],
      );
    }

    // 2. If incoming request from targetUser is pending:
    if (req != null && req.status == 'pending' && req.toUserId == currentUid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.appleSecondaryBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.appleBorder),
            ),
            child: Column(
              children: [
                Text(
                  '$targetName sent you a connection request.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appleBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _respondToPeerRequest(req, 'accepted'),
                        child: const Text('Accept Request'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.appleBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _respondToPeerRequest(req, 'declined'),
                        child: const Text('Decline'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          NivaButton(
            label: 'Direct Message',
            variant: NivaButtonVariant.secondary,
            isFullWidth: true,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            onPressed:
                () => _showFeedback(
                  'Messaging is available after accepting the connection request.',
                ),
          ),
        ],
      );
    }

    // 3. If sent request is pending:
    if (req != null &&
        req.status == 'pending' &&
        req.fromUserId == currentUid) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.appleBlue,
              ),
              label: const Text(
                'Connection Request Sent',
                style: TextStyle(
                  color: AppColors.appleBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.appleBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: null,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          NivaButton(
            label: 'Direct Message',
            variant: NivaButtonVariant.secondary,
            isFullWidth: true,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            onPressed:
                () => _showFeedback(
                  'Messaging will be available once the request is accepted.',
                ),
          ),
        ],
      );
    }

    // 4. Default: No request yet (or declined)
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.appleBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.near_me_rounded, size: 18),
            label: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Connect',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(width: 2),
                Opacity(
                  opacity: 0.0,
                  child: Text(
                    'Send Connection Request',
                    style: TextStyle(fontSize: 1),
                  ),
                ),
              ],
            ),
            onPressed: () => _sendConnectionRequestToPeer(
              currentUid: currentUid,
              targetUid: targetUid,
              targetName: targetName,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        NivaButton(
          label: 'Direct Message',
          variant: NivaButtonVariant.secondary,
          isFullWidth: true,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          onPressed:
              () => _showFeedback(
                'Messaging is available after connection request is accepted.',
              ),
        ),
      ],
    );
  }

  // 9. SAFETY & ACCOUNT ACTIONS
  Widget _buildSafetyActions(
    BuildContext context, {
    required bool isOwnProfile,
  }) {
    if (isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Center(
          child: TextButton.icon(
            icon: const Icon(
              Icons.logout_rounded,
              size: 18,
              color: AppColors.error,
            ),
            label: const Text(
              'Log Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      backgroundColor: AppColors.card,
                      title: const Text('Log Out'),
                      content: const Text(
                        'Are you sure you want to log out of NIVA?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                await AuthService.instance.signOut();
              }
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.flag_outlined, size: 16),
            label: const Text('Report Profile'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textTertiary,
            ),
            onPressed: () {
              ReportSheet.show(
                context,
                reportedUserId: widget.targetUserId ?? 'unknown_user',
                reportedUserName: widget.targetUserName ?? 'Community Member',
                referenceId: widget.targetUserId ?? 'profile',
                safetyRepository: widget.safetyRepository,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrustMetricCard extends StatelessWidget {
  const _TrustMetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
