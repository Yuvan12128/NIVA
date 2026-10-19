import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niva/app/niva_app.dart';
import 'package:niva/features/navigation/presentation/main_navigation_shell.dart';
import 'package:niva/features/navigation/presentation/widgets/create_need_sheet.dart';
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

      final map = user.toMap(useServerTimestamp: false);
      expect(map['name'], 'Arun Kumar');
      expect(map['email'], 'arun@example.com');
      expect(map['city'], 'Chennai');
      expect(map['trustScore'], 100);

      final deserialized = UserModel.fromMap('test_uid_123', map);
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
}
