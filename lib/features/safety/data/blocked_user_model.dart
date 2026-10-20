import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a user block relation (`blocked_users/{blockId}`).
class BlockedUserModel {
  const BlockedUserModel({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    this.createdAt,
  });

  final String id;
  final String blockerId;
  final String blockedUserId;
  final DateTime? createdAt;

  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    return {
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : (useServerTimestamp ? FieldValue.serverTimestamp() : null),
    };
  }

  factory BlockedUserModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return BlockedUserModel(
      id: id,
      blockerId: map['blockerId'] as String? ?? '',
      blockedUserId: map['blockedUserId'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  BlockedUserModel copyWith({
    String? id,
    String? blockerId,
    String? blockedUserId,
    DateTime? createdAt,
  }) {
    return BlockedUserModel(
      id: id ?? this.id,
      blockerId: blockerId ?? this.blockerId,
      blockedUserId: blockedUserId ?? this.blockedUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
