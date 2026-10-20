import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../notifications/data/notification_repository.dart';
import '../../safety/data/safety_repository.dart';
import 'connection_request_model.dart';

/// Lightweight repository for managing 1-to-1 connection requests.
/// Operations are strictly one-shot reads/writes with zero ongoing listeners.
class ConnectionRequestRepository {
  ConnectionRequestRepository({
    FirebaseFirestore? firestore,
    NotificationRepository? notificationRepository,
    SafetyRepository? safetyRepository,
  }) : _customFirestore = firestore,
       _customNotificationRepo = notificationRepository,
       _customSafetyRepo = safetyRepository;

  final FirebaseFirestore? _customFirestore;
  final NotificationRepository? _customNotificationRepo;
  final SafetyRepository? _customSafetyRepo;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  NotificationRepository get _notificationRepo =>
      _customNotificationRepo ??
      NotificationRepository(firestore: _customFirestore);

  SafetyRepository get _safetyRepo =>
      _customSafetyRepo ?? SafetyRepository(firestore: _customFirestore);

  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      _firestore.collection('connection_requests');

  /// Send a connection request to a candidate helper.
  /// Enforces self-request prevention, block prevention, and duplicate pending request prevention.
  Future<String> sendConnectRequest({
    required String fromUserId,
    required String toUserId,
    required String needId,
  }) async {
    // 1. Prevent self-requests
    if (fromUserId.isEmpty || toUserId.isEmpty) {
      throw ArgumentError('User IDs must not be empty.');
    }
    if (fromUserId == toUserId) {
      throw ArgumentError(
        'Users cannot send connection requests to themselves.',
      );
    }

    // 2. Prevent requests if either user has blocked the other
    final blocked = await _safetyRepo.isBlocked(
      userA: fromUserId,
      userB: toUserId,
    );
    if (blocked) {
      throw StateError(
        'Cannot send connection request because this user relationship is blocked.',
      );
    }

    try {
      // 2. Prevent duplicate pending requests for the same need & users
      final existing = await _requestsCollection
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('needId', isEqualTo: needId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint(
          'ConnectionRequestRepository: duplicate pending request detected.',
        );
        return existing.docs.first.id;
      }

      // 3. Create new connection request
      final docRef = _requestsCollection.doc();
      final request = ConnectionRequestModel(
        id: docRef.id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        needId: needId,
        status: 'pending',
      );

      await docRef.set(request.toMap(useServerTimestamp: true));

      // 4. Create in-app notification for the recipient
      try {
        await _notificationRepo.createNotification(
          recipientId: toUserId,
          senderId: fromUserId,
          type: 'connection_request',
          title: 'New Connection Request',
          body: 'Someone wants to connect regarding a shared need.',
          referenceId: docRef.id,
        );
      } catch (notifErr) {
        debugPrint('Notice: notification creation error: $notifErr');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('ConnectionRequestRepository.sendConnectRequest error: $e');
      rethrow;
    }
  }

  /// Helper responds to incoming connection request: 'accepted' or 'declined'.
  /// Enforces that only the recipient (toUserId) can respond.
  Future<void> respondToRequest({
    required String requestId,
    required String responderUserId,
    required String status,
  }) async {
    if (status != 'accepted' && status != 'declined') {
      throw ArgumentError('Status must be either "accepted" or "declined".');
    }

    try {
      final docSnapshot = await _requestsCollection.doc(requestId).get();
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        throw StateError('Connection request not found.');
      }

      final data = docSnapshot.data()!;
      final toUserId = data['toUserId'] as String? ?? '';

      if (toUserId != responderUserId) {
        throw StateError(
          'Only the recipient can respond to this connection request.',
        );
      }

      await _requestsCollection.doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If accepted, notify the original sender
      if (status == 'accepted') {
        try {
          final fromUserId = data['fromUserId'] as String? ?? '';
          if (fromUserId.isNotEmpty) {
            await _notificationRepo.createNotification(
              recipientId: fromUserId,
              senderId: responderUserId,
              type: 'connection_accepted',
              title: 'Connection Accepted!',
              body: 'Your connection request was accepted. You can now chat.',
              referenceId: requestId,
            );
          }
        } catch (notifErr) {
          debugPrint('Notice: notification creation error: $notifErr');
        }
      }
    } catch (e) {
      debugPrint('ConnectionRequestRepository.respondToRequest error: $e');
      rethrow;
    }
  }

  /// Get recipient IDs for requests already sent by user for this specific need.
  /// Used by MatchingSheet to immediately initialize "Request Sent" state without unbounded queries.
  Future<Set<String>> getSentRecipientIdsForNeed({
    required String fromUserId,
    required String needId,
  }) async {
    try {
      final snapshot = await _requestsCollection
          .where('fromUserId', isEqualTo: fromUserId)
          .where('needId', isEqualTo: needId)
          .limit(20)
          .get();

      final sentToUserIds = <String>{};
      for (final doc in snapshot.docs) {
        final toUser = doc.data()['toUserId'] as String?;
        if (toUser != null && toUser.isNotEmpty) {
          sentToUserIds.add(toUser);
        }
      }
      return sentToUserIds;
    } catch (e) {
      debugPrint(
        'ConnectionRequestRepository.getSentRecipientIdsForNeed notice: $e',
      );
      return const {};
    }
  }
}
