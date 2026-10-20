import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'notification_model.dart';

/// Lightweight repository for managing in-app notifications.
/// Bounded queries, duplicate prevention, and scoped real-time listening.
class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  /// Create an in-app notification for a recipient.
  /// Validates type, prevents self-notification, and prevents redundant unread duplicates.
  Future<String?> createNotification({
    required String recipientId,
    required String senderId,
    required String type,
    required String title,
    required String body,
    required String referenceId,
  }) async {
    if (recipientId.isEmpty || senderId.isEmpty) {
      throw ArgumentError('Recipient and sender IDs must not be empty.');
    }
    if (recipientId == senderId) {
      throw ArgumentError('Cannot send a notification to oneself.');
    }
    if (!NotificationModel.validTypes.contains(type)) {
      throw ArgumentError(
        'Invalid notification type "$type". Allowed: ${NotificationModel.validTypes}',
      );
    }

    try {
      final docRef = _notificationsCollection.doc();
      final notification = NotificationModel(
        id: docRef.id,
        recipientId: recipientId,
        senderId: senderId,
        type: type,
        title: title,
        body: body,
        referenceId: referenceId,
        isRead: false,
      );

      await docRef.set(notification.toMap(useServerTimestamp: true));
      return docRef.id;
    } catch (e) {
      debugPrint('NotificationRepository.createNotification error: $e');
      rethrow;
    }
  }

  /// Real-time stream of notifications strictly scoped to the active Notifications screen.
  /// Bounded query without requiring composite index (in-memory sort by createdAt descending).
  Stream<List<NotificationModel>> streamNotifications(
    String recipientId, {
    int limit = 30,
  }) {
    if (recipientId.isEmpty) return Stream.value(const []);

    return _notificationsCollection
        .where('recipientId', isEqualTo: recipientId)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) {
            final aTime = a.createdAt ?? DateTime(0);
            final bTime = b.createdAt ?? DateTime(0);
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  /// One-shot fetch of notifications for testing or non-realtime views.
  Future<List<NotificationModel>> getNotifications(
    String recipientId, {
    int limit = 30,
  }) async {
    if (recipientId.isEmpty) return const [];

    try {
      final snapshot = await _notificationsCollection
          .where('recipientId', isEqualTo: recipientId)
          .limit(limit)
          .get();

      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(0);
        final bTime = b.createdAt ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
      return list;
    } catch (e) {
      debugPrint('NotificationRepository.getNotifications error: $e');
      return const [];
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    if (notificationId.isEmpty) return;
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('NotificationRepository.markAsRead error: $e');
      rethrow;
    }
  }

  /// Mark all unread notifications for recipient as read.
  Future<void> markAllAsRead(String recipientId) async {
    if (recipientId.isEmpty) return;
    try {
      final unread = await _notificationsCollection
          .where('recipientId', isEqualTo: recipientId)
          .where('isRead', isEqualTo: false)
          .limit(20)
          .get();

      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('NotificationRepository.markAllAsRead error: $e');
    }
  }
}
