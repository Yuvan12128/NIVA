import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a need or help capability in NIVA (`needs/{needId}`).
class NeedModel {
  const NeedModel({
    required this.needId,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    this.skills = const [],
    this.location = 'Remote',
    this.urgency = 'Flexible',
    this.budget,
    this.availability,
    this.status = 'active',
    this.authorName,
    this.createdAt,
    this.updatedAt,
  });

  final String needId;
  final String userId;
  final String type; // 'need' or 'help'
  final String title;
  final String description;
  final String category;
  final List<String> skills;
  final String location;
  final String urgency;
  final String? budget;
  final String? availability;
  final String status;
  final String? authorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'category': category,
      'skills': skills,
      'location': location,
      'urgency': urgency,
      'budget': budget,
      'availability': availability,
      'status': status,
      if (authorName != null) 'authorName': authorName,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : (useServerTimestamp ? FieldValue.serverTimestamp() : null),
      'updatedAt': useServerTimestamp ? FieldValue.serverTimestamp() : null,
    };
  }

  factory NeedModel.fromMap(String needId, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return NeedModel(
      needId: needId,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'need',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      skills:
          (map['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      location: map['location'] as String? ?? 'Remote',
      urgency: map['urgency'] as String? ?? 'Flexible',
      budget: map['budget'] as String?,
      availability: map['availability'] as String?,
      status: map['status'] as String? ?? 'active',
      authorName: map['authorName'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  NeedModel copyWith({
    String? needId,
    String? userId,
    String? type,
    String? title,
    String? description,
    String? category,
    List<String>? skills,
    String? location,
    String? urgency,
    String? budget,
    String? availability,
    String? status,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NeedModel(
      needId: needId ?? this.needId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      skills: skills ?? this.skills,
      location: location ?? this.location,
      urgency: urgency ?? this.urgency,
      budget: budget ?? this.budget,
      availability: availability ?? this.availability,
      status: status ?? this.status,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
