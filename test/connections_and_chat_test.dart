import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niva/core/constants/app_colors.dart';
import 'package:niva/features/chat/data/chat_model.dart';
import 'package:niva/features/chat/data/chat_repository.dart';
import 'package:niva/features/chat/data/message_model.dart';
import 'package:niva/features/chat/presentation/chat_screen.dart';
import 'package:niva/features/chat/presentation/conversation_screen.dart';
import 'package:niva/features/connect/data/connection_request_model.dart';
import 'package:niva/features/connect/data/connection_request_repository.dart';
import 'package:niva/features/profile/presentation/profile_screen.dart';
import 'package:niva/features/safety/data/safety_repository.dart';
import 'package:niva/features/user/data/user_model.dart';
import 'package:niva/features/user/data/user_repository.dart';

class FakeSafetyRepository extends SafetyRepository {
  final Set<String> _blockedPairs = {};

  void block(String userA, String userB) {
    _blockedPairs.add('${userA}_$userB');
    _blockedPairs.add('${userB}_$userA');
  }

  void unblock(String userA, String userB) {
    _blockedPairs.remove('${userA}_$userB');
    _blockedPairs.remove('${userB}_$userA');
  }

  @override
  Future<bool> isBlocked({
    required String userA,
    required String userB,
  }) async {
    return _blockedPairs.contains('${userA}_$userB');
  }

  @override
  Future<String> blockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    block(blockerId, blockedUserId);
    return 'block_${blockerId}_$blockedUserId';
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    unblock(blockerId, blockedUserId);
  }
}

class FakeConnectionRequestRepository extends ConnectionRequestRepository {
  FakeConnectionRequestRepository({SafetyRepository? safetyRepo})
    : _safety = safetyRepo ?? FakeSafetyRepository();

  final SafetyRepository _safety;
  final Map<String, ConnectionRequestModel> requests = {};
  FakeChatRepository? linkedChatRepo;

  @override
  Future<String> sendConnectRequest({
    required String fromUserId,
    required String toUserId,
    required String needId,
    String? fromUserName,
    String? fromUserPhotoUrl,
    String? fromUserProfession,
    String? toUserName,
  }) async {
    if (fromUserId.isEmpty || toUserId.isEmpty) {
      throw ArgumentError('User IDs must not be empty.');
    }
    if (fromUserId == toUserId) {
      throw ArgumentError(
        'Users cannot send connection requests to themselves.',
      );
    }
    final blocked = await _safety.isBlocked(userA: fromUserId, userB: toUserId);
    if (blocked) {
      throw StateError(
        'Cannot send connection request because this user relationship is blocked.',
      );
    }

    final docId = '${fromUserId}_${toUserId}_$needId';
    final existing = requests[docId];
    if (existing != null && existing.status == 'pending') {
      return docId;
    }

    final newReq = ConnectionRequestModel(
      id: docId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      needId: needId,
      status: 'pending',
      fromUserName: fromUserName,
      fromUserPhotoUrl: fromUserPhotoUrl,
      fromUserProfession: fromUserProfession,
      toUserName: toUserName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    requests[docId] = newReq;
    return docId;
  }

  @override
  Future<void> respondToRequest({
    required String requestId,
    required String responderUserId,
    required String status,
  }) async {
    if (status != 'accepted' && status != 'declined') {
      throw ArgumentError('Status must be either "accepted" or "declined".');
    }
    final req = requests[requestId];
    if (req == null) {
      throw StateError('Connection request not found.');
    }
    if (req.toUserId != responderUserId) {
      throw StateError(
        'Only the recipient can respond to this connection request.',
      );
    }

    final updated = req.copyWith(status: status, updatedAt: DateTime.now());
    requests[requestId] = updated;

    if (status == 'accepted' && linkedChatRepo != null) {
      await linkedChatRepo!.getOrCreateChat(
        connectionRequestId: requestId,
        needId: req.needId,
        user1: req.fromUserId,
        user2: responderUserId,
        participantNames: {
          if (req.fromUserName != null) req.fromUserId: req.fromUserName!,
          if (req.toUserName != null) responderUserId: req.toUserName!,
        },
      );
    }
  }

  @override
  Future<List<ConnectionRequestModel>> getIncomingRequests(String userId) async {
    return requests.values
        .where((r) => r.toUserId == userId && r.status == 'pending')
        .toList();
  }

  @override
  Future<List<ConnectionRequestModel>> getSentRequests(String userId) async {
    return requests.values.where((r) => r.fromUserId == userId).toList();
  }

  @override
  Future<ConnectionRequestModel?> getConnectionRequestBetween({
    required String userA,
    required String userB,
  }) async {
    final matches =
        requests.values.where((r) {
          return (r.fromUserId == userA && r.toUserId == userB) ||
              (r.fromUserId == userB && r.toUserId == userA);
        }).toList();

    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      if (a.status == 'accepted' && b.status != 'accepted') return -1;
      if (b.status == 'accepted' && a.status != 'accepted') return 1;
      return (b.updatedAt ?? DateTime(2000)).compareTo(
        a.updatedAt ?? DateTime(2000),
      );
    });
    return matches.first;
  }
}

