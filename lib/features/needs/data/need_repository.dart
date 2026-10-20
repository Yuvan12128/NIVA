import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'need_model.dart';

/// Lightweight Firestore repository handling needs & capabilities (`needs` collection).
class NeedRepository {
  NeedRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _needsCollection =>
      _firestore.collection('needs');

  // In-memory cache to conserve Firestore read quota on the free tier
  static List<NeedModel>? _cachedRecentNeeds;
  static DateTime? _recentNeedsTimestamp;
  static const Duration _cacheTtl = Duration(seconds: 60);

  /// Invalidate recent needs cache (e.g. after publishing or on pull-to-refresh)
  static void clearRecentNeedsCache() {
    _cachedRecentNeeds = null;
    _recentNeedsTimestamp = null;
  }

  /// Publish a new need or help offer to Firestore.
  /// Uses server-side timestamps for consistency.
  Future<String> createNeed(NeedModel need) async {
    try {
      final docRef = need.needId.isNotEmpty
          ? _needsCollection.doc(need.needId)
          : _needsCollection.doc();

      final data = need.toMap(useServerTimestamp: true);
      await docRef.set(data);
      clearRecentNeedsCache();
      return docRef.id;
    } catch (e) {
      debugPrint('NeedRepository.createNeed error: $e');
      rethrow;
    }
  }

  /// Update targeted fields of an existing need.
  Future<void> updateNeed(String needId, Map<String, dynamic> data) async {
    try {
      final updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _needsCollection.doc(needId).update(updateData);
    } catch (e) {
      debugPrint('NeedRepository.updateNeed error: $e');
      rethrow;
    }
  }

  /// Delete a need document.
  Future<void> deleteNeed(String needId) async {
    try {
      await _needsCollection.doc(needId).delete();
    } catch (e) {
      debugPrint('NeedRepository.deleteNeed error: $e');
      rethrow;
    }
  }

  /// Fetch needs created by a specific user with pagination support.
  Future<List<NeedModel>> getUserNeeds(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _needsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NeedModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);
    } catch (e) {
      debugPrint('NeedRepository.getUserNeeds error: $e');
      return const [];
    }
  }

  /// Real-time stream of recent needs with a strict query limit.
  Stream<List<NeedModel>> streamRecentNeeds({int limit = 10}) {
    return _needsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NeedModel.fromMap(doc.id, doc.data()))
              .toList(growable: false),
        )
        .handleError((dynamic error) {
          debugPrint('NeedRepository.streamRecentNeeds error: $error');
          return const <NeedModel>[];
        });
  }

  /// One-shot fetch for recent needs (with 60s in-memory caching to save Firestore free quota).
  Future<List<NeedModel>> getRecentNeeds({
    int limit = 10,
    DocumentSnapshot? startAfter,
    bool forceRefresh = false,
  }) async {
    // Return cached items if available and valid
    if (startAfter == null &&
        !forceRefresh &&
        _cachedRecentNeeds != null &&
        _recentNeedsTimestamp != null &&
        DateTime.now().difference(_recentNeedsTimestamp!) < _cacheTtl) {
      return _cachedRecentNeeds!;
    }

    try {
      Query<Map<String, dynamic>> query = _needsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final results = snapshot.docs
          .map((doc) => NeedModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);

      if (startAfter == null) {
        _cachedRecentNeeds = results;
        _recentNeedsTimestamp = DateTime.now();
      }

      return results;
    } catch (e) {
      debugPrint('NeedRepository.getRecentNeeds error: $e');
      return const [];
    }
  }

  /// Fetch needs filtered by category with pagination.
  Future<List<NeedModel>> getNeedsByCategory(
    String category, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _needsCollection
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NeedModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);
    } catch (e) {
      debugPrint('NeedRepository.getNeedsByCategory error: $e');
      return const [];
    }
  }

  /// Fetch needs with optional category/type filters for discovery.
  Future<List<NeedModel>> getDiscoverableNeeds({
    String? category,
    String? type,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _needsCollection;

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      if (type != null && type.isNotEmpty) {
        query = query.where('type', isEqualTo: type);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NeedModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);
    } catch (e) {
      debugPrint('NeedRepository.getDiscoverableNeeds error: $e');
      return const [];
    }
  }
}
