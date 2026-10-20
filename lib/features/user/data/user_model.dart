import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile data model for NIVA users collection (`users/{uid}`).
/// By default, private email is NOT exposed in public discovery documents.
class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    this.email = '',
    this.photoUrl,
    this.country = 'India',
    this.state = 'Tamil Nadu',
    this.city = 'Chennai',
    this.language = 'English',
    this.role = 'member',
    this.bio = '',
    this.skills = const [],
    this.canHelpWith = const [],
    this.lookingFor = const [],
    this.availability = 'Available',
    this.trustScore = 100,
    this.completedConnections = 0,
    this.helpfulInteractions = 0,
    this.reviewCount = 0,
    this.rating = 5.0,
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
  final String bio;
  final List<String> skills;
  final List<String> canHelpWith;
  final List<String> lookingFor;
  final String availability;
  final int trustScore;
  final int completedConnections;
  final int helpfulInteractions;
  final int reviewCount;
  final double rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Serializes to map.
  /// [includeEmail] is false by default to ensure private email is NEVER
  /// written to the public discovery profile document (`users/{uid}`).
  Map<String, dynamic> toMap({
    bool useServerTimestamp = true,
    bool includeEmail = false,
  }) {
    return {
      'name': name,
      if (includeEmail && email.isNotEmpty) 'email': email,
      'photoUrl': photoUrl,
      'country': country,
      'state': state,
      'city': city,
      'language': language,
      'role': role,
      'bio': bio,
      'skills': skills,
      'canHelpWith': canHelpWith,
      'lookingFor': lookingFor,
      'availability': availability,
      'trustScore': trustScore,
      'completedConnections': completedConnections,
      'helpfulInteractions': helpfulInteractions,
      'reviewCount': reviewCount,
      'rating': rating,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : (useServerTimestamp ? FieldValue.serverTimestamp() : null),
      'updatedAt': useServerTimestamp ? FieldValue.serverTimestamp() : null,
    };
  }

  factory UserModel.fromMap(
    String uid,
    Map<String, dynamic> map, {
    String email = '',
  }) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? email,
      photoUrl: map['photoUrl'] as String?,
      country: map['country'] as String? ?? '',
      state: map['state'] as String? ?? '',
      city: map['city'] as String? ?? '',
      language: map['language'] as String? ?? 'English',
      role: map['role'] as String? ?? 'member',
      bio: map['bio'] as String? ?? '',
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
      completedConnections:
          (map['completedConnections'] as num?)?.toInt() ?? 0,
      helpfulInteractions:
          (map['helpfulInteractions'] as num?)?.toInt() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? country,
    String? state,
    String? city,
    String? language,
    String? role,
    String? bio,
    List<String>? skills,
    List<String>? canHelpWith,
    List<String>? lookingFor,
    String? availability,
    int? trustScore,
    int? completedConnections,
    int? helpfulInteractions,
    int? reviewCount,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      language: language ?? this.language,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      canHelpWith: canHelpWith ?? this.canHelpWith,
      lookingFor: lookingFor ?? this.lookingFor,
      availability: availability ?? this.availability,
      trustScore: trustScore ?? this.trustScore,
      completedConnections: completedConnections ?? this.completedConnections,
      helpfulInteractions: helpfulInteractions ?? this.helpfulInteractions,
      reviewCount: reviewCount ?? this.reviewCount,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
