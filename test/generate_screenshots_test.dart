import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niva/core/theme/app_theme.dart';
import 'package:niva/features/auth/presentation/login_screen.dart';
import 'package:niva/features/auth/presentation/signup_screen.dart';
import 'package:niva/features/chat/data/chat_model.dart';
import 'package:niva/features/chat/data/chat_repository.dart';
import 'package:niva/features/chat/data/message_model.dart';
import 'package:niva/features/chat/presentation/chat_screen.dart';
import 'package:niva/features/chat/presentation/conversation_screen.dart';
import 'package:niva/features/explore/data/search_filter_model.dart';
import 'package:niva/features/explore/presentation/explore_screen.dart';
import 'package:niva/features/explore/presentation/widgets/filter_bottom_sheet.dart';
import 'package:niva/features/matching/presentation/widgets/matching_sheet.dart';
import 'package:niva/features/navigation/presentation/main_navigation_shell.dart';
import 'package:niva/features/navigation/presentation/widgets/create_need_sheet.dart';
import 'package:niva/features/needs/data/need_model.dart';
import 'package:niva/features/notifications/data/notification_model.dart';
import 'package:niva/features/notifications/data/notification_repository.dart';
import 'package:niva/features/notifications/presentation/notifications_screen.dart';
import 'package:niva/features/profile/presentation/profile_screen.dart';
import 'package:niva/features/reviews/presentation/widgets/review_sheet.dart';
import 'package:niva/features/safety/presentation/widgets/report_sheet.dart';
import 'package:niva/features/splash/presentation/logo_reveal_screen.dart';

