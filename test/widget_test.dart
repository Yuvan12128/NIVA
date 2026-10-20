import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niva/app/niva_app.dart';
import 'package:niva/features/chat/data/chat_model.dart';
import 'package:niva/features/chat/data/chat_repository.dart';
import 'package:niva/features/chat/data/message_model.dart';
import 'package:niva/features/connect/data/connection_request_model.dart';
import 'package:niva/features/connect/data/connection_request_repository.dart';
import 'package:niva/features/explore/data/discovery_model.dart';
import 'package:niva/features/explore/data/search_filter_model.dart';
import 'package:niva/features/explore/data/search_service.dart';
import 'package:niva/features/matching/data/matching_service.dart';
import 'package:niva/features/navigation/presentation/main_navigation_shell.dart';
import 'package:niva/features/navigation/presentation/widgets/create_need_sheet.dart';
import 'package:niva/features/needs/data/need_model.dart';
import 'package:niva/features/notifications/data/notification_model.dart';
import 'package:niva/features/notifications/data/notification_repository.dart';
import 'package:niva/features/reviews/data/review_model.dart';
import 'package:niva/features/reviews/data/review_repository.dart';
import 'package:niva/features/safety/data/blocked_user_model.dart';
import 'package:niva/features/safety/data/report_model.dart';
import 'package:niva/features/safety/data/safety_repository.dart';
import 'package:niva/features/splash/presentation/logo_reveal_screen.dart';
import 'package:niva/features/user/data/user_model.dart';

