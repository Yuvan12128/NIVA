import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_avatar.dart';
import '../../../core/widgets/niva_button.dart';
import '../../auth/data/auth_service.dart';
import '../../safety/data/safety_repository.dart';
import '../../safety/presentation/widgets/report_sheet.dart';
import '../../user/data/user_model.dart';
import '../../user/data/user_repository.dart';
import 'widgets/edit_profile_sheet.dart';

/// User Profile Screen for NIVA.
/// Built around two core discovery questions:
/// 1. "What does this person need?"
/// 2. "What can this person help with?"
/// Strictly non-social-media: no follower counts, likes, or vanity metrics.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.targetUserId,
    this.targetUserName,
    this.safetyRepository,
    this.userRepository,
  });

  final String? targetUserId;
  final String? targetUserName;
  final SafetyRepository? safetyRepository;
  final UserRepository? userRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserRepository _userRepo =
      widget.userRepository ?? UserRepository();
  UserModel? _userProfile;

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
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = widget.targetUserId ?? AuthService.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        final profile = await _userRepo.getUserProfile(uid);
        if (mounted && profile != null) {
          setState(() {
            _userProfile = profile;
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

    final baseUser = _userProfile ?? UserModel(
      uid: currentUser?.uid ?? '',
      name: fallbackName,
      bio: isGuestOrTest
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

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final isGuestOrTest = currentUser == null && widget.targetUserId == null;

    final fallbackName = currentUser?.displayName?.isNotEmpty == true
        ? currentUser!.displayName!
        : (currentUser?.email != null
              ? currentUser!.email!.split('@').first
              : 'Arun Kumar');

    final displayName = _userProfile?.name.isNotEmpty == true
        ? _userProfile!.name
        : (widget.targetUserName ?? fallbackName);

    final city = _userProfile?.city.isNotEmpty == true
        ? _userProfile!.city
        : (isGuestOrTest ? 'Chennai (Remote flexible)' : 'Location not set');

    final language = _userProfile?.language.isNotEmpty == true
        ? _userProfile!.language
        : (isGuestOrTest ? 'English, Tamil' : 'English');

    final availability = _userProfile?.availability.isNotEmpty == true
        ? _userProfile!.availability
        : 'Available for discovery';

    final activeNeeds = _userProfile?.lookingFor.isNotEmpty == true
        ? _userProfile!.lookingFor
        : (isGuestOrTest ? _defaultActiveNeeds : const <String>[]);

    final helpCapabilities = _userProfile?.canHelpWith.isNotEmpty == true
        ? _userProfile!.canHelpWith
        : (_userProfile?.skills.isNotEmpty == true
              ? _userProfile!.skills
              : (isGuestOrTest ? _defaultHelpCapabilities : const <String>[]));

    final bioText = _userProfile?.bio.isNotEmpty == true
        ? _userProfile!.bio
        : (isGuestOrTest
            ? 'Building accessible tools, collaborating on needs, and connecting with community peers across NIVA.'
            : 'No bio added yet. Tap Edit Profile to introduce yourself to the community.');

    final isOwnProfile = widget.targetUserId == null ||
        widget.targetUserId == currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile', style: AppTextStyles.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _showFeedback(context, 'Opening Settings...'),
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
                  // 1. Header
                  _buildHeader(
                    context,
                    displayName: displayName,
                    city: city,
                    language: language,
                    bio: bioText,
                    hasCustomBio: _userProfile?.bio.isNotEmpty == true || isGuestOrTest,
                    isOwnProfile: isOwnProfile,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 2. Trust Indicators (Non-vanity)
                  _buildTrustSection(),
                  const SizedBox(height: AppSpacing.xl),

                  // 3. Availability
                  _buildAvailabilitySection(availability: availability),
                  const SizedBox(height: AppSpacing.xl),

                  // 4. I Need (Active Needs)
                  _buildNeedsSection(context, activeNeeds: activeNeeds),
                  const SizedBox(height: AppSpacing.xl),

                  // 5. I Can Help (Capabilities)
                  _buildHelpSection(context, capabilities: helpCapabilities),
                  const SizedBox(height: AppSpacing.xl),

                  // 6. Profile Actions
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
    required String city,
    required String language,
    required String bio,
    required bool hasCustomBio,
    required bool isOwnProfile,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NivaAvatar(
                name: displayName,
                size: 76,
                isVerified: true,
                backgroundColor: AppColors.servicesBg,
                textColor: AppColors.primaryPurple,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: AppTextStyles.h3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.blue,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Community Member & Discovery Explorer',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            city,
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.translate_rounded,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            language,
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.textTertiary,
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
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            bio,
            style: AppTextStyles.bodyMedium.copyWith(
              color: hasCustomBio
                  ? AppColors.textPrimary
                  : AppColors.textTertiary,
              height: 1.45,
              fontSize: 13.5,
              fontStyle: hasCustomBio ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isOwnProfile)
            NivaButton(
              label: 'Edit Profile',
              variant: NivaButtonVariant.secondary,
              isFullWidth: true,
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: _openEditProfile,
            ),
        ],
      ),
    );
  }

  // 2. TRUST SECTION (Useful trust indicators only)
  Widget _buildTrustSection() {
    final trustScore = _userProfile?.trustScore ?? 100;
    final completedConnections = _userProfile?.completedConnections ?? 0;
    final helpfulInteractions = _userProfile?.helpfulInteractions ?? 0;
    final reviewCount = _userProfile?.reviewCount ?? 0;
    final rating = _userProfile?.rating ?? 5.0;

    final reviewLabel = reviewCount == 0
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
                iconColor: AppColors.blue,
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

  // 3. AVAILABILITY
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

  // 4. I NEED (Active Needs)
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

  // 5. I CAN HELP (Capabilities)
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
            children: capabilities.map((capability) {
              return Container(
                constraints: const BoxConstraints(maxWidth: 260),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.helpBg,
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(color: AppColors.helpIcon.withValues(alpha: 0.2)),
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

  // 6. PROFILE ACTIONS
  Widget _buildActionsSection(
    BuildContext context, {
    required bool isOwnProfile,
  }) {
    if (isOwnProfile) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        NivaButton(
          label: 'Send Connection Request',
          isFullWidth: true,
          icon: const Icon(Icons.handshake_rounded, size: 18),
          onPressed: () =>
              _showFeedback(context, 'Connection request sent to peer.'),
        ),
        const SizedBox(height: AppSpacing.sm),
        NivaButton(
          label: 'Direct Message',
          variant: NivaButtonVariant.secondary,
          isFullWidth: true,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          onPressed: () =>
              _showFeedback(context, 'Opening secure messaging channel...'),
        ),
      ],
    );
  }

  // 7. SAFETY & ACCOUNT ACTIONS
  Widget _buildSafetyActions(BuildContext context, {required bool isOwnProfile}) {
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
                builder: (ctx) => AlertDialog(
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
