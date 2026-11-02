import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../user/data/user_model.dart';
import '../../user/data/user_repository.dart';

/// Central authentication service for NIVA using Firebase Authentication & Google Sign-In.
class AuthService {
  AuthService({this.auth, this.userRepository, this.googleSignIn});

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService();
  static set instance(AuthService value) => _instance = value;

  final FirebaseAuth? auth;
  final UserRepository? userRepository;
  final GoogleSignIn? googleSignIn;

  FirebaseAuth get firebaseAuth => auth ?? FirebaseAuth.instance;
  UserRepository get userRepo => userRepository ?? UserRepository();
  GoogleSignIn get googleSignInInstance => googleSignIn ?? GoogleSignIn();

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

  /// Sign in using Google Sign-In and authenticate with Firebase.
  /// Automatically retrieves Google name, email, and photoURL,
  /// then creates or updates users/{uid} in Firestore while preserving existing data.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
          await googleSignInInstance.signIn();
      if (googleUser == null) {
        // User cancelled Google sign-in prompt
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await syncGoogleUserProfile(user);
      }

      return userCredential;
    } catch (e) {
      debugPrint('AuthService.signInWithGoogle error: $e');
      rethrow;
    }
  }

  /// Synchronize Google profile information into Firestore (users/{uid}).
  /// - New user: Creates users/{uid} with name, email, and profile photo.
  /// - Returning user: Preserves all existing data (skills, bio, location, etc.)
  ///   and only backfills missing fields.
  Future<void> syncGoogleUserProfile(User user) async {
    try {
      final existing = await userRepo.getUserProfile(user.uid);
      final googleName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Member');
      final googleEmail = user.email?.trim() ?? '';
      final googlePhoto = user.photoURL;

      if (existing == null) {
        final profile = UserModel(
          uid: user.uid,
          name: googleName,
          email: googleEmail,
          photoUrl: googlePhoto,
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
        await userRepo.createUserProfile(profile);
      } else {
        // Preserve existing user data during login!
        final updates = <String, dynamic>{};
        if (existing.name.trim().isEmpty && googleName.isNotEmpty) {
          updates['name'] = googleName;
        }
        if ((existing.photoUrl == null || existing.photoUrl!.trim().isEmpty) &&
            googlePhoto != null &&
            googlePhoto.isNotEmpty) {
          updates['photoUrl'] = googlePhoto;
        }

        if (updates.isNotEmpty) {
          await userRepo.updateUserProfile(user.uid, updates);
        }

        // Ensure private account document contains email
        if (googleEmail.isNotEmpty) {
          final privateEmail = await userRepo.getUserPrivateEmail(user.uid);
          if (privateEmail == null || privateEmail.isEmpty) {
            await userRepo.updateUserProfile(user.uid, {'email': googleEmail});
          }
        }
      }
    } catch (e) {
      debugPrint('AuthService.syncGoogleUserProfile notice: $e');
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

  /// Sign out current authenticated user from Firebase and Google.
  Future<void> signOut() async {
    try {
      await googleSignInInstance.signOut();
    } catch (e) {
      debugPrint('GoogleSignIn.signOut notice: $e');
    }
    await firebaseAuth.signOut();
  }

  /// Human-readable error message mapping for authentication failures.
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email address using another sign-in method.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid sign-in credentials. Please check your account.';
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
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('canceled') || errStr.contains('cancelled') || errStr.contains('popup_closed')) {
      return 'Google sign in was cancelled.';
    }
    if (errStr.contains('apiexception: 10') ||
        errStr.contains(': 10') ||
        errStr.contains('developer_error')) {
      return 'Google Sign-In error (Code 10): Android SHA-1 fingerprint is not added to Firebase Console.';
    }
    if (errStr.contains('apiexception: 12500') || errStr.contains(': 12500')) {
      return 'Google Sign-In error (Code 12500): OAuth consent screen or support email is missing in Firebase Console.';
    }
    if (errStr.contains('operation-not-allowed')) {
      return 'This sign-in method is disabled in Firebase Console. Please enable it in Authentication > Sign-in method.';
    }
    if (errStr.contains('network')) {
      return 'Network connection error. Please check your connection.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
