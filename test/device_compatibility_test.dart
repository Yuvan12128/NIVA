import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niva/core/theme/app_theme.dart';
import 'package:niva/features/auth/presentation/login_screen.dart';
import 'package:niva/features/auth/presentation/signup_screen.dart';
import 'package:niva/features/chat/data/chat_model.dart';
import 'package:niva/features/chat/presentation/chat_screen.dart';
import 'package:niva/features/chat/presentation/conversation_screen.dart';
import 'package:niva/features/explore/data/search_filter_model.dart';
import 'package:niva/features/explore/presentation/explore_screen.dart';
import 'package:niva/features/explore/presentation/widgets/filter_bottom_sheet.dart';
import 'package:niva/features/home/presentation/home_screen.dart';
import 'package:niva/features/matching/presentation/widgets/matching_sheet.dart';
import 'package:niva/features/navigation/presentation/main_navigation_shell.dart';
import 'package:niva/features/navigation/presentation/widgets/create_need_sheet.dart';
import 'package:niva/features/needs/data/need_model.dart';
import 'package:niva/features/notifications/presentation/notifications_screen.dart';
import 'package:niva/features/profile/presentation/profile_screen.dart';
import 'package:niva/features/reviews/presentation/widgets/review_sheet.dart';
import 'package:niva/features/safety/presentation/widgets/report_sheet.dart';
import 'package:niva/features/splash/presentation/logo_reveal_screen.dart';

void main() {
  final testDevices = <String, Size>{
    'Ultra-compact (320px)': const Size(320, 568),
    'Entry Android (360px)': const Size(360, 640),
    'Compact Mobile (375px)': const Size(375, 667),
    'Modern Mobile (390px)': const Size(390, 844),
    'Wide Android (412px)': const Size(412, 915),
    'Large Mobile (430px)': const Size(430, 932),
    '7-inch Tablet (600px)': const Size(600, 960),
    '10-inch Tablet (800px)': const Size(800, 1280),
  };

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
    lastMessage: 'Looking forward to collaborating!',
    lastMessageAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget createTestWrapper(Widget child) {
    return MaterialApp(theme: AppTheme.lightTheme, home: child);
  }

  group('Responsive Device Compatibility Suite', () {
    for (final entry in testDevices.entries) {
      final deviceName = entry.key;
      final size = entry.value;

      group('$deviceName [${size.width.toInt()}x${size.height.toInt()}]', () {
        void setDeviceSize(WidgetTester tester) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
        }

        testWidgets('LoginScreen renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(
            createTestWrapper(LoginScreen(onNavigateToSignUp: () {})),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('SignUpScreen renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(
            createTestWrapper(SignUpScreen(onNavigateToLogin: ([_]) {})),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('HomeScreen renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(createTestWrapper(const HomeScreen()));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('ExploreScreen renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(createTestWrapper(const ExploreScreen()));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('CreateNeedSheet renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(
            createTestWrapper(const Scaffold(body: CreateNeedSheet())),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('MatchingSheet renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(
            createTestWrapper(Scaffold(body: MatchingSheet(need: sampleNeed))),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('ChatScreen renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(createTestWrapper(const ChatScreen()));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('ConversationScreen renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(
            createTestWrapper(
              ConversationScreen(
                chat: sampleChat,
                otherUserName: 'Karthik Raja',
                otherUserId: 'userB',
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('NotificationsScreen renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(
            createTestWrapper(const NotificationsScreen()),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('ProfileScreen renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(createTestWrapper(const ProfileScreen()));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('ReviewSheet renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(
            createTestWrapper(
              const Scaffold(
                body: ReviewSheet(
                  connectionRequestId: 'req_123',
                  needId: 'need_123',
                  revieweeId: 'userB',
                  revieweeName: 'Priya Sundaram',
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('ReportSheet renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(
            createTestWrapper(
              const Scaffold(
                body: ReportSheet(
                  reportedUserId: 'userB',
                  reportedUserName: 'Priya Sundaram',
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('FilterBottomSheet renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(
            createTestWrapper(
              Scaffold(
                body: FilterBottomSheet(
                  initialFilter: const SearchFilter(),
                  onApply: (_) {},
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

        testWidgets('LogoRevealScreen renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(
            createTestWrapper(LogoRevealScreen(onComplete: () {})),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        });

        testWidgets('MainNavigationShell renders with zero overflow', (
          WidgetTester tester,
        ) async {
          setDeviceSize(tester);
          await tester.pumpWidget(
            createTestWrapper(const MainNavigationShell()),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      });
    }
  });
}
