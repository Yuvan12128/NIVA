import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/data/auth_service.dart';
import '../data/notification_model.dart';
import '../data/notification_repository.dart';

/// Notifications Screen displaying in-app updates for connections and messages.
/// Uses a real-time listener strictly scoped to this screen lifecycle.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.notificationRepository});

  final NotificationRepository? notificationRepository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationRepository _notificationRepo =
      widget.notificationRepository ?? NotificationRepository();

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Just now';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }

  (IconData, Color, Color) _resolveTypeStyle(String type) {
    switch (type) {
      case 'connection_request':
        return (Icons.person_add_rounded, AppColors.helpIcon, AppColors.helpBg);
      case 'connection_accepted':
        return (
          Icons.check_circle_rounded,
          AppColors.primaryPurple,
          AppColors.servicesBg,
        );
      case 'new_message':
        return (
          Icons.chat_bubble_rounded,
          AppColors.infoIcon,
          AppColors.infoBg,
        );
      default:
        return (
          Icons.notifications_rounded,
          AppColors.primaryPurple,
          AppColors.servicesBg,
        );
    }
  }

  void _handleTap(NotificationModel notification) {
    if (!notification.isRead) {
      _notificationRepo.markAsRead(notification.id);
    }

    if (notification.type == 'new_message' ||
        notification.type == 'connection_accepted') {
      Navigator.pop(
        context,
      ); // Return to main navigation where chat tab is available
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: AppTextStyles.h2),
        actions: [
          if (currentUserId.isNotEmpty)
            TextButton(
              onPressed: () => _notificationRepo.markAllAsRead(currentUserId),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: currentUserId.isEmpty
          ? _buildEmptyState()
          : StreamBuilder<List<NotificationModel>>(
              stream: _notificationRepo.streamNotifications(
                currentUserId,
                limit: 30,
              ),
              builder: (context, snapshot) {
                // 1. Loading State
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

                // 2. Error State
                if (snapshot.hasError) {
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
                            'Unable to load notifications.',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final notifications = snapshot.data ?? const [];

                // 3. Empty State
                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                // 4. Notifications List
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: AppColors.borderSubtle,
                    indent: 68,
                  ),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    final (icon, iconColor, iconBg) = _resolveTypeStyle(
                      item.type,
                    );

                    return Material(
                      color: item.isRead
                          ? Colors.transparent
                          : AppColors.primaryPurple.withValues(alpha: 0.04),
                      child: InkWell(
                        onTap: () => _handleTap(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenHorizontal,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  fontWeight: item.isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          _formatTimeAgo(item.createdAt),
                                          style: AppTextStyles.captionSmall
                                              .copyWith(
                                                color: AppColors.textTertiary,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.body,
                                      style: AppTextStyles.captionSmall
                                          .copyWith(
                                            color: item.isRead
                                                ? AppColors.textSecondary
                                                : AppColors.textPrimary,
                                            fontSize: 13,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!item.isRead) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryPurple,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.servicesBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primaryPurple,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('No notifications yet', style: AppTextStyles.subtitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Updates on your connection requests and messages will appear here.',
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
}
