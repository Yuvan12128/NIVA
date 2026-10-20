import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a 1-to-1 conversation (`chats/{chatId}`).
class ChatModel {
  const ChatModel({
    required this.id,
    required this.participantIds,
    required this.needId,
    required this.connectionRequestId,
    this.lastMessage,
    this.lastMessageAt,
    this.participantNames,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final List<String> participantIds;
  final String needId;
  final String connectionRequestId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, String>? participantNames;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    return {
      'participantIds': participantIds,
      'needId': needId,
      'connectionRequestId': connectionRequestId,
      'lastMessage': lastMessage ?? '',
      if (participantNames != null) 'participantNames': participantNames,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : (useServerTimestamp ? FieldValue.serverTimestamp() : null),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : (useServerTimestamp ? FieldValue.serverTimestamp() : null),
      'updatedAt': useServerTimestamp ? FieldValue.serverTimestamp() : null,
    };
  }

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    final pList =
        (map['participantIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    final pNamesMap = (map['participantNames'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, v.toString()),
    );

    return ChatModel(
      id: id,
      participantIds: pList,
      needId: map['needId'] as String? ?? '',
      connectionRequestId: map['connectionRequestId'] as String? ?? '',
      lastMessage: map['lastMessage'] as String?,
      lastMessageAt: parseDate(map['lastMessageAt']),
      participantNames: pNamesMap,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  ChatModel copyWith({
    String? id,
    List<String>? participantIds,
    String? needId,
    String? connectionRequestId,
    String? lastMessage,
    DateTime? lastMessageAt,
    Map<String, String>? participantNames,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      needId: needId ?? this.needId,
      connectionRequestId: connectionRequestId ?? this.connectionRequestId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      participantNames: participantNames ?? this.participantNames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getOtherUserId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String getOtherUserName(String currentUserId, {String defaultName = 'User'}) {
    final otherId = getOtherUserId(currentUserId);
    if (participantNames != null && participantNames!.containsKey(otherId)) {
      return participantNames![otherId]!;
    }
    return defaultName;
  }
}
