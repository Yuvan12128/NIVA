import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing an in-app notification (`notifications/{notificationId}`).
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.type,
    required this.title,
    required this.body,
    required this.referenceId,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String recipientId;
  final String senderId;
  final String
  type; // 'connection_request' | 'connection_accepted' | 'new_message'
  final String title;
  final String body;
  final String referenceId;
  final bool isRead;
  final DateTime? createdAt;

  static const List<String> validTypes = [
    'connection_request',
    'connection_accepted',
    'new_message',
  ];

  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'type': type,
      'title': title,
      'body': body,
      'referenceId': referenceId,
      'isRead': isRead,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : (useServerTimestamp ? FieldValue.serverTimestamp() : null),
    };
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return NotificationModel(
      id: id,
      recipientId: map['recipientId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      type: map['type'] as String? ?? 'connection_request',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      referenceId: map['referenceId'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? type,
    String? title,
    String? body,
    String? referenceId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
