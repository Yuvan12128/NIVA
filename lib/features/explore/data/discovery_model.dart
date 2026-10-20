import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../needs/data/need_model.dart';
import '../../user/data/user_model.dart';

/// The 5 core discovery facets supported across NIVA.
enum DiscoveryType {
  people,
  services,
  information,
  opportunities,
  communities;

  String get label => switch (this) {
    DiscoveryType.people => 'People',
    DiscoveryType.services => 'Services',
    DiscoveryType.information => 'Information',
    DiscoveryType.opportunities => 'Opportunities',
    DiscoveryType.communities => 'Communities',
  };

  Color get iconColor => switch (this) {
    DiscoveryType.people => AppColors.peopleIcon,
    DiscoveryType.services => AppColors.servicesIcon,
    DiscoveryType.information => AppColors.infoIcon,
    DiscoveryType.opportunities => AppColors.opportunitiesIcon,
    DiscoveryType.communities => AppColors.communitiesIcon,
  };

  Color get backgroundColor => switch (this) {
    DiscoveryType.people => AppColors.peopleBg,
    DiscoveryType.services => AppColors.servicesBg,
    DiscoveryType.information => AppColors.infoBg,
    DiscoveryType.opportunities => AppColors.opportunitiesBg,
    DiscoveryType.communities => AppColors.communitiesBg,
  };

  IconData get icon => switch (this) {
    DiscoveryType.people => Icons.person_outline_rounded,
    DiscoveryType.services => Icons.business_center_outlined,
    DiscoveryType.information => Icons.menu_book_outlined,
    DiscoveryType.opportunities => Icons.lightbulb_outline_rounded,
    DiscoveryType.communities => Icons.groups_outlined,
  };
}

/// Model for a universal discovery item in NIVA.
class DiscoveryModel {
  const DiscoveryModel({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.location,
    required this.meta,
    required this.actionLabel,
    this.itemType,
    this.category,
    this.authorName,
    this.authorId,
    this.tags = const [],
    this.skills = const [],
    this.availability,
    this.trustScore,
    this.needModel,
    this.createdAt,
  });

  final String id;
  final String title;
  final DiscoveryType type;
  final String? itemType; // 'need' | 'help' | 'profile' | 'community' | etc.
  final String? category;
  final String description;
  final String location;
  final String meta;
  final String actionLabel;
  final String? authorName;
  final String? authorId;
  final List<String> tags;
  final List<String> skills;
  final String? availability;
  final int? trustScore;
  final NeedModel? needModel;
  final DateTime? createdAt;

  /// Map a Firestore NeedModel (type 'need' or 'help') into a rich DiscoveryModel.
  factory DiscoveryModel.fromNeedModel(NeedModel need) {
    DiscoveryType type;
    final cat = need.category.toLowerCase();
    if (cat.contains('communit')) {
      type = DiscoveryType.communities;
    } else if (cat.contains('opport') ||
        cat.contains('career') ||
        cat.contains('job')) {
      type = DiscoveryType.opportunities;
    } else if (cat.contains('info') ||
        cat.contains('edu') ||
        cat.contains('advice')) {
      type = DiscoveryType.information;
    } else if (need.type == 'help') {
      type = DiscoveryType.people;
    } else {
      type = DiscoveryType.services;
    }

    final isNeed = need.type == 'need';
    final allSkills = need.skills.isNotEmpty ? need.skills : [need.category];

    return DiscoveryModel(
      id: need.needId,
      title: need.title,
      type: type,
      itemType: need.type,
      category: need.category,
      description: need.description.isNotEmpty ? need.description : need.title,
      location: need.location,
      meta: need.urgency.isNotEmpty
          ? need.urgency
          : (need.availability ?? 'Active'),
      actionLabel: isNeed ? 'Find Match' : 'Connect',
      authorName: need.authorName?.isNotEmpty == true
          ? need.authorName
          : (isNeed ? 'Requester' : 'Provider'),
      authorId: need.userId,
      tags: allSkills,
      skills: need.skills,
      availability: need.availability ?? need.urgency,
      trustScore: 100,
      needModel: need,
      createdAt: need.createdAt,
    );
  }

  /// Map a UserModel (discovery helper profile) into a DiscoveryModel.
  /// Only exposes public discovery fields (no private email or account secrets).
  factory DiscoveryModel.fromUserModel(UserModel user) {
    final allSkills = {...user.skills, ...user.canHelpWith}.toList();
    final locationText = user.city.isNotEmpty
        ? user.city
        : (user.state.isNotEmpty ? user.state : 'Remote');

    return DiscoveryModel(
      id: user.uid,
      title: user.name.isNotEmpty ? user.name : 'Community Helper',
      type: DiscoveryType.people,
      itemType: 'help',
      category: 'People',
      description: user.canHelpWith.isNotEmpty
          ? 'Can help with: ${user.canHelpWith.join(', ')}'
          : (user.skills.isNotEmpty
                ? 'Skills: ${user.skills.join(', ')}'
                : 'Available to collaborate in the community'),
      location: locationText,
      meta: user.availability.isNotEmpty ? user.availability : 'Available',
      actionLabel: 'Connect',
      authorName: user.name,
      authorId: user.uid,
      tags: allSkills.isNotEmpty ? allSkills : ['Helper'],
      skills: allSkills,
      availability: user.availability,
      trustScore: user.trustScore,
      createdAt: user.createdAt,
    );
  }

  DiscoveryModel copyWith({
    String? id,
    String? title,
    DiscoveryType? type,
    String? itemType,
    String? category,
    String? description,
    String? location,
    String? meta,
    String? actionLabel,
    String? authorName,
    String? authorId,
    List<String>? tags,
    List<String>? skills,
    String? availability,
    int? trustScore,
    NeedModel? needModel,
    DateTime? createdAt,
  }) {
    return DiscoveryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      itemType: itemType ?? this.itemType,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      meta: meta ?? this.meta,
      actionLabel: actionLabel ?? this.actionLabel,
      authorName: authorName ?? this.authorName,
      authorId: authorId ?? this.authorId,
      tags: tags ?? this.tags,
      skills: skills ?? this.skills,
      availability: availability ?? this.availability,
      trustScore: trustScore ?? this.trustScore,
      needModel: needModel ?? this.needModel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
