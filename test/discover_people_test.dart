import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niva/features/connect/data/connection_request_model.dart';
import 'package:niva/features/connect/data/connection_request_repository.dart';
import 'package:niva/features/discover/presentation/discover_people_screen.dart';
import 'package:niva/features/profile/presentation/profile_screen.dart';
import 'package:niva/features/safety/data/safety_repository.dart';
import 'package:niva/features/user/data/user_model.dart';
import 'package:niva/features/user/data/user_repository.dart';

class FakeDiscoverUserRepository extends UserRepository {
  final List<UserModel> community = [];
  bool shouldFail = false;

  @override
  Future<List<UserModel>> discoverPeople({
    String query = '',
    String? currentUserId,
    Set<String> blockedUserIds = const {},
    int limit = 30,
    dynamic startAfter,
  }) async {
    if (shouldFail) {
      throw Exception('Firestore network timeout');
    }
    return UserRepository.filterDiscoverableUsers(
      users: community,
      query: query,
      currentUserId: currentUserId,
      blockedUserIds: blockedUserIds,
    );
  }
}

class FakeDiscoverSafetyRepository extends SafetyRepository {
  final Set<String> blocked = {};

  @override
  Future<Set<String>> getBlockedUserIds(String currentUserId) async {
    return blocked;
  }
}

class FakeDiscoverConnectionRepo extends ConnectionRequestRepository {
  final List<ConnectionRequestModel> sentRequests = [];
  bool shouldFail = false;

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
    if (shouldFail) {
      throw Exception('Request sending failed');
    }
    final req = ConnectionRequestModel(
      id: 'req_${sentRequests.length + 1}',
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
    sentRequests.add(req);
    return req.id;
  }
}

