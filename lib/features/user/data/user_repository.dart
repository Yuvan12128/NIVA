import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'user_model.dart';

/// Lightweight Firestore repository handling user profile document interactions.
/// Separates public discovery data (users/{uid}) from private account data (users/{uid}/private/account).
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _usersCollection =>
      _firestore?.collection('users');

  DocumentReference<Map<String, dynamic>>? _privateAccountDoc(String uid) =>
      _usersCollection?.doc(uid).collection('private').doc('account');

  /// Create initial user profile at users/{uid} upon signup (public discovery info),
  /// and stores private email in users/{uid}/private/account.
  Future<void> createUserProfile(UserModel user) async {
    final col = _usersCollection;
    if (col == null) return;

    // 1. Write public profile to users/{uid} (excludes private email)
    await col.doc(user.uid).set(user.toMap(includeEmail: false));

    // 2. Write private account document if email exists
    if (user.email.isNotEmpty) {
      try {
        await _privateAccountDoc(user.uid)?.set({
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
      final docRef = _privateAccountDoc(uid);
      if (docRef == null) return null;
      final doc = await docRef.get();
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
    final col = _usersCollection;
    if (col == null) return null;

    final doc = await col.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    final privateEmail = await getUserPrivateEmail(uid);
    return UserModel.fromMap(
      doc.id,
      doc.data()!,
      email: privateEmail ?? '',
    );
  }

  /// Update targeted user profile fields.
  /// If email is present in update data, it is stored in users/{uid}/private/account.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final col = _usersCollection;
    if (col == null) return;

    final updateData = Map<String, dynamic>.from(data);

    // Route private email to users/{uid}/private/account
    final email = updateData.remove('email') as String?;
    if (email != null && email.isNotEmpty) {
      try {
        await _privateAccountDoc(uid)?.set({
          'email': email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('UserRepository.updateUserProfile private email notice: $e');
      }
    }

    if (updateData.isNotEmpty) {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await col.doc(uid).update(updateData);
    }
  }

  /// Real-time stream for current user's profile.
  Stream<UserModel?> streamUserProfile(String uid) {
    final col = _usersCollection;
    if (col == null) return Stream.value(null);

    return col.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.id, doc.data()!);
    });
  }

  /// In-memory filter for discovering and searching users across Name, Skills, Profession, and Education.
  /// Strictly excludes current user and blocked users.
  static List<UserModel> filterDiscoverableUsers({
    required List<UserModel> users,
    String query = '',
    String? currentUserId,
    Set<String> blockedUserIds = const {},
  }) {
    final available = users.where((u) {
      if (currentUserId != null && u.uid == currentUserId) {
        return false;
      }
      if (blockedUserIds.contains(u.uid)) return false;
      return true;
    }).toList();

    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return available;
    }

    final terms =
        cleanQuery
            .split(RegExp(r'\s+'))
            .where((t) => t.isNotEmpty)
            .toList();

    return available.where((user) {
      final name = user.name.toLowerCase();
      final profession = user.profession.toLowerCase();
      final education = user.education.toLowerCase();
      final bio = user.bio.toLowerCase();
      final skills = user.skills.map((s) => s.toLowerCase()).toList();

      return terms.every((term) {
        if (name.contains(term)) return true;
        if (profession.contains(term)) return true;
        if (education.contains(term)) return true;
        if (bio.contains(term)) return true;
        if (skills.any((s) => s.contains(term))) return true;
        return false;
      });
    }).toList();
  }

  /// Discover and search community members across Name, Skills, Profession, and Education.
  /// Enforces exclusion of current user and blocked users.
  Future<List<UserModel>> discoverPeople({
    String query = '',
    String? currentUserId,
    Set<String> blockedUserIds = const {},
    int limit = 30,
    DocumentSnapshot? startAfter,
  }) async {
    final col = _usersCollection;
    if (col == null) return const [];

    try {
      Query<Map<String, dynamic>> firestoreQuery =
          col.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        firestoreQuery = firestoreQuery.startAfterDocument(startAfter);
      }

      final snapshot = await firestoreQuery.get();
      final allUsers =
          snapshot.docs
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .toList();

      return filterDiscoverableUsers(
        users: allUsers,
        query: query,
        currentUserId: currentUserId,
        blockedUserIds: blockedUserIds,
      );
    } catch (e) {
      debugPrint('UserRepository.discoverPeople error: $e');
      return const [];
    }
  }

  /// Real-time stream for discovering and searching people.
  Stream<List<UserModel>> streamDiscoverPeople({
    String query = '',
    String? currentUserId,
    Set<String> blockedUserIds = const {},
    int limit = 30,
  }) {
    final col = _usersCollection;
    if (col == null) return Stream.value(const <UserModel>[]);

    return col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final allUsers =
              snapshot.docs
                  .map((doc) => UserModel.fromMap(doc.id, doc.data()))
                  .toList();

          return filterDiscoverableUsers(
            users: allUsers,
            query: query,
            currentUserId: currentUserId,
            blockedUserIds: blockedUserIds,
          );
        })
        .handleError((dynamic error) {
          debugPrint('UserRepository.streamDiscoverPeople error: $error');
          return const <UserModel>[];
        });
  }
}
