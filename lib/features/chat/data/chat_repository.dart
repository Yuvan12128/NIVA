import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../notifications/data/notification_repository.dart';
import '../../safety/data/safety_repository.dart';
import 'chat_model.dart';
import 'message_model.dart';

/// Lightweight repository handling 1-to-1 private chat messaging.
/// Follows deterministic chat IDs to prevent duplicates.
/// Uses a real-time listener ONLY for the active conversation messages.
class ChatRepository {
  ChatRepository({
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

  CollectionReference<Map<String, dynamic>>? get _chatsCollection =>
      _firestore?.collection('chats');

  CollectionReference<Map<String, dynamic>>? get _messagesCollection =>
      _firestore?.collection('messages');

  /// Generate a deterministic, canonical 1-to-1 chat ID from two participant UIDs.
  /// Guarantees the same chat document ID regardless of which user initiates.
  static String generateChatId(String user1, String user2) {
    if (user1.isEmpty || user2.isEmpty) {
      throw ArgumentError('Participant IDs cannot be empty.');
    }
    if (user1 == user2) {
      throw ArgumentError('Chat participants must be different users.');
    }
    final sorted = [user1.trim(), user2.trim()]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Retrieve or create the unique 1-to-1 chat for two users associated with an accepted connection.
  Future<ChatModel> getOrCreateChat({
    required String connectionRequestId,
    required String needId,
    required String user1,
    required String user2,
    Map<String, String>? participantNames,
  }) async {
    final chatId = generateChatId(user1, user2);
    final sortedParticipants = [user1.trim(), user2.trim()]..sort();
    final defaultChat = ChatModel(
      id: chatId,
      participantIds: sortedParticipants,
      needId: needId,
      connectionRequestId: connectionRequestId,
      lastMessage: '',
      participantNames: participantNames,
    );

    final col = _chatsCollection;
    if (col == null) return defaultChat;

    final docRef = col.doc(chatId);

    try {
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        return ChatModel.fromMap(doc.id, doc.data()!);
      }

      await docRef.set(defaultChat.toMap(useServerTimestamp: true));
      return defaultChat;
    } catch (e) {
      debugPrint('ChatRepository.getOrCreateChat error: $e');
      rethrow;
    }
  }

  /// Fetch list of chats for the user (one-shot query with limit).
  /// Safe query avoiding composite index requirements by sorting in memory.
  Future<List<ChatModel>> getUserChats(String userId, {int limit = 20}) async {
    if (userId.isEmpty) return const [];
    final col = _chatsCollection;
    if (col == null) return const [];

    try {
      final snapshot = await col
          .where('participantIds', arrayContains: userId)
          .limit(limit)
          .get();

      final chats = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.id, doc.data()))
          .toList();

      chats.sort((a, b) {
        final tA = a.updatedAt ?? a.createdAt ?? DateTime(2000);
        final tB = b.updatedAt ?? b.createdAt ?? DateTime(2000);
        return tB.compareTo(tA);
      });

      return chats;
    } catch (e) {
      debugPrint('ChatRepository.getUserChats error: $e');
      return const [];
    }
  }

  /// Real-time stream of messages ONLY for the active conversation.
  /// Bounded query avoiding composite index requirements by sorting in memory.
  Stream<List<MessageModel>> streamMessages(String chatId, {int limit = 40}) {
    if (chatId.isEmpty) return Stream.value(const []);
    final col = _messagesCollection;
    if (col == null) return Stream.value(const []);

    try {
      return col
          .where('chatId', isEqualTo: chatId)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
                .toList();
            list.sort((a, b) {
              final tA = a.createdAt ?? DateTime(2000);
              final tB = b.createdAt ?? DateTime(2000);
              return tB.compareTo(tA);
            });
            return list;
          });
    } catch (e) {
      debugPrint('ChatRepository.streamMessages error: $e');
      return Stream.value(const []);
    }
  }

  /// Send a text message in the conversation.
  /// Updates both the messages collection and the chat's lastMessage metadata.
  Future<String> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Message text cannot be empty.');
    }
    if (trimmed.length > 2000) {
      throw ArgumentError('Message text must not exceed 2000 characters.');
    }
    if (senderId.isEmpty || receiverId.isEmpty) {
      throw ArgumentError('Sender and receiver IDs must not be empty.');
    }
    if (senderId == receiverId) {
      throw ArgumentError('Sender and receiver must be different users.');
    }

    // Safety check: block status
    final blocked = await _safetyRepo.isBlocked(
      userA: senderId,
      userB: receiverId,
    );
    if (blocked) {
      throw StateError(
        'Cannot send message because this user relationship is blocked.',
      );
    }

    try {
      final col = _messagesCollection;
      if (col != null) {
        final messageDoc = col.doc();
        final message = MessageModel(
          id: messageDoc.id,
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          text: trimmed,
        );

        // 1. Write the message document
        await messageDoc.set(message.toMap(useServerTimestamp: true));

        // 2. Update the parent chat's lastMessage and timestamp
        try {
          await _chatsCollection?.doc(chatId).update({
            'lastMessage': trimmed,
            'lastMessageAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (updateError) {
          debugPrint('Notice: Chat document update error: $updateError');
        }

        // 3. Create notification for receiver
        try {
          await _notificationRepo.createNotification(
            recipientId: receiverId,
            senderId: senderId,
            type: 'new_message',
            title: 'New Message',
            body: trimmed.length > 60
                ? '${trimmed.substring(0, 57)}...'
                : trimmed,
            referenceId: chatId,
          );
        } catch (notifErr) {
          debugPrint('Notice: message notification creation error: $notifErr');
        }

        return messageDoc.id;
      }
      return 'msg_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('ChatRepository.sendMessage error: $e');
      rethrow;
    }
  }
}
