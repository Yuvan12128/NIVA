import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_avatar.dart';
import '../../auth/data/auth_service.dart';
import '../../safety/data/safety_repository.dart';
import '../../safety/presentation/widgets/report_sheet.dart';
import '../data/chat_model.dart';
import '../data/chat_repository.dart';
import '../data/message_model.dart';

/// Apple-minimal 1-to-1 Conversation Screen.
/// Real-time Firestore message stream with Apple Blue sent bubbles and light grey received bubbles.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.chat,
    required this.otherUserName,
    required this.otherUserId,
    this.otherUserPhotoUrl,
    this.currentUserId,
    this.chatRepository,
    this.safetyRepository,
  });

  final ChatModel chat;
  final String otherUserName;
  final String otherUserId;
  final String? otherUserPhotoUrl;
  final String? currentUserId;
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

  String get _currentUserId =>
      widget.currentUserId ??
      AuthService.instance.currentUser?.uid ??
      'anonymous';

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
  }

  Future<void> _checkBlockStatus() async {
    final currentUid = _currentUserId;
    if (currentUid != 'anonymous') {
      final blocked = await _safetyRepo.isBlocked(
        userA: currentUid,
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
    final currentUid = _currentUserId;
    if (currentUid == 'anonymous') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Block ${widget.otherUserName}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'You will no longer be able to message each other or see connection requests.',
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
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Block'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await _safetyRepo.blockUser(
        blockerId: currentUid,
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
    final currentUid = _currentUserId;
    if (currentUid == 'anonymous') return;

    await _safetyRepo.unblockUser(
      blockerId: currentUid,
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

    final currentUid = _currentUserId;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatRepo.sendMessage(
        chatId: widget.chat.id,
        senderId: currentUid,
        receiverId: widget.otherUserId,
        text: text,
      );

      _textController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send message: ${e.toString().replaceAll("Exception: ", "").replaceAll("StateError: ", "")}',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
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
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 22,
            color: AppColors.appleTextPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            NivaAvatar(
              name: widget.otherUserName,
              imageUrl: widget.otherUserPhotoUrl,
              size: 36,
              backgroundColor: AppColors.appleSecondaryBg,
              textColor: AppColors.appleBlue,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34C759),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF34C759),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Connected',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF34C759),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
              Icons.call_outlined,
              color: AppColors.appleTextPrimary,
              size: 22,
            ),
            tooltip: 'Call',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling peer...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.appleTextPrimary,
              size: 22,
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
            itemBuilder:
                (context) => [
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
                            color: AppColors.appleBlue,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.8),
          child: Container(color: AppColors.appleBorder, height: 0.8),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages Stream
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatRepo.streamMessages(widget.chat.id, limit: 60),
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
                            AppColors.appleBlue,
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
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: AppColors.appleSecondaryBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppColors.appleBlue,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Say hello to ${widget.otherUserName} to start your conversation!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // 4. Message Bubble List (reverse: true)
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
                      final isMe = message.senderId == _currentUserId;
                      return _MessageBubble(
                        message: message,
                        isMe: isMe,
                        otherUserName: widget.otherUserName,
                        otherUserPhotoUrl: widget.otherUserPhotoUrl,
                      );
                    },
                  );
                },
              ),
            ),

            // Blocked Banner or Minimal Message Composer
            if (_isBlocked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.md,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.appleSecondaryBg,
                  border: Border(
                    top: BorderSide(color: AppColors.appleBorder, width: 0.8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.block_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Messaging is disabled because this user is blocked.',
                      style: TextStyle(
                        fontSize: 13,
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
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.pureWhite,
                  border: Border(
                    top: BorderSide(color: AppColors.appleBorder, width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: Color(0xFF8E8E93),
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: _textController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 4,
                          minLines: 1,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1C1C1E),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 9),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.appleBlue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isSending ? null : _sendMessage,
                        icon:
                            _isSending
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                  size: 20,
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.otherUserName = '',
    this.otherUserPhotoUrl,
  });

  final MessageModel message;
  final bool isMe;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  String _formatTimestamp(DateTime? date) {
    if (date == null) return '';
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTimestamp(message.createdAt);

    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.appleBlue, // #007AFF
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
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              ),
              if (timeStr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all_rounded,
                        size: 14,
                        color: AppColors.appleBlue,
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
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: const BoxDecoration(
                color: Color(0xFFE5E5EA), // Apple Light Grey
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),
            if (timeStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4),
                child: Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