class FakeChatRepository extends ChatRepository {
  @override
  Future<List<ChatModel>> getUserChats(String userId, {int limit = 20}) async {
    return [
      ChatModel(
        id: 'chat_userA_userB',
        participantIds: const ['userA', 'userB'],
        needId: 'need_123',
        connectionRequestId: 'req_123',
        lastMessage: 'Looking forward to collaborating on Flutter architecture!',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 15)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ChatModel(
        id: 'chat_userA_userC',
        participantIds: const ['userA', 'userC'],
        needId: 'need_456',
        connectionRequestId: 'req_456',
        lastMessage: 'I reviewed your repository structure. Looks clean.',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }

  @override
  Stream<List<MessageModel>> streamMessages(String chatId, {int limit = 40}) {
    return Stream.value([
      MessageModel(
        id: 'm1',
        chatId: chatId,
        senderId: 'userB',
        receiverId: 'userA',
        text: 'Hi! I saw your post regarding Flutter Architecture assistance.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      MessageModel(
        id: 'm2',
        chatId: chatId,
        senderId: 'userA',
        receiverId: 'userB',
        text: 'Hey Karthik! Yes, looking for guidance on scalable offline caching and responsive layouts.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      MessageModel(
        id: 'm3',
        chatId: chatId,
        senderId: 'userB',
        receiverId: 'userA',
        text: 'Looking forward to collaborating on Flutter architecture!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ]);
  }
}

class FakeNotificationRepository extends NotificationRepository {
  @override
  Stream<List<NotificationModel>> streamNotifications(String recipientId, {int limit = 30}) {
    return Stream.value([
      NotificationModel(
        id: 'n1',
        recipientId: recipientId,
        senderId: 'userB',
        type: 'connection_accepted',
        title: 'Connection Accepted',
        body: 'Priya Sundaram accepted your connection request.',
        referenceId: 'req_123',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      NotificationModel(
        id: 'n2',
        recipientId: recipientId,
        senderId: 'userC',
        type: 'connection_request',
        title: 'New Connection Request',
        body: 'Karthik Raja sent a connection request for "Java Mentorship".',
        referenceId: 'req_456',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'n3',
        recipientId: recipientId,
        senderId: 'userB',
        type: 'new_message',
        title: 'New Message',
        body: 'Karthik Raja: Looking forward to collaborating!',
        referenceId: 'chat_userA_userB',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ]);
  }
}

void main() {
  final sampleNeed = NeedModel(
    needId: 'sample_need_1',
    userId: 'user_123',
    type: 'need',
    title: 'Urgent Flutter Architecture Help',
    description: 'Need assistance designing scalable offline state management and Clean Architecture for mobile production.',
    category: 'Services',
    skills: const ['Flutter', 'Dart', 'Architecture'],
    location: 'Remote',
    budget: 'Paid',
    urgency: 'high',
    status: 'active',
    createdAt: DateTime.now(),
  );

  final sampleChat = ChatModel(
    id: 'chat_userA_userB',
    participantIds: const ['userA', 'userB'],
    needId: 'need_123',
    connectionRequestId: 'req_123',
    lastMessage: 'Looking forward to collaborating on Flutter architecture!',
    lastMessageAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  void setupDevice(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget createWrapper(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: child,
    );
  }

  group('Capture NIVA Production Screens at 390x844', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const fontDir =
          '/home/yuvan-shankar-raja/develop/flutter/bin/cache/artifacts/material_fonts';

      try {
        final iconBytes =
            await File('$fontDir/MaterialIcons-Regular.otf').readAsBytes();
        final iconLoader = FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.view(iconBytes.buffer)));
        await iconLoader.load();

        final regularBytes =
            await File('$fontDir/Roboto-Regular.ttf').readAsBytes();
        final mediumBytes =
            await File('$fontDir/Roboto-Medium.ttf').readAsBytes();
        final boldBytes = await File('$fontDir/Roboto-Bold.ttf').readAsBytes();

        for (final family in [
          'Plus Jakarta Sans',
          'Roboto',
          'sans-serif',
          '.SF Pro Text',
        ]) {
          final loader = FontLoader(family)
            ..addFont(Future.value(ByteData.view(regularBytes.buffer)))
            ..addFont(Future.value(ByteData.view(mediumBytes.buffer)))
            ..addFont(Future.value(ByteData.view(boldBytes.buffer)));
          await loader.load();
        }
      } catch (e) {
        debugPrint('Font load notice: $e');
      }
    });
    testWidgets('01_splash', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(LogoRevealScreen(onComplete: () {})),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await expectLater(
        find.byType(LogoRevealScreen),
        matchesGoldenFile('../docs/screenshots/01_splash.png'),
      );
    });

    testWidgets('02_login', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(LoginScreen(onNavigateToSignUp: () {})),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('../docs/screenshots/02_login.png'),
      );
    });

    testWidgets('03_signup', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(SignUpScreen(onNavigateToLogin: ([_]) {})),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await expectLater(
        find.byType(SignUpScreen),
        matchesGoldenFile('../docs/screenshots/03_signup.png'),
      );
    });

    testWidgets('04_home', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(const MainNavigationShell()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await expectLater(
        find.byType(MainNavigationShell),
        matchesGoldenFile('../docs/screenshots/04_home.png'),
      );
    });

    testWidgets('05_explore', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(const ExploreScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await expectLater(
        find.byType(ExploreScreen),
        matchesGoldenFile('../docs/screenshots/05_explore.png'),
      );
    });

    testWidgets('06_filter', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(
          Scaffold(
            backgroundColor: const Color(0x66000000),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FilterBottomSheet(
                initialFilter: const SearchFilter(),
                onApply: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../docs/screenshots/06_filter.png'),
      );
    });

    testWidgets('07_create_need', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(
          const Scaffold(
            backgroundColor: Color(0x66000000),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: CreateNeedSheet(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../docs/screenshots/07_create_need.png'),
      );
    });

    testWidgets('08_matching', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(
          Scaffold(
            backgroundColor: const Color(0x66000000),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MatchingSheet(
                need: sampleNeed,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../docs/screenshots/08_matching.png'),
      );
    });

    testWidgets('09_chat_list', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(
          ChatScreen(
            chatRepository: FakeChatRepository(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await expectLater(
        find.byType(ChatScreen),
        matchesGoldenFile('../docs/screenshots/09_chat_list.png'),
      );
    });

    testWidgets('10_conversation', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(
          ConversationScreen(
            chat: sampleChat,
            otherUserName: 'Karthik Raja',
            otherUserId: 'userB',
            chatRepository: FakeChatRepository(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await expectLater(
        find.byType(ConversationScreen),
        matchesGoldenFile('../docs/screenshots/10_conversation.png'),
      );
    });

    testWidgets('11_notifications', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(
          NotificationsScreen(
            notificationRepository: FakeNotificationRepository(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await expectLater(
        find.byType(NotificationsScreen),
        matchesGoldenFile('../docs/screenshots/11_notifications.png'),
      );
    });

    testWidgets('12_profile', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(const ProfileScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('../docs/screenshots/12_profile.png'),
      );
    });

    testWidgets('13_review', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(
          const Scaffold(
            backgroundColor: Color(0x66000000),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ReviewSheet(
                connectionRequestId: 'req_123',
                needId: 'need_123',
                revieweeId: 'userB',
                revieweeName: 'Priya Sundaram',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../docs/screenshots/13_review.png'),
      );
    });

    testWidgets('14_report', (WidgetTester tester) async {
      setupDevice(tester);
      await tester.pumpWidget(
        createWrapper(
          const Scaffold(
            backgroundColor: Color(0x66000000),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ReportSheet(
                reportedUserId: 'userB',
                reportedUserName: 'Priya Sundaram',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../docs/screenshots/14_report.png'),
      );
    });
  });
}
