import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile data model for NIVA users collection (`users/{uid}`).
class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.country = 'India',
    this.state = 'Tamil Nadu',
    this.city = 'Chennai',
    this.language = 'English',
    this.role = 'member',
    this.skills = const [],
    this.canHelpWith = const [],
    this.lookingFor = const [],
    this.availability = 'Available',
    this.trustScore = 100,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String country;
  final String state;
  final String city;
  final String language;
  final String role;
  final List<String> skills;
  final List<String> canHelpWith;
  final List<String> lookingFor;
  final String availability;
  final int trustScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'country': country,
      'state': state,
      'city': city,
      'language': language,
      'role': role,
      'skills': skills,
      'canHelpWith': canHelpWith,
      'lookingFor': lookingFor,
      'availability': availability,
      'trustScore': trustScore,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : (useServerTimestamp ? FieldValue.serverTimestamp() : null),
      'updatedAt': useServerTimestamp ? FieldValue.serverTimestamp() : null,
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      country: map['country'] as String? ?? '',
      state: map['state'] as String? ?? '',
      city: map['city'] as String? ?? '',
      language: map['language'] as String? ?? 'English',
      role: map['role'] as String? ?? 'member',
      skills:
          (map['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      canHelpWith:
          (map['canHelpWith'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lookingFor:
          (map['lookingFor'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      availability: map['availability'] as String? ?? 'Available',
      trustScore: (map['trustScore'] as num?)?.toInt() ?? 100,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? country,
    String? state,
    String? city,
    String? language,
    String? role,
    List<String>? skills,
    List<String>? canHelpWith,
    List<String>? lookingFor,
    String? availability,
    int? trustScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      language: language ?? this.language,
      role: role ?? this.role,
      skills: skills ?? this.skills,
      canHelpWith: canHelpWith ?? this.canHelpWith,
      lookingFor: lookingFor ?? this.lookingFor,
      availability: availability ?? this.availability,
      trustScore: trustScore ?? this.trustScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
