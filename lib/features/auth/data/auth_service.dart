import 'package:firebase_auth/firebase_auth.dart';

import '../../user/data/user_model.dart';
import '../../user/data/user_repository.dart';

/// Central authentication service for NIVA using Firebase Authentication & Firestore.
class AuthService {
  AuthService({this.auth, this.userRepository});

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService();
  static set instance(AuthService value) => _instance = value;

  final FirebaseAuth? auth;
  final UserRepository? userRepository;

  FirebaseAuth get firebaseAuth => auth ?? FirebaseAuth.instance;
  UserRepository get userRepo => userRepository ?? UserRepository();

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  /// Currently authenticated user, or null if unauthenticated or Firebase is uninitialized.
  User? get currentUser {
    try {
      return firebaseAuth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Sign up with email, password, and initial profile details.
  Future<UserCredential> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    String country = 'India',
    String state = 'Tamil Nadu',
    String city = 'Chennai',
    String language = 'English',
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      // Update Auth display name
      await user.updateDisplayName(name.trim());

      // Create initial Firestore user document at users/{uid}
      final userProfile = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        photoUrl: user.photoURL,
        country: country,
        state: state,
        city: city,
        language: language,
        role: 'member',
        skills: const [],
        canHelpWith: const [],
        lookingFor: const [],
        availability: 'Available for discovery',
        trustScore: 100,
      );

      try {
        await userRepo.createUserProfile(userProfile);
      } catch (_) {
        // Non-blocking fallback; profile is guaranteed on next sign in
      }
    }

    return credential;
  }

  /// Sign in with existing email and password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      try {
        final existing = await userRepo.getUserProfile(user.uid);
        if (existing == null) {
          final profile = UserModel(
            uid: user.uid,
            name: user.displayName?.isNotEmpty == true
                ? user.displayName!
                : email.split('@').first,
            email: user.email ?? email.trim(),
            photoUrl: user.photoURL,
            country: 'India',
            state: 'Tamil Nadu',
            city: 'Chennai',
            language: 'English',
            role: 'member',
            skills: const [],
            canHelpWith: const [],
            lookingFor: const [],
            availability: 'Available for discovery',
            trustScore: 100,
          );
          await userRepo.createUserProfile(profile);
        }
      } catch (_) {
        // Non-blocking self-heal
      }
    }

    return credential;
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out current authenticated user.
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  /// Human-readable error message mapping for authentication failures.
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password. Please check your credentials.';
        case 'email-already-in-use':
          return 'An account already exists for this email address.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
