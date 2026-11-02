import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/niva_avatar.dart';
import '../../auth/data/auth_service.dart';
import '../../connect/data/connection_request_model.dart';
import '../../connect/data/connection_request_repository.dart';
import '../data/chat_model.dart';
import '../data/chat_repository.dart';
import 'conversation_screen.dart';

/// Apple-minimal Chat & Connections Hub.
/// Supports 1-to-1 active messaging, viewing incoming connection requests (with Accept/Decline),
/// and viewing sent request status.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.chatRepository,
    this.connectionRequestRepository,
    this.currentUserId,
  });

  final ChatRepository? chatRepository;
  final ConnectionRequestRepository? connectionRequestRepository;
  final String? currentUserId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatRepository _chatRepo =
      widget.chatRepository ?? ChatRepository();
  late final ConnectionRequestRepository _connectionRepo =
      widget.connectionRequestRepository ?? ConnectionRequestRepository();

  int _selectedTab = 0; // 0 = Chats, 1 = Requests
  bool _isLoading = true;
  String? _errorMessage;
  List<ChatModel> _chats = [];
  List<ConnectionRequestModel> _incomingRequests = [];
  List<ConnectionRequestModel> _sentRequests = [];
  final Set<String> _processingRequestIds = {};

  String get _effectiveCurrentUserId =>
      widget.currentUserId ?? AuthService.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentUid = _effectiveCurrentUserId;
    if (currentUid.isEmpty) {
      if (mounted) {
        setState(() {
          _chats = [];
          _incomingRequests = [];
          _sentRequests = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final chatsFuture = _chatRepo.getUserChats(currentUid, limit: 30);
      final incomingFuture = _connectionRepo.getIncomingRequests(currentUid);
      final sentFuture = _connectionRepo.getSentRequests(currentUid);

      final results = await Future.wait([
        chatsFuture,
        incomingFuture,
        sentFuture,
      ]);

      if (!mounted) return;
      setState(() {
        _chats = results[0] as List<ChatModel>;
        _incomingRequests = results[1] as List<ConnectionRequestModel>;
        _sentRequests = results[2] as List<ConnectionRequestModel>;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load chats and connections.';
      });
    }
  }

  Future<void> _respondToRequest(
    ConnectionRequestModel request,
    String status,
  ) async {
    final currentUid = _effectiveCurrentUserId;
    if (currentUid.isEmpty) return;

    setState(() {
      _processingRequestIds.add(request.id);
    });

    try {
      await _connectionRepo.respondToRequest(
        requestId: request.id,
        responderUserId: currentUid,
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? 'Connection accepted! You can now chat.'
                  : 'Connection request declined.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingRequestIds.remove(request.id);
        });
      }
    }
  }

  void _openChatWithUser({
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhotoUrl,
    String? connectionRequestId,
  }) async {
    final currentUid = _effectiveCurrentUserId;
    if (currentUid.isEmpty) return;

    try {
      final chat = await _chatRepo.getOrCreateChat(
        connectionRequestId: connectionRequestId ?? '',
        needId: 'direct_connection',
        user1: currentUid,
        user2: otherUserId,
        participantNames: {
          otherUserId: otherUserName,
        },
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ConversationScreen(
                chat: chat,
                otherUserName: otherUserName,
                otherUserId: otherUserId,
                otherUserPhotoUrl: otherUserPhotoUrl,
                currentUserId: currentUid,
                chatRepository: _chatRepo,
              ),
        ),
      ).then((_) => _loadData());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open conversation: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              _buildSegmentedSwitcher(),
              const SizedBox(height: 8),
              Container(color: AppColors.appleBorder, height: 0.8),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.appleBlue,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildSegmentedSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.appleSecondaryBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentButton(
                label: 'Chats',
                count: _chats.length,
                isSelected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
            ),
            Expanded(
              child: _buildSegmentButton(
                label: 'Requests',
                count: _incomingRequests.length,
                isSelected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
                highlightBadge: _incomingRequests.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    bool highlightBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow:
              isSelected
                  ? const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color:
                      highlightBadge ? AppColors.appleBlue : AppColors.appleBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: highlightBadge ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.appleBlue),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appleBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedTab == 0) {
      return _buildChatsList();
    } else {
      return _buildRequestsList();
    }
  }

  Widget _buildChatsList() {
    final currentUid = _effectiveCurrentUserId;

    if (_chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.appleSecondaryBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.appleBlue,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No conversations yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'When your connection requests are accepted, your conversations will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _chats.length,
      separatorBuilder:
          (context, index) => const Divider(
            height: 1,
            color: AppColors.appleBorder,
            indent: 74,
          ),
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final otherId = chat.getOtherUserId(currentUid);
        final otherName = chat.getOtherUserName(currentUid);
        final lastMsg =
            (chat.lastMessage != null && chat.lastMessage!.isNotEmpty)
                ? chat.lastMessage!
                : 'Connection accepted. Say hello!';
        final timeStr = _formatTime(chat.lastMessageAt ?? chat.createdAt);

        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ConversationScreen(
                      chat: chat,
                      otherUserName: otherName,
                      otherUserId: otherId,
                      currentUserId: currentUid,
                      chatRepository: _chatRepo,
                    ),
              ),
            ).then((_) => _loadData());
          },
          leading: NivaAvatar(
            name: otherName,
            size: 46,
            backgroundColor: AppColors.appleSecondaryBg,
            textColor: AppColors.appleBlue,
          ),
          title: Text(
            otherName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            lastMsg,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            timeStr,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    if (_incomingRequests.isEmpty && _sentRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.appleSecondaryBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  color: AppColors.appleBlue,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No connection requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Discover community members to send and receive connection requests.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      children: [
        // 1. Incoming Requests Section
        if (_incomingRequests.isNotEmpty) ...[
          const Text(
            'INCOMING REQUESTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ..._incomingRequests.map((req) => _buildIncomingRequestCard(req)),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 2. Sent Requests Section
        if (_sentRequests.isNotEmpty) ...[
          const Text(
            'SENT REQUESTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ..._sentRequests.map((req) => _buildSentRequestCard(req)),
        ],
      ],
    );
  }

  Widget _buildIncomingRequestCard(ConnectionRequestModel req) {
    final senderName =
        req.fromUserName?.isNotEmpty == true ? req.fromUserName! : 'Peer User';
    final profession = req.fromUserProfession ?? 'Community Member';
    final isProcessing = _processingRequestIds.contains(req.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.appleBorder, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NivaAvatar(
                name: senderName,
                imageUrl: req.fromUserPhotoUrl,
                size: 42,
                backgroundColor: AppColors.appleSecondaryBg,
                textColor: AppColors.appleBlue,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profession,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.appleBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed:
                        isProcessing
                            ? null
                            : () => _respondToRequest(req, 'accepted'),
                    child:
                        isProcessing
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.appleBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed:
                        isProcessing
                            ? null
                            : () => _respondToRequest(req, 'declined'),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentRequestCard(ConnectionRequestModel req) {
    final toName =
        req.toUserName?.isNotEmpty == true ? req.toUserName! : 'Peer User';
    final status = req.status;

    Color badgeColor;
    Color badgeTextColor;
    String statusLabel;

    switch (status) {
      case 'accepted':
        badgeColor = const Color(0xFFE8F5E9);
        badgeTextColor = const Color(0xFF2E7D32);
        statusLabel = 'Connected';
        break;
      case 'declined':
        badgeColor = const Color(0xFFFFEBEE);
        badgeTextColor = const Color(0xFFC62828);
        statusLabel = 'Declined';
        break;
      default:
        badgeColor = const Color(0xFFE3F2FD);
        badgeTextColor = AppColors.appleBlue;
        statusLabel = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.appleBorder, width: 0.8),
      ),
      child: Row(
        children: [
          NivaAvatar(
            name: toName,
            size: 38,
            backgroundColor: AppColors.appleSecondaryBg,
            textColor: AppColors.appleBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(req.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (status == 'accepted')
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.appleBlue,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Chat'),
              onPressed:
                  () => _openChatWithUser(
                    otherUserId: req.toUserId,
                    otherUserName: toName,
                    connectionRequestId: req.id,
                  ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
