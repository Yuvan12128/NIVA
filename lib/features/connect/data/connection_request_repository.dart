import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../auth/data/auth_service.dart';
import '../../chat/data/chat_repository.dart';
import '../../notifications/data/notification_repository.dart';
import '../../safety/data/safety_repository.dart';
import 'connection_request_model.dart';

/// Lightweight repository for managing 1-to-1 connection requests.
/// Enforces self-request prevention, block relationship prevention, and duplicate pending prevention.
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

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  NotificationRepository get _notificationRepo =>
      _customNotificationRepo ??
      NotificationRepository(firestore: _customFirestore);

  SafetyRepository get _safetyRepo =>
      _customSafetyRepo ?? SafetyRepository(firestore: _customFirestore);

  CollectionReference<Map<String, dynamic>>? get _requestsCollection =>
      _firestore?.collection('connection_requests');

  /// Send a connection request to a candidate peer or helper.
  /// Enforces self-request prevention, block prevention, and duplicate pending request prevention.
  Future<String> sendConnectRequest({
    required String fromUserId,
    required String toUserId,
    required String needId,
    String? fromUserName,
    String? fromUserPhotoUrl,
    String? fromUserProfession,
    String? toUserName,
  }) async {
    // 1. Prevent empty IDs
    if (fromUserId.isEmpty || toUserId.isEmpty) {
      throw ArgumentError('User IDs must not be empty.');
    }

    // 2. Prevent self-requests
    if (fromUserId == toUserId) {
      throw ArgumentError(
        'Users cannot send connection requests to themselves.',
      );
    }

    // 3. Prevent requests if either user has blocked the other
    final blocked = await _safetyRepo.isBlocked(
      userA: fromUserId,
      userB: toUserId,
    );
    if (blocked) {
      throw StateError(
        'Cannot send connection request because this user relationship is blocked.',
      );
    }

    final col = _requestsCollection;
    final effectiveNeedId =
        needId.trim().isNotEmpty ? needId.trim() : 'direct_connection';
    final docId = '${fromUserId}_${toUserId}_$effectiveNeedId';

    if (col == null) {
      return docId;
    }

    try {
      // 4. Prevent duplicate pending requests using deterministic doc ID
      final existingDoc = await col.doc(docId).get();
      if (existingDoc.exists && existingDoc.data()?['status'] == 'pending') {
        debugPrint(
          'ConnectionRequestRepository: duplicate pending request detected.',
        );
        return docId;
      }

      // 5. Create new connection request
      final docRef = col.doc(docId);
      final request = ConnectionRequestModel(
        id: docId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        needId: effectiveNeedId,
        status: 'pending',
        fromUserName: fromUserName,
        fromUserPhotoUrl: fromUserPhotoUrl,
        fromUserProfession: fromUserProfession,
        toUserName: toUserName,
      );

      await docRef.set(request.toMap(useServerTimestamp: true));

      // 6. Create in-app notification for the recipient
      try {
        final senderDisplayName = fromUserName ??
            (AuthService.instance.currentUser?.displayName?.isNotEmpty == true
                ? AuthService.instance.currentUser!.displayName!
                : 'A peer');

        await _notificationRepo.createNotification(
          recipientId: toUserId,
          senderId: fromUserId,
          type: 'connection_request',
          title: 'New Connection Request',
          body: '$senderDisplayName wants to connect with you.',
          referenceId: docId,
        );
      } catch (notifErr) {
        debugPrint('Notice: notification creation error: $notifErr');
      }

      return docId;
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

    final col = _requestsCollection;
    if (col == null) return;

    try {
      final docSnapshot = await col.doc(requestId).get();
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

      await col.doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If accepted, initialize chat and notify the original sender
      if (status == 'accepted') {
        final fromUserId = data['fromUserId'] as String? ?? '';
        final needId = data['needId'] as String? ?? '';
        final fromUserName = data['fromUserName'] as String?;
        final toUserName = data['toUserName'] as String?;

        if (fromUserId.isNotEmpty) {
          // Initialize chat immediately
          try {
            final chatRepo = ChatRepository(
              firestore: _firestore,
              notificationRepository: _notificationRepo,
              safetyRepository: _safetyRepo,
            );
            final namesMap = <String, String>{};
            if (fromUserName != null && fromUserName.isNotEmpty) {
              namesMap[fromUserId] = fromUserName;
            }
            if (toUserName != null && toUserName.isNotEmpty) {
              namesMap[responderUserId] = toUserName;
            }

            await chatRepo.getOrCreateChat(
              connectionRequestId: requestId,
              needId: needId,
              user1: fromUserId,
              user2: responderUserId,
              participantNames: namesMap.isNotEmpty ? namesMap : null,
            );
          } catch (chatErr) {
            debugPrint('Notice: chat creation error: $chatErr');
          }

          try {
            await _notificationRepo.createNotification(
              recipientId: fromUserId,
              senderId: responderUserId,
              type: 'connection_accepted',
              title: 'Connection Accepted!',
              body: 'Your connection request was accepted. You can now chat.',
              referenceId: requestId,
            );
          } catch (notifErr) {
            debugPrint('Notice: notification creation error: $notifErr');
          }
        }
      }
    } catch (e) {
      debugPrint('ConnectionRequestRepository.respondToRequest error: $e');
      rethrow;
    }
  }

  /// Stream incoming pending requests for user (real-time).
  Stream<List<ConnectionRequestModel>> streamIncomingRequests(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    final col = _requestsCollection;
    if (col == null) return Stream.value(const []);

    return col
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ConnectionRequestModel.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) {
            final tA = a.createdAt ?? DateTime(2000);
            final tB = b.createdAt ?? DateTime(2000);
            return tB.compareTo(tA);
          });
          return list;
        });
  }

  /// One-shot fetch for incoming pending requests.
  Future<List<ConnectionRequestModel>> getIncomingRequests(String userId) async {
    if (userId.isEmpty) return const [];
    final col = _requestsCollection;
    if (col == null) return const [];

    try {
      final snapshot = await col
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final list = snapshot.docs
          .map((doc) => ConnectionRequestModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) {
        final tA = a.createdAt ?? DateTime(2000);
        final tB = b.createdAt ?? DateTime(2000);
        return tB.compareTo(tA);
      });
      return list;
    } catch (e) {
      debugPrint('ConnectionRequestRepository.getIncomingRequests error: $e');
      return const [];
    }
  }

  /// Stream sent requests by user (pending, accepted, or declined).
  Stream<List<ConnectionRequestModel>> streamSentRequests(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    final col = _requestsCollection;
    if (col == null) return Stream.value(const []);

    return col
        .where('fromUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ConnectionRequestModel.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) {
            final tA = a.updatedAt ?? a.createdAt ?? DateTime(2000);
            final tB = b.updatedAt ?? b.createdAt ?? DateTime(2000);
            return tB.compareTo(tA);
          });
          return list;
        });
  }

  /// One-shot fetch for sent requests.
  Future<List<ConnectionRequestModel>> getSentRequests(String userId) async {
    if (userId.isEmpty) return const [];
    final col = _requestsCollection;
    if (col == null) return const [];

    try {
      final snapshot = await col
          .where('fromUserId', isEqualTo: userId)
          .get();

      final list = snapshot.docs
          .map((doc) => ConnectionRequestModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) {
        final tA = a.updatedAt ?? a.createdAt ?? DateTime(2000);
        final tB = b.updatedAt ?? b.createdAt ?? DateTime(2000);
        return tB.compareTo(tA);
      });
      return list;
    } catch (e) {
      debugPrint('ConnectionRequestRepository.getSentRequests error: $e');
      return const [];
    }
  }

  /// Retrieve the active or most recent connection request between two users.
  Future<ConnectionRequestModel?> getConnectionRequestBetween({
    required String userA,
    required String userB,
  }) async {
    if (userA.isEmpty || userB.isEmpty) return null;
    final col = _requestsCollection;
    if (col == null) return null;

    try {
      // 1. Check A -> B
      final snapA = await col
          .where('fromUserId', isEqualTo: userA)
          .where('toUserId', isEqualTo: userB)
          .limit(5)
          .get();

      // 2. Check B -> A
      final snapB = await col
          .where('fromUserId', isEqualTo: userB)
          .where('toUserId', isEqualTo: userA)
          .limit(5)
          .get();

      final allDocs = [...snapA.docs, ...snapB.docs];
      if (allDocs.isEmpty) return null;

      final requests = allDocs
          .map((doc) => ConnectionRequestModel.fromMap(doc.id, doc.data()))
          .toList();

      // Prioritize accepted first, then pending, then most recently updated
      requests.sort((a, b) {
        if (a.status == 'accepted' && b.status != 'accepted') return -1;
        if (b.status == 'accepted' && a.status != 'accepted') return 1;
        if (a.status == 'pending' && b.status != 'pending') return -1;
        if (b.status == 'pending' && a.status != 'pending') return 1;

        final tA = a.updatedAt ?? a.createdAt ?? DateTime(2000);
        final tB = b.updatedAt ?? b.createdAt ?? DateTime(2000);
        return tB.compareTo(tA);
      });

      return requests.first;
    } catch (e) {
      debugPrint(
        'ConnectionRequestRepository.getConnectionRequestBetween notice: $e',
      );
      return null;
    }
  }

  /// Get recipient IDs for requests already sent by user for this specific need.
  /// Used by MatchingSheet to immediately initialize "Request Sent" state without unbounded queries.
  Future<Set<String>> getSentRecipientIdsForNeed({
    required String fromUserId,
    required String needId,
  }) async {
    final col = _requestsCollection;
    if (col == null) return const {};

    try {
      final snapshot = await col
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
