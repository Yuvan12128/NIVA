import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niva/core/constants/app_colors.dart';
import 'package:niva/core/utils/url_validator.dart';
import 'package:niva/features/auth/data/auth_service.dart';
import 'package:niva/features/auth/presentation/sign_in_screen.dart';
import 'package:niva/features/chat/data/chat_model.dart';
import 'package:niva/features/chat/data/chat_repository.dart';
import 'package:niva/features/chat/data/message_model.dart';
import 'package:niva/features/chat/presentation/chat_screen.dart';
import 'package:niva/features/chat/presentation/conversation_screen.dart';
import 'package:niva/features/connect/data/connection_request_model.dart';
import 'package:niva/features/connect/data/connection_request_repository.dart';
import 'package:niva/features/discover/presentation/discover_people_screen.dart';
import 'package:niva/features/home/presentation/widgets/home_posts_section.dart';
import 'package:niva/features/needs/data/need_model.dart';
import 'package:niva/features/needs/data/need_repository.dart';
import 'package:niva/features/profile/presentation/profile_screen.dart';
import 'package:niva/features/safety/data/safety_repository.dart';
import 'package:niva/features/user/data/user_model.dart';
import 'package:niva/features/user/data/user_repository.dart';

class FakeE2EUserRepo extends UserRepository {
  final Map<String, UserModel> users = {};
  final Map<String, String> privateEmails = {};

  @override
  Future<void> createUserProfile(UserModel user) async {
    users[user.uid] = user;
    if (user.email.isNotEmpty) {
      privateEmails[user.uid] = user.email;
    }
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final user = users[uid];
    if (user == null) return null;
    return user.copyWith(email: privateEmails[uid] ?? user.email);
  }

  @override
  Future<String?> getUserPrivateEmail(String uid) async {
    return privateEmails[uid];
  }

  @override
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final existing = users[uid];
    if (existing == null) return;

    final email = data['email'] as String?;
    if (email != null && email.isNotEmpty) {
      privateEmails[uid] = email;
    }

    users[uid] = existing.copyWith(
      name: data['name'] as String? ?? existing.name,
      bio: data['bio'] as String? ?? existing.bio,
      profession: data['profession'] as String? ?? existing.profession,
      education: data['education'] as String? ?? existing.education,
      experience: data['experience'] as String? ?? existing.experience,
      linkedInUrl: data['linkedInUrl'] as String? ?? existing.linkedInUrl,
      githubUrl: data['githubUrl'] as String? ?? existing.githubUrl,
      portfolioUrl: data['portfolioUrl'] as String? ?? existing.portfolioUrl,
      skills:
          (data['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          existing.skills,
    );
  }

  @override
  Future<List<UserModel>> discoverPeople({
    String query = '',
    String? currentUserId,
    Set<String> blockedUserIds = const {},
    int limit = 30,
    dynamic startAfter,
  }) async {
    return UserRepository.filterDiscoverableUsers(
      users: users.values.toList(),
      query: query,
      currentUserId: currentUserId,
      blockedUserIds: blockedUserIds,
    );
  }
}

class FakeE2ENeedRepo extends NeedRepository {
  final Map<String, NeedModel> posts = {};
  final StreamController<List<NeedModel>> _ctrl =
      StreamController<List<NeedModel>>.broadcast();

  void _notify() => _ctrl.add(posts.values.toList());

  @override
  Future<String> createNeed(NeedModel need) async {
    final id = 'need_${posts.length + 1}';
    final saved = need.copyWith(needId: id, createdAt: DateTime.now());
    posts[id] = saved;
    _notify();
    return id;
  }

  @override
  Future<List<NeedModel>> getNeedsByType(
    String type, {
    int limit = 20,
    dynamic startAfter,
  }) async {
    return posts.values.where((p) => p.type == type).toList();
  }

  @override
  Stream<List<NeedModel>> streamNeedsByType(String type, {int limit = 20}) {
    Future.microtask(_notify);
    return _ctrl.stream.map(
      (list) => list.where((p) => p.type == type).toList(),
    );
  }
}

class FakeE2ESafetyRepo extends SafetyRepository {
  final Set<String> _blocks = {};

