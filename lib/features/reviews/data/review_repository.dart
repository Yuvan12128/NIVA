import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'review_model.dart';

/// Lightweight repository for managing verified connection reviews and trust score updates.
class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviewsCollection =>
      _firestore.collection('reviews');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Pure, deterministic trust score calculation from received ratings.
  /// Standard 1–5 star mapping to a 0–100 score:
  /// 5.0 -> 100, 4.5 -> 90, 4.0 -> 80, 3.0 -> 60, etc.
  /// Returns 100 as base score when no ratings exist.
  static int calculateTrustScore(List<int> ratings) {
    if (ratings.isEmpty) return 100;
    final total = ratings.reduce((a, b) => a + b);
    final average = total / ratings.length;
    return (average * 20).round().clamp(0, 100);
  }

  /// Submit a review for a completed connection.
  /// Enforces self-review prevention, rating boundaries, and duplicate prevention.
  /// Updates the reviewee's trust score deterministically.
  Future<String> submitReview({
    required String connectionRequestId,
    required String needId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    String? reviewText,
  }) async {
    // 1. Validation
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5.');
    }
    if (reviewerId.isEmpty || revieweeId.isEmpty) {
      throw ArgumentError('User IDs must not be empty.');
    }
    if (reviewerId == revieweeId) {
      throw ArgumentError('Users cannot review themselves.');
    }
    if (reviewText != null && reviewText.length > 500) {
      throw ArgumentError('Review text must be 500 characters or less.');
    }

    try {
      // 2. Prevent duplicate reviews by the same user for this connection
      final existing = await _reviewsCollection
          .where('connectionRequestId', isEqualTo: connectionRequestId)
          .where('reviewerId', isEqualTo: reviewerId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw StateError(
          'A review has already been submitted for this connection.',
        );
      }

      // 3. Write review document
      final docRef = _reviewsCollection.doc();
      final review = ReviewModel(
        id: docRef.id,
        connectionRequestId: connectionRequestId,
        needId: needId,
        reviewerId: reviewerId,
        revieweeId: revieweeId,
        rating: rating,
        reviewText: reviewText?.trim(),
      );

      await docRef.set(review.toMap(useServerTimestamp: true));

      // 4. Update the reviewee's trustScore safely
      try {
        final recentReviewsSnapshot = await _reviewsCollection
            .where('revieweeId', isEqualTo: revieweeId)
            .limit(25)
            .get();

        final allRatings = recentReviewsSnapshot.docs.map((d) {
          final r = (d.data()['rating'] as num?)?.toInt() ?? 5;
          return r.clamp(1, 5);
        }).toList();

        final updatedTrustScore = calculateTrustScore(allRatings);

        await _usersCollection.doc(revieweeId).update({
          'trustScore': updatedTrustScore,
          'lastReviewId': docRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (trustUpdateError) {
        debugPrint(
          'Notice: reviewee trustScore update error: $trustUpdateError',
        );
      }

      return docRef.id;
    } catch (e) {
      debugPrint('ReviewRepository.submitReview error: $e');
      rethrow;
    }
  }

  /// Get verified reviews received by a user (one-shot fetch with limit).
  Future<List<ReviewModel>> getUserReviews(
    String revieweeId, {
    int limit = 20,
  }) async {
    if (revieweeId.isEmpty) return const [];

    try {
      final snapshot = await _reviewsCollection
          .where('revieweeId', isEqualTo: revieweeId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);
    } catch (e) {
      debugPrint('ReviewRepository.getUserReviews error: $e');
      return const [];
    }
  }
}
