import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a verified connection review (`reviews/{reviewId}`).
class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.connectionRequestId,
    required this.needId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.reviewText,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String connectionRequestId;
  final String needId;
  final String reviewerId;
  final String revieweeId;
  final int rating; // 1 to 5
  final String? reviewText;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    return {
      'connectionRequestId': connectionRequestId,
      'needId': needId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : (useServerTimestamp ? FieldValue.serverTimestamp() : null),
      'updatedAt': useServerTimestamp ? FieldValue.serverTimestamp() : null,
    };
  }

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return ReviewModel(
      id: id,
      connectionRequestId: map['connectionRequestId'] as String? ?? '',
      needId: map['needId'] as String? ?? '',
      reviewerId: map['reviewerId'] as String? ?? '',
      revieweeId: map['revieweeId'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      reviewText: map['reviewText'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  ReviewModel copyWith({
    String? id,
    String? connectionRequestId,
    String? needId,
    String? reviewerId,
    String? revieweeId,
    int? rating,
    String? reviewText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      connectionRequestId: connectionRequestId ?? this.connectionRequestId,
      needId: needId ?? this.needId,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
