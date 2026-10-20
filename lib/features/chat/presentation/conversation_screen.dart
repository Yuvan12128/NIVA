import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_avatar.dart';
import '../../auth/data/auth_service.dart';
import '../../reviews/presentation/widgets/review_sheet.dart';
import '../../safety/data/safety_repository.dart';
import '../../safety/presentation/widgets/report_sheet.dart';
import '../data/chat_model.dart';
import '../data/chat_repository.dart';
import '../data/message_model.dart';

/// Private 1-to-1 Conversation Screen.
/// Uses a real-time listener strictly for this active conversation.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.chat,
    required this.otherUserName,
    required this.otherUserId,
    this.chatRepository,
    this.safetyRepository,
  });

  final ChatModel chat;
  final String otherUserName;
  final String otherUserId;
  final ChatRepository? chatRepository;
  final SafetyRepository? safetyRepository;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatRepository _chatRepo =
      widget.chatRepository ?? ChatRepository();
  late final SafetyRepository _safetyRepo =
      widget.safetyRepository ?? SafetyRepository();

  bool _isSending = false;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
  }

  Future<void> _checkBlockStatus() async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId != null) {
      final blocked = await _safetyRepo.isBlocked(
        userA: currentUserId,
        userB: widget.otherUserId,
      );
      if (mounted && blocked != _isBlocked) {
        setState(() {
          _isBlocked = blocked;
        });
      }
    }
  }

  Future<void> _showBlockConfirmationDialog() async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        title: Text('Block ${widget.otherUserName}?'),
        content: const Text(
          'You will no longer see each other in search, matching, or receive new messages and connection requests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _safetyRepo.blockUser(
        blockerId: currentUserId,
        blockedUserId: widget.otherUserId,
      );
      if (!mounted) return;
      setState(() {
        _isBlocked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.otherUserName} has been blocked.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _unblockUser() async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    await _safetyRepo.unblockUser(
      blockerId: currentUserId,
      blockedUserId: widget.otherUserId,
    );
    if (!mounted) return;
    setState(() {
      _isBlocked = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.otherUserName} has been unblocked.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUserId = AuthService.instance.currentUser?.uid ?? 'anonymous';

    setState(() {
      _isSending = true;
    });

    try {
      await _chatRepo.sendMessage(
        chatId: widget.chat.id,
        senderId: currentUserId,
        receiverId: widget.otherUserId,
        text: text,
      );

      _textController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send message: ${e.toString().replaceAll("Exception: ", "")}',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.instance.currentUser?.uid ?? 'anonymous';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            NivaAvatar(
              name: widget.otherUserName,
              size: 36,
              backgroundColor: AppColors.servicesBg,
              textColor: AppColors.primaryPurple,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: AppTextStyles.h2.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Direct Connection',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.star_outline_rounded,
              color: AppColors.primaryPurple,
            ),
            tooltip: 'Rate & Review',
            onPressed: () {
              ReviewSheet.show(
                context,
                connectionRequestId: widget.chat.connectionRequestId,
                needId: widget.chat.needId,
                revieweeId: widget.otherUserId,
                revieweeName: widget.otherUserName,
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
            ),
            onSelected: (val) {
              if (val == 'block') {
                _showBlockConfirmationDialog();
              } else if (val == 'unblock') {
                _unblockUser();
              } else if (val == 'report') {
                ReportSheet.show(
                  context,
                  reportedUserId: widget.otherUserId,
                  reportedUserName: widget.otherUserName,
                  referenceId: widget.chat.id,
                  safetyRepository: _safetyRepo,
                );
              }
            },
            itemBuilder: (context) => [
              if (!_isBlocked)
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(
                        Icons.block_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Block User',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'unblock',
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_open_rounded,
                        size: 18,
                        color: AppColors.primaryPurple,
                      ),
                      SizedBox(width: 10),
                      Text('Unblock User'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 10),
                    Text('Report User'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages Stream
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatRepo.streamMessages(widget.chat.id, limit: 40),
                builder: (context, snapshot) {
                  // 1. Loading state
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryPurple,
                          ),
                        ),
                      ),
                    );
                  }

                  // 2. Error state
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'Unable to load messages. Please try again.',
                          style: AppTextStyles.captionSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? const [];

                  // 3. Empty state
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: AppColors.servicesBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppColors.primaryPurple,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'No messages yet',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Say hello to ${widget.otherUserName} regarding your connection!',
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // 4. Message Bubble List (reverse: true for fast bottom anchoring)
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: AppSpacing.md,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;
                      return _MessageBubble(message: message, isMe: isMe);
                    },
                  );
                },
              ),
            ),

            // Input Bar or Blocked Notification Banner
            if (_isBlocked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.md,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  border: Border(
                    top: BorderSide(color: AppColors.borderSubtle, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.block_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Messaging is disabled because this user is blocked.',
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(
                    top: BorderSide(color: AppColors.borderSubtle, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        style: AppTextStyles.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryPurple,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: AppColors.primaryPurple,
                              size: 22,
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final MessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryPurple : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusLg),
            topRight: const Radius.circular(AppSpacing.radiusLg),
            bottomLeft: Radius.circular(isMe ? AppSpacing.radiusLg : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppSpacing.radiusLg),
          ),
          border: isMe
              ? null
              : Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isMe ? AppColors.textOnPrimary : AppColors.textPrimary,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }
}