  void block(String u1, String u2) {
    _blocks.add('${u1}_$u2');
    _blocks.add('${u2}_$u1');
  }

  @override
  Future<bool> isBlocked({required String userA, required String userB}) async {
    return _blocks.contains('${userA}_$userB');
  }

  @override
  Future<Set<String>> getBlockedUserIds(String currentUserId) async {
    final blocked = <String>{};
    for (final pair in _blocks) {
      if (pair.startsWith('${currentUserId}_')) {
        blocked.add(pair.split('_')[1]);
      }
    }
    return blocked;
  }

  @override
  Future<String> blockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    block(blockerId, blockedUserId);
    return 'block_${blockerId}_$blockedUserId';
  }
}

class FakeE2EConnectionRepo extends ConnectionRequestRepository {
  FakeE2EConnectionRepo({required this.safetyRepo});
  final SafetyRepository safetyRepo;
  final Map<String, ConnectionRequestModel> requests = {};
  FakeE2EChatRepo? linkedChatRepo;

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
      throw ArgumentError('Users cannot send connection requests to themselves.');
    }
    final blocked = await safetyRepo.isBlocked(userA: fromUserId, userB: toUserId);
    if (blocked) {
      throw StateError('Cannot send connection request because this user relationship is blocked.');
    }

    final docId = '${fromUserId}_${toUserId}_$needId';
    if (requests.containsKey(docId) && requests[docId]?.status == 'pending') {
      return docId;
    }

    final req = ConnectionRequestModel(
      id: docId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      needId: needId,
      status: 'pending',
      fromUserName: fromUserName,
      toUserName: toUserName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    requests[docId] = req;
    return docId;
  }

  @override
  Future<void> respondToRequest({
    required String requestId,
    required String responderUserId,
    required String status,
  }) async {
    final req = requests[requestId];
    if (req == null) throw StateError('Connection request not found.');
    if (req.toUserId != responderUserId) {
      throw StateError('Only recipient can respond.');
    }
    requests[requestId] = req.copyWith(status: status, updatedAt: DateTime.now());

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
    return requests.values.where((r) => r.toUserId == userId && r.status == 'pending').toList();
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
    final list = requests.values.where((r) =>
      (r.fromUserId == userA && r.toUserId == userB) ||
      (r.fromUserId == userB && r.toUserId == userA)
    ).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(a.updatedAt ?? DateTime(2000)));
    return list.first;
  }
}

class FakeE2EChatRepo extends ChatRepository {
  FakeE2EChatRepo({required this.safetyRepo, required this.connectionRepo});
  final SafetyRepository safetyRepo;
  final FakeE2EConnectionRepo connectionRepo;
  final Map<String, ChatModel> chats = {};
  final Map<String, List<MessageModel>> messages = {};
  final Map<String, StreamController<List<MessageModel>>> ctrls = {};

  void _notify(String chatId) {
    ctrls.putIfAbsent(chatId, () => StreamController<List<MessageModel>>.broadcast());
    ctrls[chatId]!.add(List<MessageModel>.from(messages[chatId] ?? const []));
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
    if (chats.containsKey(chatId)) return chats[chatId]!;
    final c = ChatModel(
      id: chatId,
      participantIds: [user1, user2]..sort(),
      needId: needId,
      connectionRequestId: connectionRequestId,
      participantNames: participantNames,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    chats[chatId] = c;
    messages[chatId] = [];
    return c;
  }

  @override
  Future<List<ChatModel>> getUserChats(String userId, {int limit = 20}) async {
    return chats.values.where((c) => c.participantIds.contains(userId)).toList();
  }

  @override
  Stream<List<MessageModel>> streamMessages(String chatId, {int limit = 40}) {
    ctrls.putIfAbsent(chatId, () => StreamController<List<MessageModel>>.broadcast());
    Future.microtask(() => _notify(chatId));
    return ctrls[chatId]!.stream;
  }

  @override
  Future<String> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final blocked = await safetyRepo.isBlocked(userA: senderId, userB: receiverId);
    if (blocked) {
      throw StateError('Cannot send message because this user relationship is blocked.');
    }
    final chat = chats[chatId];
    if (chat != null && chat.connectionRequestId.isNotEmpty) {
      final req = connectionRepo.requests[chat.connectionRequestId];
      if (req != null && req.status != 'accepted') {
        throw StateError('Messaging is allowed only after connection request acceptance.');
      }
    }
    final msgId = 'msg_${messages[chatId]?.length ?? 0}';
    final m = MessageModel(
      id: msgId,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: DateTime.now(),
    );
    messages.putIfAbsent(chatId, () => []).add(m);
    _notify(chatId);
    return msgId;
  }
}

