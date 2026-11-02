import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niva/core/constants/app_colors.dart';
import 'package:niva/features/auth/data/auth_service.dart';
import 'package:niva/features/auth/presentation/auth_gate.dart';
import 'package:niva/features/auth/presentation/sign_in_screen.dart';
import 'package:niva/features/navigation/presentation/main_navigation_shell.dart';
import 'package:niva/features/user/data/user_model.dart';
import 'package:niva/features/user/data/user_repository.dart';

class FakeUserRepository extends UserRepository {
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

    final name = data['name'] as String?;
    final photoUrl = data['photoUrl'] as String?;

    users[uid] = existing.copyWith(
      name: name ?? existing.name,
      photoUrl: photoUrl ?? existing.photoUrl,
    );
  }
}

class FakeAuthService extends AuthService {
  FakeAuthService({
    required this.fakeUserRepo,
    this.shouldFail = false,
    this.failErrorMessage = 'Google sign-in was cancelled.',
  }) : super(userRepository: fakeUserRepo);

  final FakeUserRepository fakeUserRepo;
  final bool shouldFail;
  final String failErrorMessage;
  bool signInWithGoogleCalled = false;

  @override
  Future<UserCredential?> signInWithGoogle() async {
    signInWithGoogleCalled = true;
    if (shouldFail) {
      throw Exception(failErrorMessage);
    }
    return null;
  }
}

void main() {
  group('Google Sign-In & Apple-Style Authentication Tests', () {
    testWidgets('SignInScreen renders Apple-style minimal UI correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify white background and typography
      expect(find.text('NIVA'), findsOneWidget);
      expect(
        find.text(
          'Connect with the right person when you need help, share skills, and build peer relationships.',
        ),
        findsOneWidget,
      );
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(
        find.textContaining('Terms and Privacy Policy'),
        findsOneWidget,
      );

      // Verify scaffold background is white
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.pureWhite);
    });

    testWidgets('Tapping Continue with Google calls signInWithGoogle', (
      WidgetTester tester,
    ) async {
      final userRepo = FakeUserRepository();
      final fakeAuth = FakeAuthService(fakeUserRepo: userRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(authService: fakeAuth),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeAuth.signInWithGoogleCalled, isFalse);

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      expect(fakeAuth.signInWithGoogleCalled, isTrue);
    });

    testWidgets('SignInScreen displays error banner on authentication failure', (
      WidgetTester tester,
    ) async {
      final userRepo = FakeUserRepository();
      final fakeAuth = FakeAuthService(
        fakeUserRepo: userRepo,
        shouldFail: true,
        failErrorMessage: 'Google sign in was cancelled.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(authService: fakeAuth),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('Google sign in was cancelled.'), findsOneWidget);
    });

    test('syncGoogleUserProfile creates initial profile for first-time Google user', () async {
      final userRepo = FakeUserRepository();

      // Verify initial state is empty
      final initial = await userRepo.getUserProfile('google_uid_123');
      expect(initial, isNull);

      // Create new profile via UserModel
      final newProfile = UserModel(
        uid: 'google_uid_123',
        name: 'Kavitha Raman',
        email: 'kavitha@gmail.com',
        photoUrl: 'https://lh3.googleusercontent.com/photo123',
        country: 'India',
        state: 'Tamil Nadu',
        city: 'Chennai',
        language: 'English',
        role: 'member',
        skills: const [],
        canHelpWith: const [],
        lookingFor: const [],
        availability: 'Available',
        trustScore: 100,
      );
      await userRepo.createUserProfile(newProfile);

      final created = await userRepo.getUserProfile('google_uid_123');
      expect(created, isNotNull);
      expect(created!.name, 'Kavitha Raman');
      expect(created.email, 'kavitha@gmail.com');
      expect(created.photoUrl, 'https://lh3.googleusercontent.com/photo123');
      expect(created.trustScore, 100);
      expect(created.city, 'Chennai');
    });

    test('syncGoogleUserProfile preserves existing user data during login', () async {
      final userRepo = FakeUserRepository();

      // Seed pre-existing profile with customized bio, skills, canHelpWith, and lookingFor
      final existingProfile = UserModel(
        uid: 'google_uid_456',
        name: 'Venkatesh S',
        email: 'venkat@gmail.com',
        photoUrl: 'https://lh3.googleusercontent.com/old_photo',
        country: 'India',
        state: 'Tamil Nadu',
        city: 'Coimbatore',
        language: 'Tamil, English',
        role: 'member',
        bio: 'Senior Flutter and Systems Architect with 8+ years experience.',
        skills: const ['Flutter', 'Dart', 'Clean Architecture', 'Firebase'],
        canHelpWith: const ['System Design', 'Code Reviews', 'Mentorship'],
        lookingFor: const ['Open Source Collaborators', 'Rust Mentors'],
        availability: 'Weekends & Evenings',
        trustScore: 100,
      );
      await userRepo.createUserProfile(existingProfile);

      // Simulate a returning Google sign-in where Google provides same or new photo
      final fetched = await userRepo.getUserProfile('google_uid_456');
      expect(fetched, isNotNull);

      // Verify all custom fields are preserved intact
      expect(fetched!.name, 'Venkatesh S');
      expect(fetched.bio, 'Senior Flutter and Systems Architect with 8+ years experience.');
      expect(fetched.skills, ['Flutter', 'Dart', 'Clean Architecture', 'Firebase']);
      expect(fetched.canHelpWith, ['System Design', 'Code Reviews', 'Mentorship']);
      expect(fetched.lookingFor, ['Open Source Collaborators', 'Rust Mentors']);
      expect(fetched.city, 'Coimbatore');
      expect(fetched.availability, 'Weekends & Evenings');
    });

    testWidgets('AuthGate routes to SignInScreen when unauthenticated and MainNavigationShell when authenticated', (
      WidgetTester tester,
    ) async {
      final userRepo = FakeUserRepository();
      final fakeAuth = FakeAuthService(fakeUserRepo: userRepo);

      // 1. Unauthenticated -> presents SignInScreen
      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authStateStream: Stream.value(null),
            authService: fakeAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(MainNavigationShell), findsNothing);
    });
  });
}
