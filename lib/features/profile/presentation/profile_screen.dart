import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_avatar.dart';
import '../../../core/widgets/niva_button.dart';
import '../../auth/data/auth_service.dart';

/// User Profile Screen for NIVA.
/// Built around two core discovery questions:
/// 1. "What does this person need?"
/// 2. "What can this person help with?"
/// Strictly non-social-media: no follower counts, likes, or vanity metrics.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const List<String> _activeNeeds = [
    'Looking for a Java & distributed systems mentor',
    'Looking for a photographer for local tech meetup',
    'Looking for a React & Flutter contributor community',
  ];

  static const List<String> _helpCapabilities = [
    'Java',
    'React',
    'Flutter',
    'Laptop repair',
    'Mentoring beginners',
  ];

  @override
  Widget build(BuildContext context) {
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
                  _buildHeader(context),
                  const SizedBox(height: AppSpacing.xl),

                  // 2. Trust Indicators (Non-vanity)
                  _buildTrustSection(),
                  const SizedBox(height: AppSpacing.xl),

                  // 3. Availability
                  _buildAvailabilitySection(),
                  const SizedBox(height: AppSpacing.xl),

                  // 4. I Need (Active Needs)
                  _buildNeedsSection(context),
                  const SizedBox(height: AppSpacing.xl),

                  // 5. I Can Help (Capabilities)
                  _buildHelpSection(context),
                  const SizedBox(height: AppSpacing.xl),

                  // 6. Profile Actions
                  _buildActionsSection(context),
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
  Widget _buildHeader(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final displayName = currentUser?.displayName?.isNotEmpty == true
        ? currentUser!.displayName!
        : (currentUser?.email != null
              ? currentUser!.email!.split('@').first
              : 'Arun Kumar');

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
                      'Mobile engineer & discovery explorer',
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
                        Text(
                          'Chennai (Remote flexible)',
                          style: AppTextStyles.captionSmall.copyWith(
                            color: AppColors.textTertiary,
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
                        Text(
                          'English, Tamil',
                          style: AppTextStyles.captionSmall.copyWith(
                            color: AppColors.textTertiary,
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
            'Building accessible tools. Currently exploring distributed systems and always happy to help beginners with Flutter and frontend architecture.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          NivaButton(
            label: 'Edit Profile',
            variant: NivaButtonVariant.secondary,
            isFullWidth: true,
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () =>
                _showFeedback(context, 'Edit profile form opening...'),
          ),
        ],
      ),
    );
  }

  // 2. TRUST SECTION (Useful trust indicators only)
  Widget _buildTrustSection() {
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
                value: '18',
                label: 'Completed connections',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TrustMetricCard(
                icon: Icons.volunteer_activism_outlined,
                iconColor: AppColors.helpIcon,
                iconBg: AppColors.helpBg,
                value: '42',
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
                value: '4.9',
                label: '24 verified reviews',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TrustMetricCard(
                icon: Icons.verified_user_outlined,
                iconColor: AppColors.blue,
                iconBg: AppColors.infoBg,
                value: 'Verified',
                label: 'ID & Phone confirmed',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. AVAILABILITY
  Widget _buildAvailabilitySection() {
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
                    Text(
                      'Available for discovery',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Active this week • Typically responds within ~1 hour',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Open for: Remote guidance & local discussions in Chennai',
                  style: AppTextStyles.captionSmall.copyWith(
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
  Widget _buildNeedsSection(BuildContext context) {
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
                '${_activeNeeds.length} active',
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
        ..._activeNeeds.map((need) {
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
  Widget _buildHelpSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('I Can Help With', style: AppTextStyles.subtitle),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: const BoxDecoration(
                color: AppColors.helpBg,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
              child: Text(
                '${_helpCapabilities.length} capabilities',
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
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _helpCapabilities
              .map((capability) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppSpacing.borderRadiusFull,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.helpIcon,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        capability,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  // 6. PROFILE ACTIONS
  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Settings & Privacy', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.sm),
        _ActionTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy & Discovery',
          subtitle: 'Manage what information is visible to discovery queries',
          onTap: () =>
              _showFeedback(context, 'Privacy & Discovery preferences'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionTile(
          icon: Icons.tune_rounded,
          title: 'Preferences',
          subtitle: 'Notifications, languages, and regional settings',
          onTap: () => _showFeedback(context, 'Preferences opening...'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionTile(
          icon: Icons.help_outline_rounded,
          title: 'Help & About NIVA',
          subtitle: 'Version 1.0.0 • Community guidelines & trust policies',
          onTap: () => _showFeedback(context, 'About NIVA & guidelines'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionTile(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          subtitle: 'Log out of your account on this device',
          onTap: () async {
            try {
              await AuthService.instance.signOut();
            } catch (e) {
              if (context.mounted) {
                _showFeedback(
                  context,
                  'Logout failed: ${AuthService.getErrorMessage(e)}',
                );
              }
            }
          },
        ),
      ],
    );
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Compact trust metric card for non-vanity indicators.
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Action item tile in the settings and preferences list.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.servicesBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primaryPurple, size: 19),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
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