class FakeE2EAuthService extends AuthService {
  FakeE2EAuthService({required this.fakeUserRepo}) : super(userRepository: fakeUserRepo);
  final FakeE2EUserRepo fakeUserRepo;
  bool signInCalled = false;

  @override
  Future<UserCredential?> signInWithGoogle() async {
    signInCalled = true;
    return null;
  }
}

void main() {
  group('NIVA E2E Launch Readiness & Core User Workflows Suite', () {
    late FakeE2EUserRepo userRepo;
    late FakeE2ENeedRepo needRepo;
    late FakeE2ESafetyRepo safetyRepo;
    late FakeE2EConnectionRepo connectionRepo;
    late FakeE2EChatRepo chatRepo;

    final userAlice = UserModel(
      uid: 'user_alice',
      name: 'Alice Chen',
      email: 'alice@niva.app',
      profession: 'Staff Product Designer',
      education: 'RISD',
      skills: ['Figma', 'Design Systems', 'Apple HIG'],
      bio: 'Designing human-first experiences',
      linkedInUrl: 'https://linkedin.com/in/alicechen',
      githubUrl: 'https://github.com/alicechen',
    );

    final userBob = UserModel(
      uid: 'user_bob',
      name: 'Bob Miller',
      email: 'bob@niva.app',
      profession: 'Flutter Systems Architect',
      education: 'Stanford',
      skills: ['Flutter', 'Dart', 'Firebase'],
      bio: 'Architecting minimal peer software',
    );

    setUp(() {
      userRepo = FakeE2EUserRepo();
      needRepo = FakeE2ENeedRepo();
      safetyRepo = FakeE2ESafetyRepo();
      connectionRepo = FakeE2EConnectionRepo(safetyRepo: safetyRepo);
      chatRepo = FakeE2EChatRepo(safetyRepo: safetyRepo, connectionRepo: connectionRepo);
      connectionRepo.linkedChatRepo = chatRepo;

      userRepo.users[userAlice.uid] = userAlice;
      userRepo.users[userBob.uid] = userBob;
    });

    testWidgets('1. Authentication: SignInScreen renders Apple Minimal UI & calls Google Sign-In', (
      tester,
    ) async {
      final fakeAuth = FakeE2EAuthService(fakeUserRepo: userRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(authService: fakeAuth),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NIVA'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(fakeAuth.signInCalled, isTrue);
    });

    testWidgets('2. Profile: Displays profile, validates URLs, and protects private email', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            targetUserId: 'user_alice',
            initialProfile: userAlice,
            isOwnProfileOverride: false,
            currentUserId: 'user_bob',
            userRepository: userRepo,
            connectionRequestRepository: connectionRepo,
            chatRepository: chatRepo,
            safetyRepository: safetyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice Chen'), findsOneWidget);
      expect(find.text('Staff Product Designer'), findsOneWidget);
      expect(find.text('RISD'), findsOneWidget);
      expect(find.text('Design Systems'), findsAtLeastNWidgets(1));

      // Verify email is strictly hidden from peer view
      expect(find.text('alice@niva.app'), findsNothing);

      // Verify URL normalization
      expect(UrlValidator.normalize('linkedin.com/in/alicechen'), 'https://linkedin.com/in/alicechen');
      expect(UrlValidator.validateUrl('https://linkedin.com/in/alicechen', platform: 'LinkedIn'), isNull);
      expect(UrlValidator.isValidUrl('https://linkedin.com/in/alicechen'), isTrue);
    });

    testWidgets('3. Posts: HomePostsSection switches segments between Need Help and Can Help', (
      tester,
    ) async {
      await needRepo.createNeed(
        NeedModel(
          needId: 'n1',
          userId: 'user_alice',
          type: 'need',
          title: 'Need help with distributed caching',
          description: 'Scaling read performance.',
          authorName: 'Alice Chen',
        ),
      );
      await needRepo.createNeed(
        NeedModel(
          needId: 'h1',
          userId: 'user_bob',
          type: 'help',
          title: 'Can provide architecture review',
          description: '10+ years backend & mobile experience.',
          authorName: 'Bob Miller',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomePostsSection(
              needRepository: needRepo,
              userRepository: userRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In "Need Help" tab
      expect(find.text('Need help with distributed caching'), findsOneWidget);
      expect(find.text('Can provide architecture review'), findsNothing);

      // Switch to "Can Help" tab
      await tester.tap(find.text('Can Help'));
      await tester.pumpAndSettle();

      expect(find.text('Can provide architecture review'), findsOneWidget);
      expect(find.text('Need help with distributed caching'), findsNothing);
    });

    testWidgets('4. Discover: Debounced search finds peers by skills and profession', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiscoverPeopleScreen(
            userRepository: userRepo,
            safetyRepository: safetyRepo,
            connectionRequestRepository: connectionRepo,
            currentUserId: 'user_alice',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bob Miller'), findsOneWidget);

      // Search by skill "Firebase"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Firebase');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Bob Miller'), findsOneWidget);

      // Search nonexistent
      await tester.enterText(searchField, 'NonExistentSkillXYZ');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('No people found'), findsOneWidget);
    });

    testWidgets('5. Connections & 6. Chat: Complete end-to-end connection flow and real-time messaging', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Bob views Alice's profile and sends connection request
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            targetUserId: 'user_alice',
            initialProfile: userAlice,
            isOwnProfileOverride: false,
            currentUserId: 'user_bob',
            userRepository: userRepo,
            connectionRequestRepository: connectionRepo,
            chatRepository: chatRepo,
            safetyRepository: safetyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Connection Request'));
      await tester.pumpAndSettle();

      expect(find.text('Connection Request Sent'), findsOneWidget);
      expect(connectionRepo.requests.length, 1);
      final reqId = connectionRepo.requests.keys.first;

      // 2. Alice views ChatScreen Requests tab and accepts Bob's request
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            chatRepository: chatRepo,
            connectionRequestRepository: connectionRepo,
            currentUserId: 'user_alice',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(find.text('Accept'), findsOneWidget);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      ScaffoldMessenger.of(tester.element(find.byType(ChatScreen))).clearSnackBars();
      await tester.pumpAndSettle();

      // Request accepted and chat initialized
      expect(connectionRepo.requests[reqId]?.status, 'accepted');
      expect(chatRepo.chats.length, 1);

      // 3. Open conversation screen and send message
      final chat = chatRepo.chats.values.first;
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationScreen(
            chat: chat,
            otherUserName: 'Bob Miller',
            otherUserId: 'user_bob',
            currentUserId: 'user_alice',
            chatRepository: chatRepo,
            safetyRepository: safetyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final input = find.byType(TextField);
      await tester.enterText(input, 'Hello Bob! Thanks for connecting.');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Hello Bob! Thanks for connecting.'), findsOneWidget);

      // 4. Verify message color is Apple Blue
      final bubbleContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Hello Bob! Thanks for connecting.'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = bubbleContainer.decoration as BoxDecoration;
      expect(decoration.color, AppColors.appleBlue);
    });

    testWidgets('7. Security: Blocked relationship disables messaging and request creation', (
      tester,
    ) async {
      safetyRepo.block('user_alice', 'user_bob');

      // Attempt to send connection request when blocked
      expect(
        connectionRepo.sendConnectRequest(
          fromUserId: 'user_alice',
          toUserId: 'user_bob',
          needId: 'direct_connection',
        ),
        throwsA(isA<StateError>()),
      );

      // Attempt to send chat message when blocked
      final chatId = ChatRepository.generateChatId('user_alice', 'user_bob');
      expect(
        chatRepo.sendMessage(
          chatId: chatId,
          senderId: 'user_alice',
          receiverId: 'user_bob',
          text: 'Unreachable message',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
