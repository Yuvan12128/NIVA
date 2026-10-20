import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a 1-to-1 connection request between a seeker and a helper.
/// Stored in Firestore at `connection_requests/{requestId}`.
class ConnectionRequestModel {
  const ConnectionRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.needId,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String needId;
  final String status; // 'pending' | 'accepted' | 'declined'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'needId': needId,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : (useServerTimestamp ? FieldValue.serverTimestamp() : null),
      'updatedAt': useServerTimestamp ? FieldValue.serverTimestamp() : null,
    };
  }

  factory ConnectionRequestModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return ConnectionRequestModel(
      id: id,
      fromUserId: map['fromUserId'] as String? ?? '',
      toUserId: map['toUserId'] as String? ?? '',
      needId: map['needId'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  ConnectionRequestModel copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? needId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConnectionRequestModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      needId: needId ?? this.needId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
