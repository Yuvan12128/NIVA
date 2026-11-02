import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/connection_request_repository.dart';

/// Pixel-perfect Connection Request Dialog matching Reference Design (Screen 9)
/// - Modal overlay with soft rounded corners (20px)
/// - Close button `X` on top right
/// - Centered Handshake icon in soft blue circle
/// - "Send Connection Request?" bold title
/// - "[User] will be notified and can start a chat with you."
/// - "Cancel" and "Send" action buttons
class ConnectionRequestDialog extends StatefulWidget {
  const ConnectionRequestDialog({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserPhotoUrl,
    this.connectionRequestRepository,
    this.onSentSuccess,
  });

  final String targetUserId;
  final String targetUserName;
  final String? targetUserPhotoUrl;
  final ConnectionRequestRepository? connectionRequestRepository;
  final VoidCallback? onSentSuccess;

  static Future<bool?> show(
    BuildContext context, {
    required String targetUserId,
    required String targetUserName,
    String? targetUserPhotoUrl,
    ConnectionRequestRepository? connectionRequestRepository,
    VoidCallback? onSentSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ConnectionRequestDialog(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        targetUserPhotoUrl: targetUserPhotoUrl,
        connectionRequestRepository: connectionRequestRepository,
        onSentSuccess: onSentSuccess,
      ),
    );
  }

  @override
  State<ConnectionRequestDialog> createState() => _ConnectionRequestDialogState();
}

class _ConnectionRequestDialogState extends State<ConnectionRequestDialog> {
  late final ConnectionRequestRepository _repo =
      widget.connectionRequestRepository ?? ConnectionRequestRepository();
  bool _isSending = false;

  Future<void> _handleSend() async {
    final currentUser = AuthService.instance.currentUser;
    final currentUid = currentUser?.uid;

    if (currentUid == null || currentUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to send connection requests.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(false);
      return;
    }

    if (currentUid == widget.targetUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot send a connection request to yourself.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isSending = true);

    try {
      await _repo.sendConnectRequest(
        fromUserId: currentUid,
        toUserId: widget.targetUserId,
        needId: 'direct_connection',
        fromUserName: currentUser?.displayName,
        fromUserPhotoUrl: currentUser?.photoURL,
        toUserName: widget.targetUserName,
      );

      if (mounted) {
        widget.onSentSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to ${widget.targetUserName}.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.appleBlue,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send connection request: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.appleSecondaryBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),

                // Blue Circle with Handshake Icon
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBF5FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.handshake_outlined,
                      size: 34,
                      color: AppColors.appleBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Dialog Title
                const Text(
                  'Send Connection Request?',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.appleTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Dialog Subtitle
                Text(
                  '${widget.targetUserName} will be notified and can start a chat with you.',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Action Buttons Row: Cancel vs Send
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.appleTextPrimary,
                            side: const BorderSide(
                              color: AppColors.appleBorder,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appleBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSending ? null : _handleSend,
                          child: _isSending
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
                              : const Text(
                                  'Send',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
