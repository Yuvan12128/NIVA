import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/niva_avatar.dart';
import '../../../auth/data/auth_service.dart';
import '../../../user/data/user_model.dart';
import '../../../user/data/user_repository.dart';
import '../../data/need_model.dart';
import '../../data/need_repository.dart';

/// Apple-minimal bottom sheet for creating and editing "I Need Help" and "I Can Help" posts.
/// Enforces required Title and Description, automatic profile attribution, and duplicate prevention.
class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({
    super.key,
    this.existingPost,
    this.initialType,
    this.needRepository,
    this.userRepository,
    this.onPostPublished,
  });

  final NeedModel? existingPost;
  final String? initialType;
  final NeedRepository? needRepository;
  final UserRepository? userRepository;
  final ValueChanged<NeedModel>? onPostPublished;

  static Future<NeedModel?> show(
    BuildContext context, {
    NeedModel? existingPost,
    String? initialType,
    NeedRepository? needRepository,
    UserRepository? userRepository,
    ValueChanged<NeedModel>? onPostPublished,
  }) {
    return showModalBottomSheet<NeedModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => CreatePostSheet(
            existingPost: existingPost,
            initialType: initialType,
            needRepository: needRepository,
            userRepository: userRepository,
            onPostPublished: onPostPublished,
          ),
    );
  }

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  late String _selectedType;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _skillsController;

  late final NeedRepository _needRepo =
      widget.needRepository ?? NeedRepository();
  late final UserRepository _userRepo =
      widget.userRepository ?? UserRepository();

  String? _titleError;
  String? _descriptionError;
  bool _isPublishing = false;
  UserModel? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _selectedType =
        widget.existingPost?.type ?? widget.initialType ?? 'need';
    _titleController = TextEditingController(
      text: widget.existingPost?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingPost?.description ?? '',
    );
    _skillsController = TextEditingController(
      text: widget.existingPost?.skills.join(', ') ?? '',
    );
    _loadUserProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        final profile = await _userRepo.getUserProfile(uid);
        if (mounted && profile != null) {
          setState(() {
            _currentUserProfile = profile;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _submitPost() async {
    if (_isPublishing) return; // Prevent duplicate submissions

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    bool isValid = true;
    setState(() {
      if (title.isEmpty) {
        _titleError = 'Title is required';
        isValid = false;
      } else {
        _titleError = null;
      }

      if (description.isEmpty) {
        _descriptionError = 'Description is required';
        isValid = false;
      } else {
        _descriptionError = null;
      }
    });

    if (!isValid) return;

    setState(() {
      _isPublishing = true;
    });

    try {
      final currentUser = AuthService.instance.currentUser;
      final uid =
          widget.existingPost?.userId ??
          currentUser?.uid ??
          'guest_${DateTime.now().millisecondsSinceEpoch}';

      final authorName =
          _currentUserProfile?.name.isNotEmpty == true
              ? _currentUserProfile!.name
              : (currentUser?.displayName?.isNotEmpty == true
                  ? currentUser!.displayName!
                  : (currentUser?.email != null
                      ? currentUser!.email!.split('@').first
                      : 'Community Member'));

      final authorPhotoUrl =
          _currentUserProfile?.photoUrl?.isNotEmpty == true
              ? _currentUserProfile!.photoUrl
              : currentUser?.photoURL;

      final authorProfession =
          _currentUserProfile?.profession.isNotEmpty == true
              ? _currentUserProfile!.profession
              : null;

      final skills =
          _skillsController.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

      if (widget.existingPost != null) {
        // Edit existing post
        final updateMap = <String, dynamic>{
          'title': title,
          'description': description,
          'skills': skills,
          'type': _selectedType,
        };

        await _needRepo.updateNeed(widget.existingPost!.needId, updateMap);

        final updatedPost = widget.existingPost!.copyWith(
          title: title,
          description: description,
          skills: skills,
          type: _selectedType,
          updatedAt: DateTime.now(),
        );

        if (mounted) {
          widget.onPostPublished?.call(updatedPost);
          Navigator.of(context).pop(updatedPost);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post updated successfully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Create new post
        final newPost = NeedModel(
          needId: '',
          userId: uid,
          type: _selectedType,
          title: title,
          description: description,
          skills: skills,
          authorName: authorName,
          authorPhotoUrl: authorPhotoUrl,
          authorProfession: authorProfession,
          createdAt: DateTime.now(),
        );

        final createdId = await _needRepo.createNeed(newPost);
        final savedPost = newPost.copyWith(needId: createdId);

        if (mounted) {
          widget.onPostPublished?.call(savedPost);
          Navigator.of(context).pop(savedPost);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selectedType == 'need'
                    ? 'Help request published to Home feed.'
                    : 'Help capability published to Home feed.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish post: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final isEditing = widget.existingPost != null;

    final currentUser = AuthService.instance.currentUser;
    final authorName =
        _currentUserProfile?.name.isNotEmpty == true
            ? _currentUserProfile!.name
            : (currentUser?.displayName?.isNotEmpty == true
                ? currentUser!.displayName!
                : (currentUser?.email != null
                    ? currentUser!.email!.split('@').first
                    : 'Community Member'));

    final authorPhoto =
        _currentUserProfile?.photoUrl?.isNotEmpty == true
            ? _currentUserProfile!.photoUrl
            : currentUser?.photoURL;

    final authorProfession =
        _currentUserProfile?.profession.isNotEmpty == true
            ? _currentUserProfile!.profession
            : 'Verified Peer';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Title & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Post' : 'Create Post',
                    style: AppTextStyles.h2.copyWith(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Segmented Type Selector (I Need Help | I Can Help)
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
                      child: _buildTypeSegment(
                        type: 'need',
                        label: 'I Need Help',
                        icon: Icons.lightbulb_outline_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildTypeSegment(
                        type: 'help',
                        label: 'I Can Help',
                        icon: Icons.volunteer_activism_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Automatic Author Preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.appleSecondaryBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.appleBorder, width: 0.8),
                ),
                child: Row(
                  children: [
                    NivaAvatar(
                      name: authorName,
                      imageUrl: authorPhoto,
                      size: 40,
                      isVerified: true,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            authorProfession,
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.appleBlue,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title Field (Required)
              _buildFieldLabel(
                _selectedType == 'need'
                    ? 'What help do you need? *'
                    : 'What help can you offer? *',
              ),
              TextField(
                controller: _titleController,
                style: AppTextStyles.bodyMedium,
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  hintText:
                      _selectedType == 'need'
                          ? 'E.g., Need a senior Flutter mentor'
                          : 'E.g., Can help with code reviews and architecture',
                  errorText: _titleError,
                ),
                onChanged: (_) {
                  if (_titleError != null) {
                    setState(() => _titleError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Description Field (Required)
              _buildFieldLabel('Description *'),
              TextField(
                controller: _descriptionController,
                style: AppTextStyles.bodyMedium,
                minLines: 3,
                maxLines: 5,
                decoration: _buildInputDecoration(
                  hintText:
                      _selectedType == 'need'
                          ? 'Describe your requirement in detail, expectations, timeline, etc.'
                          : 'Describe your expertise, availability, and how you can help peers.',
                  errorText: _descriptionError,
                ),
                onChanged: (_) {
                  if (_descriptionError != null) {
                    setState(() => _descriptionError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Skills Field (Optional)
              _buildFieldLabel('Relevant Skills (optional)'),
              TextField(
                controller: _skillsController,
                style: AppTextStyles.bodyMedium,
                decoration: _buildInputDecoration(
                  hintText: 'Comma separated e.g. Flutter, Dart, Clean Code',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Publish Action Button
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
                  onPressed: _isPublishing ? null : _submitPost,
                  child:
                      _isPublishing
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            isEditing ? 'Save Changes' : 'Publish Post',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegment({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        if (_selectedType != type) {
          setState(() {
            _selectedType = type;
          });
        }
      },
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.appleBlue : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected ? AppColors.appleBlue : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.appleTextTertiary, fontSize: 13.5),
      errorText: errorText,
      filled: true,
      fillColor: AppColors.appleSecondaryBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.appleBorder, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.appleBorder, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.appleBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
    );
  }
}
