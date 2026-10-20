import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'user_model.dart';

/// Lightweight Firestore repository handling user profile document interactions.
/// Separates public discovery data (users/{uid}) from private account data (users/{uid}/private/account).
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> _privateAccountDoc(String uid) =>
      _usersCollection.doc(uid).collection('private').doc('account');

  /// Create initial user profile at users/{uid} upon signup (public discovery info),
  /// and stores private email in users/{uid}/private/account.
  Future<void> createUserProfile(UserModel user) async {
    // 1. Write public profile to users/{uid} (excludes private email)
    await _usersCollection.doc(user.uid).set(user.toMap(includeEmail: false));

    // 2. Write private account document if email exists
    if (user.email.isNotEmpty) {
      try {
        await _privateAccountDoc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint(
          'UserRepository.createUserProfile private account notice: $e',
        );
      }
    }
  }

  /// Retrieve the user's private account email (only accessible by the owner).
  Future<String?> getUserPrivateEmail(String uid) async {
    try {
      final doc = await _privateAccountDoc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['email'] as String?;
      }
    } catch (e) {
      debugPrint('UserRepository.getUserPrivateEmail notice: $e');
    }
    return null;
  }

  /// Retrieve single user profile by UID without querying the whole collection.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  /// Update targeted user profile fields.
  /// If email is present in update data, it is stored in users/{uid}/private/account.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final updateData = Map<String, dynamic>.from(data);

    // Route private email to users/{uid}/private/account
    final email = updateData.remove('email') as String?;
    if (email != null && email.isNotEmpty) {
      try {
        await _privateAccountDoc(uid).set({
          'email': email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('UserRepository.updateUserProfile private email notice: $e');
      }
    }

    if (updateData.isNotEmpty) {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _usersCollection.doc(uid).update(updateData);
    }
  }

  /// Real-time stream for current user's profile.
  Stream<UserModel?> streamUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.id, doc.data()!);
    });
  }
}
