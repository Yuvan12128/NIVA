import 'package:cloud_firestore/cloud_firestore.dart';

/// Allowed reason identifiers for reporting users in NIVA Safety V1.
enum ReportReason {
  spam,
  harassment,
  inappropriateContent,
  scam,
  fakeProfile,
  other;

  String get value => switch (this) {
    ReportReason.spam => 'spam',
    ReportReason.harassment => 'harassment',
    ReportReason.inappropriateContent => 'inappropriate_content',
    ReportReason.scam => 'scam',
    ReportReason.fakeProfile => 'fake_profile',
    ReportReason.other => 'other',
  };

  String get label => switch (this) {
    ReportReason.spam => 'Spam or Advertising',
    ReportReason.harassment => 'Harassment or Bullying',
    ReportReason.inappropriateContent => 'Inappropriate Content',
    ReportReason.scam => 'Scam or Fraud',
    ReportReason.fakeProfile => 'Fake Profile / Impersonation',
    ReportReason.other => 'Other Safety Concern',
  };

  static ReportReason fromString(String val) {
    return switch (val.toLowerCase().trim()) {
      'spam' => ReportReason.spam,
      'harassment' => ReportReason.harassment,
      'inappropriate_content' => ReportReason.inappropriateContent,
      'scam' => ReportReason.scam,
      'fake_profile' => ReportReason.fakeProfile,
      _ => ReportReason.other,
    };
  }
}

/// Data model representing a user report submission (`reports/{reportId}`).
class ReportModel {
  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.description,
    this.referenceId,
    this.status = 'submitted',
    this.createdAt,
  });

  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String? description;
  final String? referenceId;
  final String status;
  final DateTime? createdAt;

  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (referenceId != null && referenceId!.trim().isNotEmpty)
        'referenceId': referenceId!.trim(),
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : (useServerTimestamp ? FieldValue.serverTimestamp() : null),
    };
  }

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return ReportModel(
      id: id,
      reporterId: map['reporterId'] as String? ?? '',
      reportedUserId: map['reportedUserId'] as String? ?? '',
      reason: map['reason'] as String? ?? 'other',
      description: map['description'] as String?,
      referenceId: map['referenceId'] as String?,
      status: map['status'] as String? ?? 'submitted',
      createdAt: parseDate(map['createdAt']),
    );
  }

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? reason,
    String? description,
    String? referenceId,
    String? status,
    DateTime? createdAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
