import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/niva_avatar.dart';
import '../../../../core/widgets/niva_button.dart';
import '../../../auth/data/auth_service.dart';
import '../../../connect/data/connection_request_repository.dart';
import '../../../needs/data/need_model.dart';
import '../../data/match_result.dart';
import '../../data/matching_service.dart';

/// Modal bottom sheet presenting ranked matching helpers for an active need.
/// Supports immediate 1-to-1 Connect Requests.
class MatchingSheet extends StatefulWidget {
  const MatchingSheet({
    super.key,
    required this.need,
    this.matchingService,
    this.connectionRequestRepository,
  });

  final NeedModel need;
  final MatchingService? matchingService;
  final ConnectionRequestRepository? connectionRequestRepository;

  static void show(
    BuildContext context, {
    required NeedModel need,
    MatchingService? matchingService,
    ConnectionRequestRepository? connectionRequestRepository,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MatchingSheet(
        need: need,
        matchingService: matchingService,
        connectionRequestRepository: connectionRequestRepository,
      ),
    );
  }

  @override
  State<MatchingSheet> createState() => _MatchingSheetState();
}

class _MatchingSheetState extends State<MatchingSheet> {
  late final MatchingService _matchingService =
      widget.matchingService ?? MatchingService();
  late final ConnectionRequestRepository _requestRepo =
      widget.connectionRequestRepository ?? ConnectionRequestRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<MatchResult> _matches = [];

  final Set<String> _sentUserIds = {};
  final Set<String> _sendingUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _matchingService.findMatches(
        widget.need,
        limit: 10,
      );

      final currentUserId = AuthService.instance.currentUser?.uid;
      Set<String> alreadySent = {};
      if (currentUserId != null &&
          currentUserId.isNotEmpty &&
          widget.need.needId.isNotEmpty) {
        alreadySent = await _requestRepo.getSentRecipientIdsForNeed(
          fromUserId: currentUserId,
          needId: widget.need.needId,
        );
      }

      final filteredResults = results
          .where((r) => currentUserId == null || r.userId != currentUserId)
          .toList();

      if (!mounted) return;
      setState(() {
        _matches = filteredResults;
        _sentUserIds.addAll(alreadySent);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to calculate matching candidates.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConnect(MatchResult match) async {
    final currentUserId = AuthService.instance.currentUser?.uid ?? 'anonymous';
    if (match.userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot send a connection request to yourself.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_sendingUserIds.contains(match.userId) ||
        _sentUserIds.contains(match.userId)) {
      return;
    }

    setState(() {
      _sendingUserIds.add(match.userId);
    });

    try {
      await _requestRepo.sendConnectRequest(
        fromUserId: currentUserId,
        toUserId: match.userId,
        needId: widget.need.needId,
      );

      if (!mounted) return;
      setState(() {
        _sendingUserIds.remove(match.userId);
        _sentUserIds.add(match.userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection request sent to ${match.name}!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendingUserIds.remove(match.userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not send request: ${e.toString().replaceAll("Exception: ", "")}',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                    ),
                  ),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Matching Helpers (V1)',
                              style: AppTextStyles.h2,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.need.title,
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Body Content based on state
                  Flexible(child: _buildBody()),

                  const SizedBox(height: AppSpacing.md),
                  NivaButton(
                    label: 'Close',
                    variant: NivaButtonVariant.secondary,
                    isFullWidth: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 1. Loading State
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryPurple,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Scoring & ranking candidates...',
                style: AppTextStyles.captionSmall,
              ),
            ],
          ),
        ),
      );
    }

    // 2. Error State
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.textTertiary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: _loadMatches, child: const Text('Retry')),
          ],
        ),
      );
    }

    // 3. Empty State
    if (_matches.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_search_outlined,
              color: AppColors.textTertiary,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No matching helpers found yet',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'As more community members share their skills and capabilities, matches will appear here ranked by relevance.',
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 4. Matches List
    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: _matches.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final match = _matches[index];
        final isSent = _sentUserIds.contains(match.userId);
        final isSending = _sendingUserIds.contains(match.userId);

        return _MatchCard(
          match: match,
          rank: index + 1,
          isSent: isSent,
          isSending: isSending,
          onConnect: () => _handleConnect(match),
        );
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.rank,
    required this.isSent,
    required this.isSending,
    required this.onConnect,
  });

  final MatchResult match;
  final int rank;
  final bool isSent;
  final bool isSending;
  final VoidCallback onConnect;

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
          // Top Row: Avatar, Name, Meta, and Score Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NivaAvatar(
                name: match.name,
                size: 42,
                backgroundColor: AppColors.helpBg,
                textColor: AppColors.helpIcon,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      match.offerTitle ?? match.category,
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Match Score Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.helpBg,
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: AppColors.helpIcon.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: AppColors.helpIcon,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${match.matchPercentage}%',
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.helpIcon,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Location & Availability row
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 3),
              Text(
                match.location,
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 3),
              Text(
                match.availability,
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),

          // Matched Skills Tags (if any)
          if (match.matchedSkills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: match.matchedSkills
                  .map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.servicesBg,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        s,
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.primaryPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ],

          const SizedBox(height: AppSpacing.xs),

          // Score Breakdown Note
          Text(
            'Skills: ${match.skillScore.round()}/40 • Loc: ${match.locationScore.round()}/20 • Avail: ${match.availabilityScore.round()}/15 • Cat: ${match.categoryScore.round()}/15 • Trust: ${match.trustScoreComponent.round()}/10',
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Connect CTA
          if (isSent)
            Container(
              width: double.infinity,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.helpBg,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: AppColors.helpIcon.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_rounded,
                    color: AppColors.helpIcon,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Request Sent',
                    style: TextStyle(
                      color: AppColors.helpIcon,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            NivaButton(
              label: 'Connect',
              height: 36,
              isFullWidth: true,
              isLoading: isSending,
              icon: const Icon(Icons.person_add_outlined, size: 16),
              onPressed: isSending ? null : onConnect,
            ),
        ],
      ),
    );
  }
}
