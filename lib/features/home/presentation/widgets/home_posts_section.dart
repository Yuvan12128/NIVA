import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/niva_avatar.dart';
import '../../../auth/data/auth_service.dart';
import '../../../needs/data/need_model.dart';
import '../../../needs/data/need_repository.dart';
import '../../../needs/presentation/widgets/create_post_sheet.dart';
import '../../../user/data/user_repository.dart';

/// Segmented feed section displayed prominently on the Home screen.
/// Features Apple minimal styling, two segmented tabs (Need Help | Can Help),
/// author photo, name, profession, and in-place edit/delete for post authors.
class HomePostsSection extends StatefulWidget {
  const HomePostsSection({
    super.key,
    this.needRepository,
    this.userRepository,
    this.initialType = 'need',
    this.onPostTap,
  });

  final NeedRepository? needRepository;
  final UserRepository? userRepository;
  final String initialType;
  final ValueChanged<NeedModel>? onPostTap;

  @override
  State<HomePostsSection> createState() => _HomePostsSectionState();
}

class _HomePostsSectionState extends State<HomePostsSection> {
  late String _selectedType;
  late final NeedRepository _needRepo =
      widget.needRepository ?? NeedRepository();
  late final UserRepository _userRepo =
      widget.userRepository ?? UserRepository();

  StreamSubscription<List<NeedModel>>? _subscription;
  List<NeedModel>? _posts;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _subscribeToPosts();
  }

  @override
  void didUpdateWidget(covariant HomePostsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.needRepository != widget.needRepository) {
      _subscribeToPosts();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToPosts() {
    _subscription?.cancel();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _subscription = _needRepo.streamNeedsByType(_selectedType).listen(
      (data) {
        if (mounted) {
          setState(() {
            _posts = data;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      },
      onError: (dynamic error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = error.toString();
          });
        }
      },
    );
  }

  void _onTabChanged(String type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
    });
    _subscribeToPosts();
  }

  Future<void> _openCreatePost() async {
    final created = await CreatePostSheet.show(
      context,
      initialType: _selectedType,
      needRepository: _needRepo,
      userRepository: _userRepo,
    );
    if (created != null && mounted) {
      _subscribeToPosts();
    }
  }

  Future<void> _openEditPost(NeedModel post) async {
    final updated = await CreatePostSheet.show(
      context,
      existingPost: post,
      needRepository: _needRepo,
      userRepository: _userRepo,
    );
    if (updated != null && mounted) {
      _subscribeToPosts();
    }
  }

  Future<void> _confirmDeletePost(NeedModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Post'),
            content: Text(
              'Are you sure you want to delete "${post.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        await _needRepo.deleteNeed(post.needId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _subscribeToPosts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete post: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & New Post Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Community Posts',
                style: AppTextStyles.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 15),
              label: const Text(
                'New Post',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.appleBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(
                    color: AppColors.appleBlue,
                    width: 0.8,
                  ),
                ),
              ),
              onPressed: _openCreatePost,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Segmented Tabs: Need Help | Can Help
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.appleSecondaryBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.appleBorder, width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentButton(
                  type: 'need',
                  title: 'Need Help',
                  icon: Icons.lightbulb_outline_rounded,
                ),
              ),
              Expanded(
                child: _buildSegmentButton(
                  type: 'help',
                  title: 'Can Help',
                  icon: Icons.volunteer_activism_outlined,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Feed State Handling
        if (_isLoading)
          _buildLoadingState()
        else if (_errorMessage != null)
          _buildErrorState(_errorMessage!)
        else if (_posts == null || _posts!.isEmpty)
          _buildEmptyState()
        else
          _buildPostsList(_posts!),
      ],
    );
  }

  Widget _buildSegmentButton({
    required String type,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => _onTabChanged(type),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow:
              isSelected
                  ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.appleBlue : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected ? AppColors.appleBlue : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.appleBorder, width: 0.8),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.appleBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.appleBorder, width: 0.8),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Unable to load posts',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textTertiary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: _subscribeToPosts,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.appleBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isNeed = _selectedType == 'need';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.appleBorder, width: 0.8),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.appleSecondaryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNeed
                  ? Icons.lightbulb_outline_rounded
                  : Icons.volunteer_activism_outlined,
              color: AppColors.appleBlue,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isNeed ? 'No Help Requests Yet' : 'No Help Offers Yet',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isNeed
                ? 'Be the first to post what help or guidance you need from the community.'
                : 'Share your skills and capabilities to help peers across the platform.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.appleBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: Text(isNeed ? 'Request Help' : 'Offer Help'),
            onPressed: _openCreatePost,
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(List<NeedModel> posts) {
    return Column(
      children:
          posts.map((post) {
            return _PostCard(
              post: post,
              needRepository: _needRepo,
              onEdit: () => _openEditPost(post),
              onDelete: () => _confirmDeletePost(post),
              onTap: () => widget.onPostTap?.call(post),
              timeAgo: _formatTimeAgo(post.createdAt),
            );
          }).toList(),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.needRepository,
    required this.onEdit,
    required this.onDelete,
    required this.timeAgo,
    this.onTap,
  });

  final NeedModel post;
  final NeedRepository needRepository;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String timeAgo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService.instance.currentUser?.uid;
    // Allow author or test environments to edit/delete
    final isAuthor =
        post.userId.isNotEmpty &&
        (post.userId == currentUid ||
            (currentUid == null && post.userId.startsWith('guest_')));

    final isNeed = post.type == 'need';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.appleBorder, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar, Name, Profession, Date, Action Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NivaAvatar(
                      name: post.authorName ?? 'Community Member',
                      imageUrl: post.authorPhotoUrl,
                      size: 42,
                      isVerified: true,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.authorName ?? 'Community Member',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isNeed
                                          ? AppColors.appleBlue.withValues(
                                            alpha: 0.1,
                                          )
                                          : AppColors.helpBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isNeed ? 'Need' : 'Help',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isNeed
                                            ? AppColors.appleBlue
                                            : AppColors.helpIcon,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (post.authorProfession != null &&
                              post.authorProfession!.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              post.authorProfession!,
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.appleBlue,
                                fontWeight: FontWeight.w500,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            timeAgo,
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAuthor)
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (val) {
                          if (val == 'edit') {
                            onEdit();
                          } else if (val == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder:
                            (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Edit Post'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete Post',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Post Title
                Text(
                  post.title,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),

                // Post Description
                Text(
                  post.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 13.5,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),

                // Skills tags (if present)
                if (post.skills.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        post.skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.appleSecondaryBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.appleBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              skill,
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