void main() {
  group('UserRepository Discover People Unit Tests', () {
    final userMe = UserModel(
      uid: 'user_me',
      name: 'Myself',
      email: 'me@niva.app',
      profession: 'Mobile Lead',
      skills: ['Flutter', 'Dart'],
      education: 'MIT',
      bio: 'Building minimal products',
    );

    final userAlice = UserModel(
      uid: 'user_alice',
      name: 'Alice Chen',
      email: 'alice@niva.app',
      profession: 'Staff Product Designer',
      skills: ['Figma', 'UI/UX', 'Design Systems', 'Apple HIG'],
      education: 'Rhode Island School of Design',
      bio: 'Crafting pixel-perfect human interfaces',
      linkedInUrl: 'https://linkedin.com/in/alicechen',
      githubUrl: 'https://github.com/alicechen',
    );

    final userBob = UserModel(
      uid: 'user_bob',
      name: 'Bob Miller',
      email: 'bob@niva.app',
      profession: 'Flutter Systems Architect',
      skills: ['Flutter', 'Dart', 'Firebase', 'Clean Architecture'],
      education: 'Stanford University',
      bio: 'Passionate about cross-platform performance',
      githubUrl: 'https://github.com/bobmiller',
    );

    final userCharlie = UserModel(
      uid: 'user_charlie',
      name: 'Charlie Davis',
      email: 'charlie@niva.app',
      profession: 'Machine Learning Engineer',
      skills: ['Python', 'PyTorch', 'TensorFlow', 'LLMs'],
      education: 'Carnegie Mellon University',
      bio: 'Building intelligent edge systems',
    );

    final allUsers = [userMe, userAlice, userBob, userCharlie];

    test('Excludes currentUserId from discovery candidates', () {
      final results = UserRepository.filterDiscoverableUsers(
        users: allUsers,
        currentUserId: 'user_me',
      );

      expect(results.any((u) => u.uid == 'user_me'), isFalse);
      expect(results.length, 3);
      expect(
        results.map((u) => u.uid),
        containsAll(['user_alice', 'user_bob', 'user_charlie']),
      );
    });

    test('Excludes blockedUserIds from discovery candidates', () {
      final results = UserRepository.filterDiscoverableUsers(
        users: allUsers,
        currentUserId: 'user_me',
        blockedUserIds: {'user_charlie'},
      );

      expect(results.any((u) => u.uid == 'user_charlie'), isFalse);
      expect(results.length, 2);
      expect(results.map((u) => u.uid), containsAll(['user_alice', 'user_bob']));
    });

    test('Matches candidates by Name (case-insensitive)', () {
      final results = UserRepository.filterDiscoverableUsers(
        users: allUsers,
        query: 'aLiCe',
        currentUserId: 'user_me',
      );

      expect(results.length, 1);
      expect(results.first.uid, 'user_alice');
    });

    test('Matches candidates by Skills (case-insensitive)', () {
      final results = UserRepository.filterDiscoverableUsers(
        users: allUsers,
        query: 'FLUTTER',
        currentUserId: 'user_me',
      );

      expect(results.length, 1);
      expect(results.first.uid, 'user_bob');
    });

    test('Matches candidates by Profession', () {
      final results = UserRepository.filterDiscoverableUsers(
        users: allUsers,
        query: 'Product Designer',
        currentUserId: 'user_me',
      );

      expect(results.length, 1);
      expect(results.first.uid, 'user_alice');
    });

    test('Matches candidates by Education', () {
      final results = UserRepository.filterDiscoverableUsers(
        users: allUsers,
        query: 'Stanford',
        currentUserId: 'user_me',
      );

      expect(results.length, 1);
      expect(results.first.uid, 'user_bob');
    });

    test('Matches candidates by Bio', () {
      final results = UserRepository.filterDiscoverableUsers(
        users: allUsers,
        query: 'intelligent',
        currentUserId: 'user_me',
      );

      expect(results.length, 1);
      expect(results.first.uid, 'user_charlie');
    });

    test('Multi-token search requires all tokens across user fields', () {
      final results = UserRepository.filterDiscoverableUsers(
        users: allUsers,
        query: 'Bob Flutter Stanford',
        currentUserId: 'user_me',
      );

      expect(results.length, 1);
      expect(results.first.uid, 'user_bob');

      final zeroResults = UserRepository.filterDiscoverableUsers(
        users: allUsers,
        query: 'Bob PyTorch',
        currentUserId: 'user_me',
      );
      expect(zeroResults.isEmpty, isTrue);
    });

    test('Returns empty list when no matches exist', () {
      final results = UserRepository.filterDiscoverableUsers(
        users: allUsers,
        query: 'Quantum Astronaut 999',
        currentUserId: 'user_me',
      );

      expect(results.isEmpty, isTrue);
    });
  });

  group('DiscoverPeopleScreen Widget Tests', () {
    late FakeDiscoverUserRepository fakeUserRepo;
    late FakeDiscoverSafetyRepository fakeSafetyRepo;
    late FakeDiscoverConnectionRepo fakeConnectionRepo;

    final candidateUser1 = UserModel(
      uid: 'cand_1',
      name: 'Maya Patel',
      profession: 'Senior iOS Developer',
      skills: ['Swift', 'SwiftUI', 'Combine', 'SwiftData'],
      education: 'UC Berkeley',
      bio: 'Passionate about Apple platform craft',
      linkedInUrl: 'https://linkedin.com/in/mayapatel',
      githubUrl: 'https://github.com/mayapatel',
    );

    final candidateUser2 = UserModel(
      uid: 'cand_2',
      name: 'David Kim',
      profession: 'Full Stack Engineer',
      skills: ['Node.js', 'TypeScript', 'PostgreSQL', 'Flutter'],
      education: 'Georgia Tech',
      bio: 'Open source contributor & mentor',
      githubUrl: 'https://github.com/davidkim',
    );

    setUp(() {
      fakeUserRepo = FakeDiscoverUserRepository();
      fakeUserRepo.community.addAll([candidateUser1, candidateUser2]);

      fakeSafetyRepo = FakeDiscoverSafetyRepository();
      fakeConnectionRepo = FakeDiscoverConnectionRepo();
    });

    Widget createTestWidget({String? currentUserId = 'current_user_123'}) {
      return MaterialApp(
        home: DiscoverPeopleScreen(
          userRepository: fakeUserRepo,
          safetyRepository: fakeSafetyRepo,
          connectionRequestRepository: fakeConnectionRepo,
          currentUserId: currentUserId,
          showAppBar: true,
        ),
      );
    }

    testWidgets('Renders search bar with Apple-minimal styling and profile cards', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify title & search bar
      expect(find.text('Discover People'), findsOneWidget);
      expect(
        find.text('Search people by name, skill, profession...'),
        findsOneWidget,
      );

      // Verify profile cards render candidate details
      expect(find.text('Maya Patel'), findsOneWidget);
      expect(find.text('Senior iOS Developer'), findsOneWidget);
      expect(find.text('SwiftUI'), findsOneWidget);
      expect(find.text('Connect'), findsNWidgets(2));

      expect(find.text('David Kim'), findsOneWidget);
      expect(find.text('Full Stack Engineer'), findsOneWidget);
      expect(find.text('TypeScript'), findsOneWidget);
    });

    testWidgets('Debounced search filters list dynamically', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Maya Patel'), findsOneWidget);
      expect(find.text('David Kim'), findsOneWidget);

      // Enter search term "Swift"
      final searchInput = find.byType(TextField);
      expect(searchInput, findsOneWidget);
      await tester.enterText(searchInput, 'Swift');

      // Before debounce fires (150ms)
      await tester.pump(const Duration(milliseconds: 150));
      // Still showing initial list
      expect(find.text('Maya Patel'), findsOneWidget);

      // After debounce completes (>300ms)
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Only Maya Patel matches "Swift"
      expect(find.text('Maya Patel'), findsOneWidget);
      expect(find.text('David Kim'), findsNothing);
    });

    testWidgets('Displays clean empty state when no people match search', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'NonExistentSkill123');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('No people found'), findsOneWidget);
      expect(
        find.textContaining('Try searching for another name, skill, or profession.'),
        findsOneWidget,
      );
      expect(find.text('Clear Search'), findsOneWidget);

      // Tap clear search
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      // Both people return
      expect(find.text('Maya Patel'), findsOneWidget);
      expect(find.text('David Kim'), findsOneWidget);
    });

    testWidgets('Tapping Connect directly sends connection request and updates button', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap "Connect" on Maya Patel's card
      final connectButtons = find.widgetWithText(ElevatedButton, 'Connect');
      expect(connectButtons, findsNWidgets(2));
      await tester.tap(connectButtons.first);
      await tester.pumpAndSettle();

      // Verify request was sent
      expect(fakeConnectionRepo.sentRequests.length, 1);
      expect(fakeConnectionRepo.sentRequests.first.toUserId, 'cand_1');
      expect(fakeConnectionRepo.sentRequests.first.fromUserId, 'current_user_123');
      expect(fakeConnectionRepo.sentRequests.first.needId, 'direct_discovery');

      // Button updates to "Requested" and SnackBar shows feedback
      expect(find.text('Requested'), findsOneWidget);
      expect(find.text('Connection request sent to Maya Patel.'), findsOneWidget);
    });

    testWidgets('Tapping profile card opens ProfileScreen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Maya Patel's card
      await tester.tap(find.text('Maya Patel'));
      await tester.pumpAndSettle();

      // Verifies ProfileScreen was pushed
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('Displays error state with retry on network failure', (tester) async {
      fakeUserRepo.shouldFail = true;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Could not load people. Please check connection.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);

      fakeUserRepo.shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Maya Patel'), findsOneWidget);
    });
  });
}
