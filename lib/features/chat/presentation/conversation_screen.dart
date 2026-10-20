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
            Stack(
              clipBehavior: Clip.none,
              children: [
                NivaAvatar(
                  name: widget.otherUserName,
                  size: 38,
                  backgroundColor: AppColors.servicesBg,
                  textColor: AppColors.primaryPurple,
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.otherUserName,
                          style: AppTextStyles.h2.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppColors.primaryPurple,
                      ),
                    ],
                  ),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Available',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' • Community Verified',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.surfaceLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_rounded,
                size: 16,
                color: AppColors.primaryPurple,
              ),
            ),
            tooltip: 'Audio Call',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Audio call connected via NIVA peer audio.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
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
            // Contextual Request Banner
            _ContextualRequestBanner(
              needId: widget.chat.needId,
              otherUserName: widget.otherUserName,
            ),

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
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SystemMatchCard(
                            otherUserName: widget.otherUserName,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
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
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _SystemMatchCard(
                            otherUserName: widget.otherUserName,
                          ),
                        );
                      }
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;
                      return _MessageBubble(
                        message: message,
                        isMe: isMe,
                        otherUserName: widget.otherUserName,
                      );
                    },
                  );
                },
              ),
            ),

            // Quick Replies Pill Carousel
            if (!_isBlocked)
              _QuickRepliesCarousel(
                onSelectReply: (reply) {
                  _textController.text = reply;
                  _textController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _textController.text.length),
                  );
                },
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
                    // Media triggers
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                      tooltip: 'Attachment',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('File attachments supported.'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      tooltip: 'Photo',
                      onPressed: () {},
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
                                  hintStyle: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const Icon(
                              Icons.mood_rounded,
                              size: 20,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPurple,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
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

class _ContextualRequestBanner extends StatelessWidget {
  const _ContextualRequestBanner({
    required this.needId,
    required this.otherUserName,
  });

  final String needId;
  final String otherUserName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'CONTEXTUAL REQUEST',
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                        'In Progress',
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  needId.isNotEmpty
                      ? 'Connection Need #$needId'
                      : 'Direct Conversation with $otherUserName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '1-to-1 secure chat • Community verified',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 12,
                          color: AppColors.primaryPurple,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemMatchCard extends StatelessWidget {
  const _SystemMatchCard({required this.otherUserName});

  final String otherUserName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primaryPurple,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Need Match Connected',
                  style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'You connected with $otherUserName via NIVA Need Match. Keep interactions safe, friendly, and aligned with community trust.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickRepliesCarousel extends StatelessWidget {
  const _QuickRepliesCarousel({required this.onSelectReply});

  final ValueChanged<String> onSelectReply;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        children: [
          _ReplyChip(
            icon: Icons.code_rounded,
            label: 'Send Repo Link',
            onTap: () => onSelectReply('Here is the GitHub repo: '),
          ),
          const SizedBox(width: 8),
          _ReplyChip(
            icon: Icons.calendar_today_rounded,
            label: 'Schedule Call',
            onTap: () => onSelectReply('Can we schedule a quick call today?'),
          ),
          const SizedBox(width: 8),
          _ReplyChip(
            icon: Icons.attachment_rounded,
            label: 'Share Details',
            onTap: () => onSelectReply('Here are the project requirements: '),
          ),
        ],
      ),
    );
  }
}

class _ReplyChip extends StatelessWidget {
  const _ReplyChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryPurple),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.otherUserName = '',
  });

  final MessageModel message;
  final bool isMe;
  final String otherUserName;

  @override
  Widget build(BuildContext context) {
    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Padding(
                padding: EdgeInsets.only(right: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '10:16 AM',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.done_all_rounded,
                      size: 13,
                      color: AppColors.primaryPurple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: NivaAvatar(
                name: otherUserName.isNotEmpty ? otherUserName : 'User',
                size: 26,
                backgroundColor: AppColors.servicesBg,
                textColor: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(18),
                      ),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      '10:14 AM',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
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
