import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_avatar.dart';
import '../../auth/data/auth_service.dart';
import '../data/chat_model.dart';
import '../data/chat_repository.dart';
import 'conversation_screen.dart';

/// Conversations List Screen displaying active 1-to-1 chats.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.chatRepository});

  final ChatRepository? chatRepository;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatRepository _chatRepo =
      widget.chatRepository ?? ChatRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<ChatModel> _chats = [];

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = AuthService.instance.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) {
        setState(() {
          _chats = [];
          _isLoading = false;
        });
        return;
      }

      final chats = await _chatRepo.getUserChats(currentUserId, limit: 20);
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load chats.';
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chats', style: AppTextStyles.h2)),
      body: RefreshIndicator(
        onRefresh: _fetchChats,
        color: AppColors.primaryPurple,
        child: _buildBody(currentUserId),
      ),
    );
  }

  Widget _buildBody(String currentUserId) {
    // 1. Loading State
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
          ),
        ),
      );
    }

    // 2. Error State
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.textTertiary,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: _fetchChats, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    // 3. Empty State
    if (_chats.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.servicesBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryPurple,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('No conversations yet', style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'When you connect with people regarding a need, messages will appear here.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Conversation List
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: _chats.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppColors.borderSubtle, indent: 72),
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final otherId = chat.getOtherUserId(currentUserId);
        final otherName = chat.getOtherUserName(currentUserId);
        final lastMsg =
            (chat.lastMessage != null && chat.lastMessage!.isNotEmpty)
            ? chat.lastMessage!
            : 'Conversation started';
        final timeStr = _formatTime(chat.lastMessageAt ?? chat.createdAt);

        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConversationScreen(
                  chat: chat,
                  otherUserName: otherName,
                  otherUserId: otherId,
                  chatRepository: _chatRepo,
                ),
              ),
            ).then((_) => _fetchChats());
          },
          leading: NivaAvatar(
            name: otherName,
            size: 44,
            backgroundColor: AppColors.servicesBg,
            textColor: AppColors.primaryPurple,
          ),
          title: Text(
            otherName,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            lastMsg,
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            timeStr,
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        );
      },
    );
  }
}
