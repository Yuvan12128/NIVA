import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/data/auth_service.dart';
import '../../user/data/user_repository.dart';
import '../data/need_model.dart';
import '../data/need_repository.dart';

/// Pixel-perfect "I Need Help" Screen matching Reference Design (Screen 5)
class NeedHelpScreen extends StatefulWidget {
  const NeedHelpScreen({
    super.key,
    this.needRepository,
    this.userRepository,
    this.onPostPublished,
  });

  final NeedRepository? needRepository;
  final UserRepository? userRepository;
  final ValueChanged<NeedModel>? onPostPublished;

  @override
  State<NeedHelpScreen> createState() => _NeedHelpScreenState();
}

class _NeedHelpScreenState extends State<NeedHelpScreen> {
  final TextEditingController _textController = TextEditingController();
  late final NeedRepository _needRepo =
      widget.needRepository ?? NeedRepository();
  late final UserRepository _userRepo =
      widget.userRepository ?? UserRepository();

  static const List<String> _categories = [
    'Programming',
    'Design',
    'Mentorship',
    'Tech Support',
    'Career & Jobs',
    'Academics',
    'Other',
  ];

  String _selectedCategory = 'Programming';
  bool _isPosting = false;
  static const int _maxChars = 200;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Category',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.appleBorder),
            ..._categories.map((cat) {
              final isSelected = cat == _selectedCategory;
              return ListTile(
                onTap: () {
                  setState(() => _selectedCategory = cat);
                  Navigator.of(ctx).pop();
                },
                leading: _buildCategoryIcon(cat),
                title: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.appleBlue : AppColors.appleTextPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: AppColors.appleBlue, size: 20)
                    : null,
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String cat) {
    IconData iconData;
    switch (cat) {
      case 'Programming':
        iconData = Icons.code_rounded;
        break;
      case 'Design':
        iconData = Icons.palette_outlined;
        break;
      case 'Mentorship':
        iconData = Icons.school_outlined;
        break;
      case 'Tech Support':
        iconData = Icons.build_outlined;
        break;
      case 'Career & Jobs':
        iconData = Icons.work_outline_rounded;
        break;
      default:
        iconData = Icons.lightbulb_outline_rounded;
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.appleBlueSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: AppColors.appleBlue, size: 18),
    );
  }

  Future<void> _handlePost() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what you need help with.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final currentUser = AuthService.instance.currentUser;
      final uid = currentUser?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

      String authorName = currentUser?.displayName ?? '';
      String? authorPhoto = currentUser?.photoURL;
      String? authorProfession;

      try {
        final profile = await _userRepo.getUserProfile(uid);
        if (profile != null) {
          if (profile.name.isNotEmpty) authorName = profile.name;
          if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty) {
            authorPhoto = profile.photoUrl;
          }
          if (profile.profession.isNotEmpty) {
            authorProfession = profile.profession;
          }
        }
      } catch (_) {}

      if (authorName.isEmpty) {
        authorName = currentUser?.email?.split('@').first ?? 'Yuvan';
      }

      final post = NeedModel(
        needId: '',
        userId: uid,
        type: 'need',
        title: text.length > 50 ? '${text.substring(0, 47)}...' : text,
        description: text,
        skills: [_selectedCategory],
        authorName: authorName,
        authorPhotoUrl: authorPhoto,
        authorProfession: authorProfession,
        createdAt: DateTime.now(),
      );

      final newId = await _needRepo.createNeed(post);
      final savedPost = post.copyWith(needId: newId);

      if (mounted) {
        widget.onPostPublished?.call(savedPost);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Help request posted successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.appleBlue,
          ),
        );
        Navigator.of(context).pop(savedPost);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post request: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLength = _textController.text.length;

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.appleTextPrimary,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'I Need Help',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.appleTextPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prompt Question
                  const Text(
                    'What do you need help with?',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.appleTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Large Description Input Card with Character Counter
                  Container(
                    height: 160,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.appleBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            maxLength: _maxChars,
                            maxLines: null,
                            expands: true,
                            buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                                const SizedBox.shrink(),
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 15,
                              color: AppColors.appleTextPrimary,
                              height: 1.4,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'I need help with Java basics and projects.',
                              hintStyle: TextStyle(
                                color: AppColors.appleTextTertiary,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                        Text(
                          '$currentLength / $_maxChars',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.appleTextTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Category Label
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.appleTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category Dropdown Card
                  InkWell(
                    onTap: _showCategoryPicker,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.appleBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.code_rounded,
                            size: 20,
                            color: AppColors.appleBlue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedCategory,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.appleTextPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.appleTextTertiary,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Full-width Apple Blue "Post" Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appleBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isPosting ? null : _handlePost,
                      child: _isPosting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Post',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
