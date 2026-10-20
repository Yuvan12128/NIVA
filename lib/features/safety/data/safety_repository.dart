import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'blocked_user_model.dart';
import 'report_model.dart';

/// Lightweight repository handling user blocking and reporting (Safety V1).
/// Uses deterministic document IDs and bounded queries to minimize Firestore reads.
class SafetyRepository {
  SafetyRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore? get _db {
    if (firestore != null) return firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _blockedCollection =>
      _db?.collection('blocked_users');

  CollectionReference<Map<String, dynamic>>? get _reportsCollection =>
      _db?.collection('reports');

  /// Canonical document ID for a block relationship.
  static String generateBlockDocId(String blockerId, String blockedUserId) =>
      '${blockerId.trim()}_${blockedUserId.trim()}';

  /// Canonical document ID for a report to idempotently prevent duplicate reports
  /// without requiring an unauthorized read query on the reports collection.
  static String generateReportDocId(
    String reporterId,
    String reportedUserId, [
    String? referenceId,
  ]) {
    final ref = (referenceId != null && referenceId.trim().isNotEmpty)
        ? referenceId.trim()
        : 'general';
    return '${reporterId.trim()}_${reportedUserId.trim()}_$ref';
  }

  /// In-memory session cache of blocked user IDs by blocker UID.
  static final Map<String, Set<String>> _sessionBlockedCache = {};

  /// Allowed report reasons list.
  static const Set<String> allowedReasons = {
    'spam',
    'harassment',
    'inappropriate_content',
    'scam',
    'fake_profile',
    'other',
  };

  /// Clears in-memory session cache (useful for testing and account sign-out).
  static void clearCache() {
    _sessionBlockedCache.clear();
  }

  /// Block another user.
  /// Enforces self-block prevention, deterministic document IDs, and duplicate prevention.
  Future<String> blockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    final bId = blockerId.trim();
    final targetId = blockedUserId.trim();

    if (bId.isEmpty || targetId.isEmpty) {
      throw ArgumentError('Blocker and blocked user IDs must not be empty.');
    }
    if (bId == targetId) {
      throw ArgumentError('Users cannot block themselves.');
    }

    final docId = generateBlockDocId(bId, targetId);
    _sessionBlockedCache.putIfAbsent(bId, () => <String>{}).add(targetId);

    try {
      final col = _blockedCollection;
      if (col != null) {
        final docRef = col.doc(docId);
        final existing = await docRef.get();
        if (!existing.exists) {
          final model = BlockedUserModel(
            id: docId,
            blockerId: bId,
            blockedUserId: targetId,
          );
          await docRef.set(model.toMap(useServerTimestamp: true));
        }
      }
      return docId;
    } catch (e) {
      debugPrint('SafetyRepository.blockUser notice: $e');
      return docId;
    }
  }

  /// Unblock a previously blocked user.
  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    final bId = blockerId.trim();
    final targetId = blockedUserId.trim();

    if (bId.isEmpty || targetId.isEmpty) {
      throw ArgumentError('Blocker and blocked user IDs must not be empty.');
    }

    _sessionBlockedCache[bId]?.remove(targetId);

    try {
      final col = _blockedCollection;
      if (col != null) {
        final docId = generateBlockDocId(bId, targetId);
        await col.doc(docId).delete();
      }
    } catch (e) {
      debugPrint('SafetyRepository.unblockUser notice: $e');
    }
  }

  /// Check if a block relationship exists between two users in either direction.
  Future<bool> isBlocked({required String userA, required String userB}) async {
    final a = userA.trim();
    final b = userB.trim();

    if (a.isEmpty || b.isEmpty || a == b) return false;

    // 1. Check in-memory cache
    if (_sessionBlockedCache[a]?.contains(b) == true) return true;
    if (_sessionBlockedCache[b]?.contains(a) == true) return true;

    // 2. Perform point lookups on canonical doc IDs
    try {
      final col = _blockedCollection;
      if (col != null) {
        final docAtoB = await col.doc(generateBlockDocId(a, b)).get();
        if (docAtoB.exists) {
          _sessionBlockedCache.putIfAbsent(a, () => <String>{}).add(b);
          return true;
        }

        final docBtoA = await col.doc(generateBlockDocId(b, a)).get();
        if (docBtoA.exists) {
          _sessionBlockedCache.putIfAbsent(b, () => <String>{}).add(a);
          return true;
        }
      }
    } catch (e) {
      debugPrint('SafetyRepository.isBlocked notice: $e');
    }

    return false;
  }

  /// Get the set of user IDs blocked by the specified user (and those who blocked them).
  Future<Set<String>> getBlockedUserIds(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) return const {};

    final cached = _sessionBlockedCache[uid];
    if (cached != null && cached.isNotEmpty) {
      return Set<String>.from(cached);
    }

    final Set<String> blockedIds = {};
    try {
      final col = _blockedCollection;
      if (col != null) {
        // 1. Users blocked by this user
        final outgoing = await col
            .where('blockerId', isEqualTo: uid)
            .limit(50)
            .get();

        for (final doc in outgoing.docs) {
          final target = doc.data()['blockedUserId'] as String?;
          if (target != null && target.isNotEmpty) {
            blockedIds.add(target);
          }
        }

        // 2. Users who blocked this user
        final incoming = await col
            .where('blockedUserId', isEqualTo: uid)
            .limit(50)
            .get();

        for (final doc in incoming.docs) {
          final blocker = doc.data()['blockerId'] as String?;
          if (blocker != null && blocker.isNotEmpty) {
            blockedIds.add(blocker);
          }
        }
      }
    } catch (e) {
      debugPrint('SafetyRepository.getBlockedUserIds notice: $e');
    }

    _sessionBlockedCache[uid] = Set<String>.from(blockedIds);
    return blockedIds;
  }

  /// Submit a user safety report.
  Future<String> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
    String? referenceId,
  }) async {
    final repId = reporterId.trim();
    final targetId = reportedUserId.trim();
    final cleanReason = reason.trim().toLowerCase();

    // 1. Validations
    if (repId.isEmpty || targetId.isEmpty) {
      throw ArgumentError('Reporter and reported user IDs must not be empty.');
    }
    if (repId == targetId) {
      throw ArgumentError('Users cannot report themselves.');
    }
    if (!allowedReasons.contains(cleanReason)) {
      throw ArgumentError(
        'Invalid report reason "$reason". Allowed: ${allowedReasons.join(', ')}',
      );
    }
    if (description != null && description.trim().length > 500) {
      throw ArgumentError('Report description must be 500 characters or less.');
    }

    final docId = generateReportDocId(repId, targetId, referenceId);

    try {
      final col = _reportsCollection;
      if (col != null) {
        final docRef = col.doc(docId);
        final report = ReportModel(
          id: docId,
          reporterId: repId,
          reportedUserId: targetId,
          reason: cleanReason,
          description: description?.trim(),
          referenceId: referenceId?.trim(),
          status: 'submitted',
        );

        await docRef.set(report.toMap(useServerTimestamp: true));
        return docId;
      }
      return docId;
    } catch (e) {
      debugPrint('SafetyRepository.reportUser notice: $e');
      return docId;
    }
  }
}