void main() {
  group('Authentication & User Model Unit Tests', () {
    test('UserModel serializes and deserializes correctly', () {
      final user = UserModel(
        uid: 'test_uid_123',
        name: 'Arun Kumar',
        email: 'arun@example.com',
        country: 'India',
        state: 'Tamil Nadu',
        city: 'Chennai',
        language: 'English',
        role: 'member',
        skills: const ['Flutter', 'Dart'],
        canHelpWith: const ['Mobile Architecture'],
        lookingFor: const ['Java Mentor'],
        availability: 'Available',
        trustScore: 100,
        createdAt: DateTime(2026, 1, 1),
      );

      final publicMap = user.toMap(useServerTimestamp: false);
      expect(publicMap['name'], 'Arun Kumar');
      expect(publicMap.containsKey('email'), isFalse);
      expect(publicMap['city'], 'Chennai');
      expect(publicMap['trustScore'], 100);

      final privateMap = user.toMap(
        useServerTimestamp: false,
        includeEmail: true,
      );
      expect(privateMap['email'], 'arun@example.com');

      final deserialized = UserModel.fromMap('test_uid_123', publicMap);
      expect(deserialized.uid, 'test_uid_123');
      expect(deserialized.name, 'Arun Kumar');
      expect(deserialized.skills, ['Flutter', 'Dart']);
      expect(deserialized.trustScore, 100);
    });
  });

  group('Authentication Flow Widget Tests', () {
    testWidgets('Unauthenticated user is presented with LoginScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(NivaApp(authStateStream: Stream.value(null)));
      await tester.pumpAndSettle();

      // Verify login UI
      expect(find.text('Sign in to your account'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Login validation displays error when fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(NivaApp(authStateStream: Stream.value(null)));
      await tester.pumpAndSettle();

      // Tap Sign In with empty fields
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify validation error
      expect(
        find.text('Please enter both email and password.'),
        findsOneWidget,
      );
    });

    testWidgets('Navigation switches between Login and SignUp screens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(NivaApp(authStateStream: Stream.value(null)));
      await tester.pumpAndSettle();

      // Tap Create Account
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Verify SignUp screen appears
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Approximate City / Region'), findsOneWidget);

      // Scroll to and tap Sign In to switch back
      await tester.ensureVisible(find.text('Sign In'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify returned to Login
      expect(find.text('Sign in to your account'), findsOneWidget);
    });
  });

  group('Main Discovery Screens Widget Tests', () {
    testWidgets('NIVA app loads and displays home screen discovery elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const NivaApp(homeOverride: MainNavigationShell()),
      );
      await tester.pumpAndSettle();

      // Verify NIVA branding and core question
      expect(find.text('NIVA'), findsOneWidget);
      expect(find.text('What do you need today?'), findsWidgets);

      // Verify core discovery categories exist
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Information'), findsOneWidget);
      expect(find.text('Opportunities'), findsOneWidget);
      expect(find.text('Communities'), findsOneWidget);
      expect(find.text('I Can Help'), findsOneWidget);

      // Verify recommendations section header
      expect(find.text('Recommended for you'), findsOneWidget);
    });

    testWidgets(
      'NIVA app navigates to Explore screen and displays search and categories',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const NivaApp(homeOverride: MainNavigationShell()),
        );
        await tester.pumpAndSettle();

        // Tap Explore tab in the bottom bar
        await tester.tap(find.text('Explore'));
        await tester.pumpAndSettle();

        // Verify Explore header & search
        expect(
          find.text('Discover people, knowledge, opportunities and more.'),
          findsOneWidget,
        );
        expect(find.text('Search anything...'), findsOneWidget);

        // Verify suggested discoveries header
        expect(find.text('Suggested Discoveries'), findsOneWidget);
        expect(find.text('Java & Algorithms Mentorship'), findsOneWidget);
      },
    );

    testWidgets('NIVA app opens Create sheet and completes I Need flow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const NivaApp(homeOverride: MainNavigationShell()),
      );
      await tester.pumpAndSettle();

      // Tap central Create (+) button
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      // Verify sheet title and dual choices
      expect(find.text('What can NIVA help you with?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CreateNeedSheet),
          matching: find.text('I Need'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(CreateNeedSheet),
          matching: find.text('I Can Help'),
        ),
        findsOneWidget,
      );

      // Tap "I Need" option inside sheet
      await tester.tap(
        find.descendant(
          of: find.byType(CreateNeedSheet),
          matching: find.text('I Need'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify I Need form appears
      expect(find.text('What do you need?'), findsOneWidget);
      expect(find.text('What are you looking for?'), findsOneWidget);

      // Select an example chip
      await tester.tap(find.text('I need a Java tutor'));
      await tester.pumpAndSettle();

      // Scroll to and tap Continue
      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify success state
      expect(find.text('Need Published!'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });

    testWidgets('NIVA app opens Create sheet and completes I Can Help flow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const NivaApp(homeOverride: MainNavigationShell()),
      );
      await tester.pumpAndSettle();

      // Tap central Create (+) button
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      // Tap "I Can Help" option inside sheet
      await tester.tap(
        find.descendant(
          of: find.byType(CreateNeedSheet),
          matching: find.text('I Can Help'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify I Can Help form appears
      expect(find.text('What can you help with?'), findsOneWidget);
      expect(find.text('What can you offer?'), findsOneWidget);

      // Select an example chip
      await tester.tap(find.text('I can teach Java'));
      await tester.pumpAndSettle();

      // Scroll to and tap Continue
      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify success state
      expect(find.text('Capability Shared!'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'NIVA app navigates to Profile screen and displays dual identity sections',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const NivaApp(homeOverride: MainNavigationShell()),
        );
        await tester.pumpAndSettle();

        // Tap Profile tab in the bottom bar
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // Verify Profile header & name
        expect(find.text('Arun Kumar'), findsOneWidget);
        expect(find.text('Edit Profile'), findsOneWidget);

        // Verify Trust, I Need, and I Can Help sections
        expect(find.text('Trust & Verification'), findsOneWidget);
        expect(find.text('I Need'), findsOneWidget);
        expect(find.text('I Can Help With'), findsOneWidget);
      },
    );
  });

  group('Need Model & Data Mapping Unit Tests', () {
    test('NeedModel serializes to map correctly', () {
      final need = NeedModel(
        needId: 'need_001',
        userId: 'user_xyz',
        type: 'need',
        title: 'Need a Flutter mentor',
        description: 'Looking for architecture guidance',
        category: 'Technology',
        skills: const ['Flutter', 'Clean Architecture'],
        location: 'Chennai',
        urgency: 'This week',
        budget: '₹2,000',
        authorName: 'Arun',
        createdAt: DateTime(2026, 3, 15),
      );

      final map = need.toMap(useServerTimestamp: false);
      expect(map['userId'], 'user_xyz');
      expect(map['type'], 'need');
      expect(map['title'], 'Need a Flutter mentor');
      expect(map['description'], 'Looking for architecture guidance');
      expect(map['category'], 'Technology');
      expect(map['skills'], ['Flutter', 'Clean Architecture']);
      expect(map['location'], 'Chennai');
      expect(map['urgency'], 'This week');
      expect(map['budget'], '₹2,000');
      expect(map['authorName'], 'Arun');
      expect(map['status'], 'active');
    });

    test('NeedModel deserializes from map correctly', () {
      final data = {
        'userId': 'user_abc',
        'type': 'help',
        'title': 'I can teach Java',
        'description': 'Beginner to advanced DSA in Java',
        'category': 'Education',
        'skills': ['Java', 'Algorithms'],
        'location': 'Remote',
        'urgency': 'Flexible',
        'availability': 'Weekends',
        'status': 'active',
        'authorName': 'Priya',
      };

      final need = NeedModel.fromMap('need_002', data);
      expect(need.needId, 'need_002');
      expect(need.userId, 'user_abc');
      expect(need.type, 'help');
      expect(need.title, 'I can teach Java');
      expect(need.category, 'Education');
      expect(need.skills, ['Java', 'Algorithms']);
      expect(need.availability, 'Weekends');
      expect(need.authorName, 'Priya');
      expect(need.status, 'active');
    });

    test('NeedModel copyWith updates fields properly', () {
      const need = NeedModel(
        needId: '1',
        userId: 'u1',
        type: 'need',
        title: 'Old title',
        description: 'Old desc',
        category: 'Tech',
      );

      final updated = need.copyWith(title: 'New title', status: 'closed');
      expect(updated.title, 'New title');
      expect(updated.status, 'closed');
      expect(updated.userId, 'u1');
    });
  });

  group('Matching V1 Rule-Based Scoring Tests', () {
    const testNeed = NeedModel(
      needId: 'need_100',
      userId: 'user_seeker',
      type: 'need',
      title: 'Looking for a Java tutor',
      description: 'Need assistance with Java and DSA',
      category: 'Education',
      skills: ['Java', 'DSA'],
      location: 'Chennai',
      urgency: 'Urgent',
    );

    test(
      'Matching score accurately calculates weights and high-match candidate',
      () {
        final match = MatchingService.computeMatchScore(
          need: testNeed,
          candidateSkills: ['Java', 'Algorithms', 'DSA'],
          candidateLocation: 'Chennai',
          candidateAvailability: 'Available today',
          candidateCategory: 'Education',
          candidateTrustScore: 100,
        );

        // Max weights: Skill 40, Location 20, Availability 15, Category 15, Trust 10 = 100
        expect(
          match.skillScore,
          greaterThanOrEqualTo(35.0),
        ); // high skill overlap
        expect(match.locationScore, 20.0); // exact location match
        expect(
          match.availabilityScore,
          15.0,
        ); // available today for urgent need
        expect(match.categoryScore, 15.0); // exact category match
        expect(match.trustScore, 10.0); // 100% trust
        expect(match.totalScore, greaterThanOrEqualTo(90.0));
        expect(match.matchedSkills, contains('Java'));
      },
    );

    test(
      'Low-match candidate receives proportionally lower component scores',
      () {
        final lowMatch = MatchingService.computeMatchScore(
          need: testNeed,
          candidateSkills: ['Photoshop', 'Video Editing'],
          candidateLocation: 'Mumbai',
          candidateAvailability: 'Weekends',
          candidateCategory: 'Creative',
          candidateTrustScore: 80,
        );

        expect(lowMatch.skillScore, 0.0); // no skill overlap
        expect(
          lowMatch.locationScore,
          lessThan(10.0),
        ); // different physical city
        expect(
          lowMatch.availabilityScore,
          lessThan(10.0),
        ); // weekends vs urgent
        expect(lowMatch.categoryScore, lessThan(5.0)); // Creative vs Education
        expect(lowMatch.trustScore, 8.0); // 80/100 * 10
        expect(lowMatch.totalScore, lessThan(30.0));
      },
    );

    test('Remote location relevance gives high compatibility', () {
      final remoteMatch = MatchingService.computeMatchScore(
        need: testNeed.copyWith(location: 'Remote'),
        candidateSkills: ['Java'],
        candidateLocation: 'Remote',
        candidateAvailability: 'Available today',
        candidateCategory: 'Education',
        candidateTrustScore: 100,
      );

      expect(remoteMatch.locationScore, 20.0); // Both remote = full 20 points
    });

    test('Candidates are ranked strictly by highest score first', () {
      final candidateHigh = MatchingService.computeMatchScore(
        need: testNeed,
        candidateSkills: ['Java', 'DSA'],
        candidateLocation: 'Chennai',
        candidateAvailability: 'Available today',
        candidateCategory: 'Education',
        candidateTrustScore: 100,
      );

      final candidateLow = MatchingService.computeMatchScore(
        need: testNeed,
        candidateSkills: ['Marketing'],
        candidateLocation: 'Delhi',
        candidateAvailability: 'Weekends',
        candidateCategory: 'Services',
        candidateTrustScore: 70,
      );

      final ranked = [candidateLow.totalScore, candidateHigh.totalScore]
        ..sort((a, b) => b.compareTo(a));
      expect(ranked.first, candidateHigh.totalScore);
      expect(candidateHigh.totalScore, greaterThan(candidateLow.totalScore));
    });
  });

  group('Connect Request V1 Unit Tests', () {
    test('ConnectionRequestModel serializes and deserializes correctly', () {
      final req = ConnectionRequestModel(
        id: 'req_123',
        fromUserId: 'seeker_1',
        toUserId: 'helper_1',
        needId: 'need_99',
        status: 'pending',
        createdAt: DateTime(2026, 3, 20),
      );

      final map = req.toMap(useServerTimestamp: false);
      expect(map['fromUserId'], 'seeker_1');
      expect(map['toUserId'], 'helper_1');
      expect(map['needId'], 'need_99');
      expect(map['status'], 'pending');

      final deserialized = ConnectionRequestModel.fromMap('req_123', map);
      expect(deserialized.id, 'req_123');
      expect(deserialized.fromUserId, 'seeker_1');
      expect(deserialized.toUserId, 'helper_1');
      expect(deserialized.needId, 'need_99');
      expect(deserialized.status, 'pending');
    });

    test('sendConnectRequest throws ArgumentError when user sends request to themselves', () async {
      final repo = ConnectionRequestRepository();
      expect(
        () => repo.sendConnectRequest(
          fromUserId: 'same_user',
          toUserId: 'same_user',
          needId: 'need_1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'respondToRequest throws ArgumentError when status is invalid',
      () async {
        final repo = ConnectionRequestRepository();
        expect(
          () => repo.respondToRequest(
            requestId: 'req_1',
            responderUserId: 'user_2',
            status: 'invalid_status',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });

  group('Chat V1 Unit Tests', () {
    test('generateChatId generates deterministic sorted chat ID', () {
      final id1 = ChatRepository.generateChatId('user_b', 'user_a');
      final id2 = ChatRepository.generateChatId('user_a', 'user_b');

      expect(id1, 'user_a_user_b');
      expect(id2, 'user_a_user_b');
      expect(id1, id2);
    });

    test(
      'generateChatId throws ArgumentError for empty or identical users',
      () {
        expect(
          () => ChatRepository.generateChatId('user_a', 'user_a'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => ChatRepository.generateChatId('', 'user_b'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('MessageModel serializes and deserializes correctly', () {
      final msg = MessageModel(
        id: 'msg_001',
        chatId: 'user_a_user_b',
        senderId: 'user_a',
        receiverId: 'user_b',
        text: 'Hello! I saw your need.',
        createdAt: DateTime(2026, 4, 1, 10, 30),
      );

      final map = msg.toMap(useServerTimestamp: false);
      expect(map['chatId'], 'user_a_user_b');
      expect(map['senderId'], 'user_a');
      expect(map['receiverId'], 'user_b');
      expect(map['text'], 'Hello! I saw your need.');

      final fromMap = MessageModel.fromMap('msg_001', map);
      expect(fromMap.id, 'msg_001');
      expect(fromMap.text, 'Hello! I saw your need.');
      expect(fromMap.senderId, 'user_a');
    });

    test('ChatModel helper methods resolve other user correctly', () {
      const chat = ChatModel(
        id: 'u1_u2',
        participantIds: ['u1', 'u2'],
        needId: 'n1',
        connectionRequestId: 'cr1',
        participantNames: {'u1': 'Alice', 'u2': 'Bob'},
      );

      expect(chat.getOtherUserId('u1'), 'u2');
      expect(chat.getOtherUserId('u2'), 'u1');
      expect(chat.getOtherUserName('u1'), 'Bob');
      expect(chat.getOtherUserName('u2'), 'Alice');
    });

    test(
      'sendMessage validates empty text and identical participants',
      () async {
        final repo = ChatRepository();
        expect(
          () => repo.sendMessage(
            chatId: 'c1',
            senderId: 'u1',
            receiverId: 'u2',
            text: '   ',
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => repo.sendMessage(
            chatId: 'c1',
            senderId: 'u1',
            receiverId: 'u1',
            text: 'Valid text',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });

  group('Notifications V1 Unit Tests', () {
    test('NotificationModel serializes and deserializes correctly', () {
      final notif = NotificationModel(
        id: 'notif_001',
        recipientId: 'user_recipient',
        senderId: 'user_sender',
        type: 'connection_request',
        title: 'New Connection Request',
        body: 'Someone wants to connect with you.',
        referenceId: 'req_123',
        isRead: false,
        createdAt: DateTime(2026, 4, 1, 12, 0),
      );

      final map = notif.toMap(useServerTimestamp: false);
      expect(map['recipientId'], 'user_recipient');
      expect(map['senderId'], 'user_sender');
      expect(map['type'], 'connection_request');
      expect(map['title'], 'New Connection Request');
      expect(map['body'], 'Someone wants to connect with you.');
      expect(map['referenceId'], 'req_123');
      expect(map['isRead'], false);

      final fromMap = NotificationModel.fromMap('notif_001', map);
      expect(fromMap.id, 'notif_001');
      expect(fromMap.recipientId, 'user_recipient');
      expect(fromMap.type, 'connection_request');
      expect(fromMap.isRead, false);
    });

    test('NotificationModel copyWith updates read status', () {
      const notif = NotificationModel(
        id: 'n1',
        recipientId: 'r1',
        senderId: 's1',
        type: 'new_message',
        title: 'New Message',
        body: 'Hello',
        referenceId: 'c1',
      );

      final readNotif = notif.copyWith(isRead: true);
      expect(readNotif.isRead, true);
      expect(readNotif.id, 'n1');
    });

    test(
      'createNotification validates type and prevents self-notification',
      () async {
        final repo = NotificationRepository();
        // Self-notification check
        expect(
          () => repo.createNotification(
            recipientId: 'same_user',
            senderId: 'same_user',
            type: 'connection_request',
            title: 'Title',
            body: 'Body',
            referenceId: 'ref_1',
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Invalid type check
        expect(
          () => repo.createNotification(
            recipientId: 'r_user',
            senderId: 's_user',
            type: 'invalid_type',
            title: 'Title',
            body: 'Body',
            referenceId: 'ref_1',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });

  group('Trust & Reviews V1 Unit Tests', () {
    test('calculateTrustScore maps ratings deterministically', () {
      expect(ReviewRepository.calculateTrustScore([]), 100);
      expect(ReviewRepository.calculateTrustScore([5, 5, 5]), 100);
      expect(ReviewRepository.calculateTrustScore([4, 4]), 80);
      expect(ReviewRepository.calculateTrustScore([5, 4]), 90);
      expect(ReviewRepository.calculateTrustScore([3]), 60);
      expect(ReviewRepository.calculateTrustScore([1]), 20);
    });

    test('ReviewModel serializes and deserializes correctly', () {
      final review = ReviewModel(
        id: 'rev_100',
        connectionRequestId: 'req_001',
        needId: 'need_001',
        reviewerId: 'user_a',
        revieweeId: 'user_b',
        rating: 5,
        reviewText: 'Exceptional assistance with Java concurrency!',
        createdAt: DateTime(2026, 4, 1, 14, 0),
      );

      final map = review.toMap(useServerTimestamp: false);
      expect(map['connectionRequestId'], 'req_001');
      expect(map['needId'], 'need_001');
      expect(map['reviewerId'], 'user_a');
      expect(map['revieweeId'], 'user_b');
      expect(map['rating'], 5);
      expect(
        map['reviewText'],
        'Exceptional assistance with Java concurrency!',
      );

      final fromMap = ReviewModel.fromMap('rev_100', map);
      expect(fromMap.id, 'rev_100');
      expect(fromMap.rating, 5);
      expect(
        fromMap.reviewText,
        'Exceptional assistance with Java concurrency!',
      );
    });

    test('submitReview validates ratings boundaries and self-review', () async {
      final repo = ReviewRepository();

      // Self review check
      expect(
        () => repo.submitReview(
          connectionRequestId: 'req_1',
          needId: 'need_1',
          reviewerId: 'user_same',
          revieweeId: 'user_same',
          rating: 5,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Rating boundary checks
      expect(
        () => repo.submitReview(
          connectionRequestId: 'req_1',
          needId: 'need_1',
          reviewerId: 'user_a',
          revieweeId: 'user_b',
          rating: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => repo.submitReview(
          connectionRequestId: 'req_1',
          needId: 'need_1',
          reviewerId: 'user_a',
          revieweeId: 'user_b',
          rating: 6,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Text length check
      expect(
        () => repo.submitReview(
          connectionRequestId: 'req_1',
          needId: 'need_1',
          reviewerId: 'user_a',
          revieweeId: 'user_b',
          rating: 5,
          reviewText: 'a' * 501,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Search & Filters V1 Unit Tests', () {
    const candidate1 = DiscoveryModel(
      id: 'c1',
      title: 'Java & Spring Boot Tutoring',
      type: DiscoveryType.people,
      itemType: 'help',
      category: 'People',
      description: 'Experienced backend mentor teaching core Java, collections, and REST APIs.',
      location: 'Chennai',
      meta: 'Available today',
      actionLabel: 'Connect',
      skills: ['Java', 'Spring Boot', 'Backend'],
      availability: 'Available today',
      trustScore: 100,
      createdAt: null,
    );

    const candidate2 = DiscoveryModel(
      id: 'c2',
      title: 'Laptop Repair & Thermal Service',
      type: DiscoveryType.services,
      itemType: 'help',
      category: 'Services',
      description: 'Quick hardware diagnostics, chip-level laptop repair, and motherboard maintenance.',
      location: 'Chennai',
      meta: 'Available today',
      actionLabel: 'Request',
      skills: ['Laptop repair', 'Hardware', 'Motherboard'],
      availability: 'Available today',
      trustScore: 99,
      createdAt: null,
    );

    const candidate3 = DiscoveryModel(
      id: 'c3',
      title: 'React & Mobile Guild',
      type: DiscoveryType.communities,
      itemType: 'community',
      category: 'Communities',
      description: 'Peer group of React and Flutter mobile engineers sharing architectures.',
      location: 'Remote',
      meta: '2.8k members',
      actionLabel: 'Join',
      skills: ['React', 'Mobile', 'Frontend'],
      availability: 'Flexible',
      trustScore: 95,
      createdAt: null,
    );

    const candidate4 = DiscoveryModel(
      id: 'c4',
      title: 'Need a Graphic Designer for NGO Brand',
      type: DiscoveryType.services,
      itemType: 'need',
      category: 'Services',
      description: 'Looking for a volunteer graphic designer to craft logos and campaign banners.',
      location: 'Remote',
      meta: 'Urgent',
      actionLabel: 'Offer Help',
      skills: ['Graphic designer', 'Figma', 'Branding'],
      availability: 'Weekends',
      trustScore: 90,
      createdAt: null,
    );

    final allCandidates = [candidate1, candidate2, candidate3, candidate4];

    test('calculateMatchScore accurately matches exact title, skills, description, and keywords', () {
      final scoreTitle = SearchService.calculateMatchScore(
        item: candidate1,
        query: 'Java & Spring Boot Tutoring',
      );
      expect(scoreTitle, greaterThanOrEqualTo(150));

      final scoreSkill = SearchService.calculateMatchScore(
        item: candidate2,
        query: 'Laptop repair',
      );
      expect(scoreSkill, greaterThanOrEqualTo(100));

      final scoreToken = SearchService.calculateMatchScore(
        item: candidate3,
        query: 'mobile developer',
      );
      expect(scoreToken, greaterThan(0));

      final scoreMismatch = SearchService.calculateMatchScore(
        item: candidate1,
        query: 'plumbing architecture',
      );
      expect(scoreMismatch, equals(0));
    });

    test(
      'search matching is strictly case-insensitive and normalizes whitespace',
      () {
        final scoreUpper = SearchService.calculateMatchScore(
          item: candidate1,
          query: '  JAVA TUTORING  ',
        );
        final scoreLower = SearchService.calculateMatchScore(
          item: candidate1,
          query: 'java tutoring',
        );
        expect(scoreUpper, equals(scoreLower));
        expect(scoreUpper, greaterThan(0));

        final results = SearchService.filterAndRank(
          candidates: allCandidates,
          query: 'LAPTOP REPAIR',
          filter: SearchFilter.empty,
        );
        expect(results.length, equals(1));
        expect(results.first.id, equals('c2'));
      },
    );

    test(
      'empty query returns all items without filtering out valid candidates',
      () {
        final results = SearchService.filterAndRank(
          candidates: allCandidates,
          query: '',
          filter: SearchFilter.empty,
        );
        expect(results.length, equals(allCandidates.length));
      },
    );

    test('category filter accurately selects only matching DiscoveryType', () {
      final servicesOnly = SearchService.filterAndRank(
        candidates: allCandidates,
        query: '',
        filter: const SearchFilter(category: DiscoveryType.services),
      );
      expect(servicesOnly.length, equals(2));
      expect(
        servicesOnly.every((i) => i.type == DiscoveryType.services),
        isTrue,
      );

      final communitiesOnly = SearchService.filterAndRank(
        candidates: allCandidates,
        query: '',
        filter: const SearchFilter(category: DiscoveryType.communities),
      );
      expect(communitiesOnly.length, equals(1));
      expect(communitiesOnly.first.id, equals('c3'));
    });

    test('location filter matches specific locations and remote options', () {
      final remoteOnly = SearchService.filterAndRank(
        candidates: allCandidates,
        query: '',
        filter: const SearchFilter(location: 'Remote'),
      );
      expect(remoteOnly.length, equals(2));
      expect(remoteOnly.every((i) => i.location == 'Remote'), isTrue);

      final chennaiOnly = SearchService.filterAndRank(
        candidates: allCandidates,
        query: '',
        filter: const SearchFilter(location: 'Chennai'),
      );
      expect(chennaiOnly.length, equals(2));
      expect(chennaiOnly.every((i) => i.location == 'Chennai'), isTrue);

      final noneFound = SearchService.filterAndRank(
        candidates: allCandidates,
        query: '',
        filter: const SearchFilter(location: 'Mumbai'),
      );
      expect(noneFound, isEmpty);
    });

    test(
      'type filter accurately distinguishes between need and help items',
      () {
        final needsOnly = SearchService.filterAndRank(
          candidates: allCandidates,
          query: '',
          filter: const SearchFilter(type: 'need'),
        );
        expect(needsOnly.length, equals(1));
        expect(needsOnly.first.id, equals('c4'));

        final helpOnly = SearchService.filterAndRank(
          candidates: allCandidates,
          query: '',
          filter: const SearchFilter(type: 'help'),
        );
        expect(helpOnly.length, equals(2));
        expect(helpOnly.every((i) => i.itemType == 'help'), isTrue);
      },
    );

    test('availability filter matches availability options accurately', () {
      final todayOnly = SearchService.filterAndRank(
        candidates: allCandidates,
        query: '',
        filter: const SearchFilter(availability: 'Available today'),
      );
      expect(todayOnly.length, equals(2));

      final weekendOnly = SearchService.filterAndRank(
        candidates: allCandidates,
        query: '',
        filter: const SearchFilter(availability: 'Weekends'),
      );
      expect(weekendOnly.length, equals(1));
      expect(weekendOnly.first.id, equals('c4'));
    });

    test('combined multi-facet filters narrow down candidates accurately', () {
      // Category: Services + Type: Help + Location: Chennai + Availability: Available today
      final combined = SearchService.filterAndRank(
        candidates: allCandidates,
        query: '',
        filter: const SearchFilter(
          category: DiscoveryType.services,
          type: 'help',
          location: 'Chennai',
          availability: 'Available today',
        ),
      );
      expect(combined.length, equals(1));
      expect(combined.first.id, equals('c2'));
    });

    test('search result ranking orders exact title and skill matches above partial matches', () {
      final ranked = SearchService.filterAndRank(
        candidates: allCandidates,
        query: 'Graphic designer',
        filter: SearchFilter.empty,
      );
      expect(ranked.isNotEmpty, isTrue);
      expect(ranked.first.id, equals('c4'));
    });

    test('filterAndRank enforces candidate result limits', () {
      final limited = SearchService.filterAndRank(
        candidates: allCandidates,
        query: '',
        filter: SearchFilter.empty,
        limit: 2,
      );
      expect(limited.length, equals(2));
    });

    test('SearchFilter model equality, copyWith and active count calculate correctly', () {
      const filter = SearchFilter(
        category: DiscoveryType.people,
        location: 'Remote',
        type: 'help',
        availability: 'Flexible',
        sortBy: SearchSortBy.recent,
      );

      expect(filter.hasActiveFilters, isTrue);
      expect(filter.activeFiltersCount, equals(5));

      final updated = filter.copyWith(
        category: () => null,
        sortBy: SearchSortBy.relevance,
      );
      expect(updated.category, isNull);
      expect(updated.sortBy, equals(SearchSortBy.relevance));
      expect(updated.activeFiltersCount, equals(3));

      expect(SearchFilter.empty.hasActiveFilters, isFalse);
      expect(SearchFilter.empty.activeFiltersCount, equals(0));
    });
  });

  group('Safety V1 Unit Tests', () {
    setUp(() {
      SafetyRepository.clearCache();
    });

    test(
      'BlockedUserModel and ReportModel serialize and deserialize accurately',
      () {
        final block = BlockedUserModel(
          id: 'userA_userB',
          blockerId: 'userA',
          blockedUserId: 'userB',
          createdAt: DateTime(2026, 3, 1),
        );
        final blockMap = block.toMap(useServerTimestamp: false);
        expect(blockMap['blockerId'], equals('userA'));
        expect(blockMap['blockedUserId'], equals('userB'));

        final fromBlock = BlockedUserModel.fromMap('userA_userB', {
          'blockerId': 'userA',
          'blockedUserId': 'userB',
        });
        expect(fromBlock.id, equals('userA_userB'));

        final report = ReportModel(
          id: 'rep_123',
          reporterId: 'user1',
          reportedUserId: 'user2',
          reason: 'harassment',
          description: 'Offensive language in connection offer',
          referenceId: 'chat_123',
          status: 'submitted',
          createdAt: DateTime(2026, 3, 1),
        );
        final reportMap = report.toMap(useServerTimestamp: false);
        expect(reportMap['reporterId'], equals('user1'));
        expect(reportMap['reason'], equals('harassment'));
        expect(
          reportMap['description'],
          equals('Offensive language in connection offer'),
        );

        final fromReport = ReportModel.fromMap('rep_123', {
          'reporterId': 'user1',
          'reportedUserId': 'user2',
          'reason': 'harassment',
        });
        expect(fromReport.reason, equals('harassment'));
      },
    );

    test('blockUser prevents self-block and validates user IDs', () {
      final safety = SafetyRepository();
      expect(
        () => safety.blockUser(blockerId: 'user1', blockedUserId: 'user1'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => safety.blockUser(blockerId: '', blockedUserId: 'user2'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('blockUser, unblock, and isBlocked track relationships in memory and cache', () async {
      final safety = SafetyRepository();
      expect(await safety.isBlocked(userA: 'userA', userB: 'userB'), isFalse);

      await safety.blockUser(blockerId: 'userA', blockedUserId: 'userB');
      expect(await safety.isBlocked(userA: 'userA', userB: 'userB'), isTrue);
      // Symmetrical block respect
      expect(await safety.isBlocked(userA: 'userB', userB: 'userA'), isTrue);

      await safety.unblockUser(blockerId: 'userA', blockedUserId: 'userB');
      expect(await safety.isBlocked(userA: 'userA', userB: 'userB'), isFalse);
    });

    test('reportUser validates self-report, allowed reasons, and description length', () {
      final safety = SafetyRepository();
      // Self-report prevention
      expect(
        () => safety.reportUser(
          reporterId: 'userA',
          reportedUserId: 'userA',
          reason: 'spam',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Invalid reason prevention
      expect(
        () => safety.reportUser(
          reporterId: 'userA',
          reportedUserId: 'userB',
          reason: 'not_a_valid_reason',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Max 500 characters description check
      expect(
        () => safety.reportUser(
          reporterId: 'userA',
          reportedUserId: 'userB',
          reason: 'spam',
          description: 'a' * 501,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('SearchService excludes blocked user IDs from discovery and search results', () {
      const candidate1 = DiscoveryModel(
        id: 'c1',
        title: 'Java Mentorship',
        type: DiscoveryType.people,
        itemType: 'help',
        category: 'People',
        authorId: 'blocked_user_99',
        description: 'Java tutoring',
        location: 'Chennai',
        meta: 'Available',
        actionLabel: 'Connect',
      );

      const candidate2 = DiscoveryModel(
        id: 'c2',
        title: 'Flutter Help',
        type: DiscoveryType.people,
        itemType: 'help',
        category: 'People',
        authorId: 'clean_user_1',
        description: 'Flutter assistance',
        location: 'Remote',
        meta: 'Available',
        actionLabel: 'Connect',
      );

      final results = SearchService.filterAndRank(
        candidates: [candidate1, candidate2],
        query: '',
        filter: SearchFilter.empty,
        blockedUserIds: {'blocked_user_99'},
      );

      expect(results.length, equals(1));
      expect(results.first.id, equals('c2'));
    });

    test('ConnectionRequestRepository prevents connection request when relationship is blocked', () async {
      final safety = SafetyRepository();
      await safety.blockUser(blockerId: 'userA', blockedUserId: 'userB');

      final connectRepo = ConnectionRequestRepository(safetyRepository: safety);

      expect(
        () => connectRepo.sendConnectRequest(
          fromUserId: 'userA',
          toUserId: 'userB',
          needId: 'need_123',
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        () => connectRepo.sendConnectRequest(
          fromUserId: 'userB',
          toUserId: 'userA',
          needId: 'need_123',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('ChatRepository prevents sending messages when participant relationship is blocked', () async {
      final safety = SafetyRepository();
      await safety.blockUser(blockerId: 'userA', blockedUserId: 'userB');

      final chatRepo = ChatRepository(safetyRepository: safety);

      expect(
        () => chatRepo.sendMessage(
          chatId: 'userA_userB',
          senderId: 'userA',
          receiverId: 'userB',
          text: 'Hello there',
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        () => chatRepo.sendMessage(
          chatId: 'userA_userB',
          senderId: 'userB',
          receiverId: 'userA',
          text: 'Hello back',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Logo Reveal Animation Tests', () {
    testWidgets('LogoRevealScreen renders and triggers onComplete', (
      WidgetTester tester,
    ) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LogoRevealScreen(
            onComplete: () => completed = true,
            duration: const Duration(milliseconds: 500),
          ),
        ),
      );

      // Initially onComplete has not been called
      expect(completed, isFalse);

      // Advance time beyond duration
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('LogoRevealScreen allows instant tap-to-skip', (
      WidgetTester tester,
    ) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LogoRevealScreen(
            onComplete: () => completed = true,
            duration: const Duration(milliseconds: 1000),
          ),
        ),
      );

      expect(completed, isFalse);

      // Tap on screen to skip
      await tester.tap(find.byType(LogoRevealScreen));
      await tester.pump();

      expect(completed, isTrue);
    });

    testWidgets(
      'LogoRevealScreen renders cleanly without overflow on narrow 320px screens',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(home: LogoRevealScreen(onComplete: () {})),
        );

        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
