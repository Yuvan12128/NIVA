import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../needs/data/need_model.dart';
import '../../user/data/user_model.dart';
import 'discovery_model.dart';
import 'search_filter_model.dart';

/// Lightweight search and filtering service for NIVA discoveries.
/// Performs bounded Firestore candidate queries and client-side deterministic ranking.
class SearchService {
  SearchService({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _needsCollection =>
      _db.collection('needs');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  /// Curated discovery seeds for initial state, offline testing, or demo setups.
  static const List<DiscoveryModel> seedDiscoveries = [
    DiscoveryModel(
      id: 'd1',
      title: 'Java & Algorithms Mentorship',
      type: DiscoveryType.people,
      itemType: 'help',
      category: 'People',
      authorName: 'Suresh Raina',
      description: '1-on-1 practical guidance on core Java, concurrency, and technical interview problem solving.',
      location: 'Chennai',
      meta: 'Available today',
      actionLabel: 'Connect',
      skills: ['Java', 'Mentorship', 'Backend'],
      tags: ['Java', 'Mentorship', 'Backend'],
      availability: 'Available today',
      trustScore: 100,
    ),
    DiscoveryModel(
      id: 'd2',
      title: 'React & Mobile Guild',
      type: DiscoveryType.communities,
      itemType: 'community',
      category: 'Communities',
      description: 'Collaborative global developer collective sharing production code reviews and architecture patterns.',
      location: 'Remote',
      meta: '2.8k members',
      actionLabel: 'Join',
      skills: ['React', 'Mobile', 'Frontend'],
      tags: ['React', 'Mobile', 'Frontend'],
      availability: 'Flexible',
      trustScore: 98,
    ),
    DiscoveryModel(
      id: 'd3',
      title: 'Open Source Accessibility Tools',
      type: DiscoveryType.opportunities,
      itemType: 'opportunity',
      category: 'Opportunities',
      description: 'Call for contributors to build open-source assistive mobile components and screen-reader integrations.',
      location: 'Remote',
      meta: '6 roles open',
      actionLabel: 'Contribute',
      skills: ['Open Source', 'Flutter', 'Accessibility'],
      tags: ['Open Source', 'Flutter', 'Accessibility'],
      availability: 'Flexible',
      trustScore: 95,
    ),
    DiscoveryModel(
      id: 'd4',
      title: 'Field Photography & Natural Light Guide',
      type: DiscoveryType.information,
      itemType: 'information',
      category: 'Information',
      description: 'Curated handbook covering exposure balance, natural lighting portraiture, and lens calibration.',
      location: 'Curated',
      meta: '15 min read',
      actionLabel: 'Read',
      skills: ['Photography', 'Guide', 'Creative'],
      tags: ['Photography', 'Guide', 'Creative'],
      availability: 'Flexible',
      trustScore: 92,
    ),
    DiscoveryModel(
      id: 'd5',
      title: 'Bengaluru Systems Architecture Roundtable',
      type: DiscoveryType.communities,
      itemType: 'community',
      category: 'Communities',
      description: 'Monthly peer discussions on event-driven backends, distributed systems, and real-time reliability.',
      location: 'Bengaluru',
      meta: 'This Saturday',
      actionLabel: 'RSVP',
      skills: ['Architecture', 'Meetup', 'Systems'],
      tags: ['Architecture', 'Meetup', 'Systems'],
      availability: 'Weekends',
      trustScore: 97,
    ),
    DiscoveryModel(
      id: 'd6',
      title: 'Hardware Diagnostics & Board Repair',
      type: DiscoveryType.services,
      itemType: 'help',
      category: 'Services',
      authorName: 'Ravi Kumar',
      description: 'Certified component-level motherboard diagnostics, thermal maintenance, and display troubleshooting.',
      location: 'Chennai',
      meta: 'Available today',
      actionLabel: 'Request',
      skills: ['Laptop repair', 'Hardware', 'Troubleshooting'],
      tags: ['Laptop repair', 'Hardware', 'Troubleshooting'],
      availability: 'Available today',
      trustScore: 99,
    ),
    DiscoveryModel(
      id: 'd7',
      title: 'Remote Frontend Engineering Fellowship',
      type: DiscoveryType.opportunities,
      itemType: 'opportunity',
      category: 'Opportunities',
      description: 'Full-time remote fellowship working alongside senior production engineers on large-scale web apps.',
      location: 'Remote',
      meta: 'Active cohort',
      actionLabel: 'Apply',
      skills: ['Frontend developer', 'Remote job', 'Engineering'],
      tags: ['Frontend developer', 'Remote job', 'Engineering'],
      availability: 'Flexible',
      trustScore: 96,
    ),
  ];

  /// Pure deterministic match score between a candidate and search query.
  /// Higher score denotes closer match.
  static int calculateMatchScore({
    required DiscoveryModel item,
    required String query,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return 0;

    int score = 0;
    final titleLower = item.title.toLowerCase();
    final descLower = item.description.toLowerCase();
    final categoryLower = (item.category ?? item.type.label).toLowerCase();
    final locationLower = item.location.toLowerCase();
    final availabilityLower = (item.availability ?? item.meta).toLowerCase();
    final authorLower = (item.authorName ?? '').toLowerCase();
    final skillsLower = item.skills.map((s) => s.toLowerCase()).toList();

    // 1. Exact query match bonuses
    if (titleLower == cleanQuery) {
      score += 150;
    } else if (titleLower.contains(cleanQuery)) {
      score += 100;
    }

    if (skillsLower.any((s) => s == cleanQuery)) {
      score += 120;
    } else if (skillsLower.any((s) => s.contains(cleanQuery))) {
      score += 80;
    }

    if (authorLower.contains(cleanQuery)) {
      score += 60;
    }

    if (categoryLower.contains(cleanQuery)) {
      score += 50;
    }

    if (descLower.contains(cleanQuery)) {
      score += 40;
    }

    if (locationLower.contains(cleanQuery)) {
      score += 30;
    }

    if (availabilityLower.contains(cleanQuery)) {
      score += 20;
    }

    // 2. Token-level matching for multi-word phrases (e.g. "java tutor", "laptop repair")
    final tokens = cleanQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    if (tokens.length > 1) {
      for (final token in tokens) {
        if (titleLower.contains(token)) score += 30;
        if (skillsLower.any((s) => s.contains(token))) score += 25;
        if (authorLower.contains(token)) score += 20;
        if (categoryLower.contains(token)) score += 15;
        if (descLower.contains(token)) score += 10;
        if (locationLower.contains(token)) score += 10;
        if (availabilityLower.contains(token)) score += 5;
      }
    }

    return score;
  }

  /// Determines whether a candidate satisfies all applied filter constraints.
  static bool matchesFilter({
    required DiscoveryModel item,
    required SearchFilter filter,
  }) {
    // 1. Category Filter
    if (filter.category != null) {
      final catName = filter.category!.label.toLowerCase();
      final typeMatches = item.type == filter.category;
      final categoryFieldMatches = (item.category ?? '').toLowerCase().contains(
        catName,
      );
      if (!typeMatches && !categoryFieldMatches) {
        return false;
      }
    }

    // 2. Type Filter (I Need vs I Can Help)
    if (filter.type != null &&
        filter.type!.isNotEmpty &&
        filter.type!.toLowerCase() != 'all') {
      final desiredType = filter.type!.toLowerCase();
      final itemType = (item.itemType ?? '').toLowerCase();
      if (itemType.isNotEmpty && itemType != desiredType) {
        return false;
      }
    }

    // 3. Location Filter
    if (filter.location != null &&
        filter.location!.trim().isNotEmpty &&
        filter.location!.toLowerCase() != 'all') {
      final filterLoc = filter.location!.trim().toLowerCase();
      final itemLoc = item.location.toLowerCase();
      if (!itemLoc.contains(filterLoc)) {
        return false;
      }
    }

    // 4. Availability Filter
    if (filter.availability != null &&
        filter.availability!.trim().isNotEmpty &&
        filter.availability!.toLowerCase() != 'any') {
      final filterAvail = filter.availability!.trim().toLowerCase();
      final itemAvail = (item.availability ?? item.meta).toLowerCase();
      if (!itemAvail.contains(filterAvail)) {
        return false;
      }
    }

    return true;
  }

  /// Sorts items by relevance or recency deterministically.
  static List<DiscoveryModel> sortResults({
    required List<DiscoveryModel> items,
    required String query,
    required SearchSortBy sortBy,
  }) {
    final hasQuery = query.trim().isNotEmpty;
    final list = List<DiscoveryModel>.from(items);

    list.sort((a, b) {
      if (sortBy == SearchSortBy.recent) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final comp = bDate.compareTo(aDate);
        if (comp != 0) return comp;
        if (hasQuery) {
          final scoreA = calculateMatchScore(item: a, query: query);
          final scoreB = calculateMatchScore(item: b, query: query);
          return scoreB.compareTo(scoreA);
        }
        return 0;
      } else {
        // Relevance sorting
        if (hasQuery) {
          final scoreA = calculateMatchScore(item: a, query: query);
          final scoreB = calculateMatchScore(item: b, query: query);
          final comp = scoreB.compareTo(scoreA);
          if (comp != 0) return comp;
        }
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      }
    });

    return list;
  }

  /// Filter, score, rank, and limit candidate discoveries in-memory.
  static List<DiscoveryModel> filterAndRank({
    required List<DiscoveryModel> candidates,
    required String query,
    required SearchFilter filter,
    Set<String> blockedUserIds = const {},
    int limit = 30,
  }) {
    final hasQuery = query.trim().isNotEmpty;

    final filtered = candidates
        .where((item) {
          // Exclude blocked users from discovery
          if (blockedUserIds.isNotEmpty) {
            if (item.authorId != null &&
                blockedUserIds.contains(item.authorId)) {
              return false;
            }
            if (blockedUserIds.contains(item.id)) {
              return false;
            }
          }
          if (!matchesFilter(item: item, filter: filter)) {
            return false;
          }
          if (hasQuery) {
            final score = calculateMatchScore(item: item, query: query);
            if (score == 0) return false;
          }
          return true;
        })
        .toList(growable: false);

    final sorted = sortResults(
      items: filtered,
      query: query,
      sortBy: filter.sortBy,
    );

    if (sorted.length > limit) {
      return sorted.sublist(0, limit);
    }
    return sorted;
  }

  /// Execute a practical bounded discovery search combining Firestore needs and helpers.
  Future<List<DiscoveryModel>> searchDiscoveries({
    required String query,
    required SearchFilter filter,
    Set<String> blockedUserIds = const {},
    int limit = 30,
  }) async {
    final List<DiscoveryModel> firestoreCandidates = [];
    final Set<String> seenIds = {};

    try {
      // 1. Bounded query on 'needs' collection (max 30 items)
      Query<Map<String, dynamic>> needsQuery = _needsCollection;

      if (filter.type != null &&
          filter.type!.isNotEmpty &&
          filter.type!.toLowerCase() != 'all') {
        needsQuery = needsQuery.where('type', isEqualTo: filter.type);
      }

      needsQuery = needsQuery.orderBy('createdAt', descending: true).limit(30);

      final needsSnapshot = await needsQuery.get();
      for (final doc in needsSnapshot.docs) {
        final need = NeedModel.fromMap(doc.id, doc.data());
        final discovery = DiscoveryModel.fromNeedModel(need);
        firestoreCandidates.add(discovery);
        seenIds.add(discovery.id);
      }
    } catch (e) {
      debugPrint('SearchService: needs query fallback notice: $e');
    }

    try {
      // 2. Bounded query on 'users' collection (max 20 items)
      // Only include helper profiles if user is looking for People / Help / All
      final includeUsers =
          (filter.type == null ||
              filter.type!.isEmpty ||
              filter.type!.toLowerCase() == 'all' ||
              filter.type == 'help') &&
          (filter.category == null || filter.category == DiscoveryType.people);

      if (includeUsers) {
        final usersSnapshot = await _usersCollection.limit(20).get();
        for (final doc in usersSnapshot.docs) {
          if (seenIds.contains(doc.id)) continue;
          final user = UserModel.fromMap(doc.id, doc.data());
          // Only include profiles with skills or helper tags
          if (user.skills.isNotEmpty || user.canHelpWith.isNotEmpty) {
            final discovery = DiscoveryModel.fromUserModel(user);
            firestoreCandidates.add(discovery);
            seenIds.add(discovery.id);
          }
        }
      }
    } catch (e) {
      debugPrint('SearchService: users query fallback notice: $e');
    }

    // 3. Fallback seeds ONLY when Firestore is empty (e.g. initial cold start, offline, or tests)
    final allCandidates = firestoreCandidates.isNotEmpty
        ? firestoreCandidates
        : seedDiscoveries;

    return filterAndRank(
      candidates: allCandidates,
      query: query,
      filter: filter,
      blockedUserIds: blockedUserIds,
      limit: limit,
    );
  }
}