class FakeChatRepository extends ChatRepository {
  FakeChatRepository({
    SafetyRepository? safetyRepo,
    this.connectionRepo,
  }) : _safety = safetyRepo ?? FakeSafetyRepository();

  final SafetyRepository _safety;
  final FakeConnectionRequestRepository? connectionRepo;
  final Map<String, ChatModel> chats = {};
  final Map<String, List<MessageModel>> messages = {};
  final Map<String, StreamController<List<MessageModel>>> messageControllers = {};

  void _notifyMessages(String chatId) {
    if (!messageControllers.containsKey(chatId)) {
      messageControllers[chatId] =
          StreamController<List<MessageModel>>.broadcast();
    }
    final list = List<MessageModel>.from(messages[chatId] ?? const []);
    list.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    messageControllers[chatId]!.add(list);
  }

  @override
  Future<ChatModel> getOrCreateChat({
    required String connectionRequestId,
    required String needId,
    required String user1,
    required String user2,
    Map<String, String>? participantNames,
  }) async {
    final chatId = ChatRepository.generateChatId(user1, user2);
    if (chats.containsKey(chatId)) {
      return chats[chatId]!;
    }
    final chat = ChatModel(
      id: chatId,
      participantIds: [user1, user2]..sort(),
      needId: needId,
      connectionRequestId: connectionRequestId,
      participantNames: participantNames,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    chats[chatId] = chat;
    messages[chatId] = [];
    return chat;
  }

  @override
  Future<List<ChatModel>> getUserChats(String userId, {int limit = 20}) async {
    final list = chats.values.where((c) => c.participantIds.contains(userId)).toList();
    list.sort((a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(a.updatedAt ?? DateTime(2000)));
    return list;
  }

  @override
  Stream<List<MessageModel>> streamMessages(String chatId, {int limit = 40}) {
    if (!messageControllers.containsKey(chatId)) {
      messageControllers[chatId] =
          StreamController<List<MessageModel>>.broadcast();
    }
    Future.microtask(() => _notifyMessages(chatId));
    return messageControllers[chatId]!.stream;
  }

  @override
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

    final blocked = await _safety.isBlocked(userA: senderId, userB: receiverId);
    if (blocked) {
      throw StateError(
        'Cannot send message because this user relationship is blocked.',
      );
    }

    final chat = chats[chatId];
    if (chat != null &&
        chat.connectionRequestId.isNotEmpty &&
        connectionRepo != null) {
      final req = connectionRepo!.requests[chat.connectionRequestId];
      if (req != null && req.status != 'accepted') {
        throw StateError(
          'Messaging is allowed only after connection request acceptance.',
        );
      }
    }

    final msgId =
        'msg_${DateTime.now().millisecondsSinceEpoch}_${(messages[chatId]?.length ?? 0) + 1}';
    final msg = MessageModel(
      id: msgId,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: trimmed,
      createdAt: DateTime.now(),
    );

    messages.putIfAbsent(chatId, () => []).add(msg);

    if (chat != null) {
      chats[chatId] = chat.copyWith(
        lastMessage: trimmed,
        lastMessageAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    _notifyMessages(chatId);
    return msgId;
  }
}

class FakeUserRepository extends UserRepository {
  final Map<String, UserModel> users = {};

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    return users[uid];
  }
}

void main() {
  group('Phase 5 Connection Requests Unit Tests', () {
    late FakeSafetyRepository safetyRepo;
    late FakeConnectionRequestRepository connectionRepo;
    late FakeChatRepository chatRepo;

    setUp(() {
      safetyRepo = FakeSafetyRepository();
      connectionRepo = FakeConnectionRequestRepository(safetyRepo: safetyRepo);
      chatRepo = FakeChatRepository(
        safetyRepo: safetyRepo,
        connectionRepo: connectionRepo,
      );
      connectionRepo.linkedChatRepo = chatRepo;
    });

    test('User A sends request to User B and creates pending request', () async {
      final reqId = await connectionRepo.sendConnectRequest(
        fromUserId: 'user_a',
        toUserId: 'user_b',
        needId: 'direct_connection',
        fromUserName: 'Alice Chen',
        toUserName: 'Bob Miller',
      );

      expect(reqId, 'user_a_user_b_direct_connection');
      expect(connectionRepo.requests[reqId]?.status, 'pending');
      expect(connectionRepo.requests[reqId]?.fromUserName, 'Alice Chen');

      final incomingB = await connectionRepo.getIncomingRequests('user_b');
      expect(incomingB.length, 1);
      expect(incomingB.first.id, reqId);

      final sentA = await connectionRepo.getSentRequests('user_a');
      expect(sentA.length, 1);
      expect(sentA.first.status, 'pending');
    });

    test('Prevents users from connecting with themselves', () async {
      expect(
        () => connectionRepo.sendConnectRequest(
          fromUserId: 'user_a',
          toUserId: 'user_a',
          needId: 'direct_connection',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Prevents duplicate pending requests', () async {
      final id1 = await connectionRepo.sendConnectRequest(
        fromUserId: 'user_a',
        toUserId: 'user_b',
        needId: 'direct_connection',
      );
      final id2 = await connectionRepo.sendConnectRequest(
        fromUserId: 'user_a',
        toUserId: 'user_b',
        needId: 'direct_connection',
      );

      expect(id1, id2);
      expect(connectionRepo.requests.length, 1);
    });

    test('Prevents connection requests between blocked users', () async {
      safetyRepo.block('user_a', 'user_b');

      expect(
        () => connectionRepo.sendConnectRequest(
          fromUserId: 'user_a',
          toUserId: 'user_b',
          needId: 'direct_connection',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('User B accepts request, status updates and chat is created', () async {
      final reqId = await connectionRepo.sendConnectRequest(
        fromUserId: 'user_a',
        toUserId: 'user_b',
        needId: 'direct_connection',
        fromUserName: 'Alice',
        toUserName: 'Bob',
      );

      await connectionRepo.respondToRequest(
        requestId: reqId,
        responderUserId: 'user_b',
        status: 'accepted',
      );

      expect(connectionRepo.requests[reqId]?.status, 'accepted');

      final userChatsA = await chatRepo.getUserChats('user_a');
      expect(userChatsA.length, 1);
      expect(userChatsA.first.participantIds, containsAll(['user_a', 'user_b']));
    });

    test('Only recipient can accept or decline request', () async {
      final reqId = await connectionRepo.sendConnectRequest(
        fromUserId: 'user_a',
        toUserId: 'user_b',
        needId: 'direct_connection',
      );

      expect(
        () => connectionRepo.respondToRequest(
          requestId: reqId,
          responderUserId: 'user_a',
          status: 'accepted',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Declined requests do not initialize chat', () async {
      final reqId = await connectionRepo.sendConnectRequest(
        fromUserId: 'user_a',
        toUserId: 'user_b',
        needId: 'direct_connection',
      );

      await connectionRepo.respondToRequest(
        requestId: reqId,
        responderUserId: 'user_b',
        status: 'declined',
      );

      expect(connectionRepo.requests[reqId]?.status, 'declined');
      expect(chatRepo.chats.isEmpty, isTrue);
    });
  });

  group('Phase 5 Chat & Messaging Unit Tests', () {
    late FakeSafetyRepository safetyRepo;
    late FakeConnectionRequestRepository connectionRepo;
    late FakeChatRepository chatRepo;

    setUp(() {
      safetyRepo = FakeSafetyRepository();
      connectionRepo = FakeConnectionRequestRepository(safetyRepo: safetyRepo);
      chatRepo = FakeChatRepository(
        safetyRepo: safetyRepo,
        connectionRepo: connectionRepo,
      );
      connectionRepo.linkedChatRepo = chatRepo;
    });

    test('Messaging allowed only after connection acceptance', () async {
      final reqId = await connectionRepo.sendConnectRequest(
        fromUserId: 'user_a',
        toUserId: 'user_b',
        needId: 'direct_connection',
      );

      final chatId = ChatRepository.generateChatId('user_a', 'user_b');
      chatRepo.chats[chatId] = ChatModel(
        id: chatId,
        participantIds: ['user_a', 'user_b'],
        needId: 'direct_connection',
        connectionRequestId: reqId,
      );

      // Sending before acceptance must reject with StateError
      await expectLater(
        chatRepo.sendMessage(
          chatId: chatId,
          senderId: 'user_a',
          receiverId: 'user_b',
          text: 'Hello Bob',
        ),
        throwsA(isA<StateError>()),
      );

      // Once accepted, messaging succeeds
      await connectionRepo.respondToRequest(
        requestId: reqId,
        responderUserId: 'user_b',
        status: 'accepted',
      );

      final msgId = await chatRepo.sendMessage(
        chatId: chatId,
        senderId: 'user_a',
        receiverId: 'user_b',
        text: 'Hello Bob after acceptance!',
      );

      expect(msgId, isNotEmpty);
      expect(chatRepo.messages[chatId]?.length, 1);
      expect(chatRepo.chats[chatId]?.lastMessage, 'Hello Bob after acceptance!');
    });

    test('Declined request prevents sending messages', () async {
      final reqId = await connectionRepo.sendConnectRequest(
        fromUserId: 'user_a',
        toUserId: 'user_b',
        needId: 'direct_connection',
      );

      await connectionRepo.respondToRequest(
        requestId: reqId,
        responderUserId: 'user_b',
        status: 'declined',
      );

      final chatId = ChatRepository.generateChatId('user_a', 'user_b');
      chatRepo.chats[chatId] = ChatModel(
        id: chatId,
        participantIds: ['user_a', 'user_b'],
        needId: 'direct_connection',
        connectionRequestId: reqId,
      );

      expect(
        chatRepo.sendMessage(
          chatId: chatId,
          senderId: 'user_a',
          receiverId: 'user_b',
          text: 'Are you there?',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Blocked users cannot communicate in chat', () async {
      final reqId = await connectionRepo.sendConnectRequest(
        fromUserId: 'user_a',
        toUserId: 'user_b',
        needId: 'direct_connection',
      );
      await connectionRepo.respondToRequest(
        requestId: reqId,
        responderUserId: 'user_b',
        status: 'accepted',
      );

      final chatId = ChatRepository.generateChatId('user_a', 'user_b');
      safetyRepo.block('user_a', 'user_b');

      expect(
        chatRepo.sendMessage(
          chatId: chatId,
          senderId: 'user_a',
          receiverId: 'user_b',
          text: 'Can you hear me?',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Phase 5 ConversationScreen Widget Tests', () {
    late FakeSafetyRepository safetyRepo;
    late FakeChatRepository chatRepo;
    late ChatModel testChat;

    setUp(() {
      safetyRepo = FakeSafetyRepository();
      chatRepo = FakeChatRepository(safetyRepo: safetyRepo);
      testChat = ChatModel(
        id: 'user_a_user_b',
        participantIds: ['user_a', 'user_b'],
        needId: 'direct_connection',
        connectionRequestId: 'req_1',
      );
      chatRepo.chats[testChat.id] = testChat;
    });

    testWidgets('Renders Apple minimal chat UI, sends message, and displays Apple Blue bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationScreen(
            chat: testChat,
            otherUserName: 'Bob Miller',
            otherUserId: 'user_b',
            currentUserId: 'user_a',
            chatRepository: chatRepo,
            safetyRepository: safetyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bob Miller'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Hi Bob, excited to connect!');

      // Tap send button (arrow upward icon)
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Hi Bob, excited to connect!'), findsOneWidget);

      // Verify bubble container has Apple Blue decoration
      final bubbleText = find.text('Hi Bob, excited to connect!');
      final bubbleContainer = tester.widget<Container>(
        find.ancestor(
          of: bubbleText,
          matching: find.byType(Container),
        ).first,
      );
      final decoration = bubbleContainer.decoration as BoxDecoration;
      expect(decoration.color, AppColors.appleBlue);
    });

    testWidgets('Displays light grey bubble for received message', (
      tester,
    ) async {
      chatRepo.messages[testChat.id] = [
        MessageModel(
          id: 'msg_recv_1',
          chatId: testChat.id,
          senderId: 'user_b',
          receiverId: 'user_a',
          text: 'Hello from Bob!',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationScreen(
            chat: testChat,
            otherUserName: 'Bob Miller',
            otherUserId: 'user_b',
            currentUserId: 'user_a',
            chatRepository: chatRepo,
            safetyRepository: safetyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello from Bob!'), findsOneWidget);

      final bubbleContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Hello from Bob!'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = bubbleContainer.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFE5E5EA));
    });
  });

  group('Phase 5 ChatScreen & Requests Hub Widget Tests', () {
    late FakeSafetyRepository safetyRepo;
    late FakeConnectionRequestRepository connectionRepo;
    late FakeChatRepository chatRepo;

    setUp(() {
      safetyRepo = FakeSafetyRepository();
      connectionRepo = FakeConnectionRequestRepository(safetyRepo: safetyRepo);
      chatRepo = FakeChatRepository(
        safetyRepo: safetyRepo,
        connectionRepo: connectionRepo,
      );
      connectionRepo.linkedChatRepo = chatRepo;
    });

    testWidgets('Renders segmented tabs, chats, and switches to connection requests', (
      tester,
    ) async {
      await connectionRepo.sendConnectRequest(
        fromUserId: 'user_alice',
        toUserId: 'user_b',
        needId: 'direct_connection',
        fromUserName: 'Alice Chen',
        fromUserProfession: 'Product Designer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            chatRepository: chatRepo,
            connectionRequestRepository: connectionRepo,
            currentUserId: 'user_b',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('No conversations yet'), findsOneWidget);

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(find.text('INCOMING REQUESTS'), findsOneWidget);
      expect(find.text('Alice Chen'), findsOneWidget);
      expect(find.text('Product Designer'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(find.text('No connection requests'), findsOneWidget);

      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();

      expect(find.text('Alice Chen'), findsOneWidget);
    });
  });

  group('Phase 5 ProfileScreen Connection Actions Widget Tests', () {
    late FakeSafetyRepository safetyRepo;
    late FakeConnectionRequestRepository connectionRepo;
    late FakeChatRepository chatRepo;
    late FakeUserRepository userRepo;

    final peerUser = UserModel(
      uid: 'user_target',
      name: 'Maya Patel',
      profession: 'iOS Engineer',
      skills: ['Swift', 'SwiftUI'],
      bio: 'Crafting Apple apps',
    );

    setUp(() {
      safetyRepo = FakeSafetyRepository();
      connectionRepo = FakeConnectionRequestRepository(safetyRepo: safetyRepo);
      chatRepo = FakeChatRepository(
        safetyRepo: safetyRepo,
        connectionRepo: connectionRepo,
      );
      userRepo = FakeUserRepository();
      userRepo.users[peerUser.uid] = peerUser;
    });

    testWidgets('Send Connection Request from peer profile creates pending state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            targetUserId: 'user_target',
            initialProfile: peerUser,
            isOwnProfileOverride: false,
            currentUserId: 'user_me',
            userRepository: userRepo,
            connectionRequestRepository: connectionRepo,
            chatRepository: chatRepo,
            safetyRepository: safetyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Send Connection Request'), findsOneWidget);
      expect(find.text('Direct Message'), findsOneWidget);

      await tester.tap(find.text('Send Connection Request'));
      await tester.pumpAndSettle();

      expect(find.text('Connection Request Sent'), findsOneWidget);
      expect(connectionRepo.requests.length, 1);
    });

    testWidgets('Accepted connection enables chatting from profile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      connectionRepo.requests['user_me_user_target_direct_connection'] =
          ConnectionRequestModel(
            id: 'user_me_user_target_direct_connection',
            fromUserId: 'user_me',
            toUserId: 'user_target',
            needId: 'direct_connection',
            status: 'accepted',
          );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            targetUserId: 'user_target',
            initialProfile: peerUser,
            isOwnProfileOverride: false,
            currentUserId: 'user_me',
            userRepository: userRepo,
            connectionRequestRepository: connectionRepo,
            chatRepository: chatRepo,
            safetyRepository: safetyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Direct Message'), findsOneWidget);

      await tester.tap(find.text('Direct Message'));
      await tester.pumpAndSettle();

      expect(find.byType(ConversationScreen), findsOneWidget);
    });

    testWidgets('Blocked user displays User Blocked on profile', (
      tester,
    ) async {
      safetyRepo.block('user_me', 'user_target');

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            targetUserId: 'user_target',
            initialProfile: peerUser,
            isOwnProfileOverride: false,
            currentUserId: 'user_me',
            userRepository: userRepo,
            connectionRequestRepository: connectionRepo,
            chatRepository: chatRepo,
            safetyRepository: safetyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('User Blocked'), findsOneWidget);
      expect(find.text('Send Connection Request'), findsNothing);
    });
  });
}
