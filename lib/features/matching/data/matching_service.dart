import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../auth/data/auth_service.dart';
import '../../needs/data/need_model.dart';
import '../../safety/data/safety_repository.dart';
import '../../user/data/user_model.dart';
import 'match_result.dart';

/// Service implementing Matching V1 rule-based scoring:
/// - Skill relevance: 40%
/// - Location relevance: 20%
/// - Availability relevance: 15%
/// - Category/intent relevance: 15%
/// - Trust score: 10%
class MatchingService {
  MatchingService({
    FirebaseFirestore? firestore,
    SafetyRepository? safetyRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _customSafetyRepo = safetyRepository;

  final FirebaseFirestore _firestore;
  final SafetyRepository? _customSafetyRepo;

  SafetyRepository get _safetyRepo =>
      _customSafetyRepo ?? SafetyRepository(firestore: _firestore);

  /// Find and rank the best matching "I Can Help" profiles/items for a given need.
  /// Uses strictly limited queries (max 20 candidates per collection) and in-memory scoring.
  Future<List<MatchResult>> findMatches(
    NeedModel need, {
    int limit = 5,
    String? currentUserId,
  }) async {
    try {
      final List<MatchResult> candidates = [];
      final Set<String> seenUserIds = {};
      final activeUserId = currentUserId ??
          (AuthService.instance.currentUser?.uid ?? '');
      final blockedIds = await _safetyRepo.getBlockedUserIds(
        activeUserId.isNotEmpty ? activeUserId : need.userId,
      );

      // 1. Fetch active Help items (limited to 20 documents)
      try {
        final helpSnapshot = await _firestore
            .collection('needs')
            .where('type', isEqualTo: 'help')
            .where('status', isEqualTo: 'active')
            .limit(20)
            .get();

        for (final doc in helpSnapshot.docs) {
          final data = doc.data();
          final candidateUserId = data['userId'] as String? ?? '';

          // Never match the user with their own post, current active user, or blocked users
          if (candidateUserId == need.userId ||
              (activeUserId.isNotEmpty && candidateUserId == activeUserId) ||
              blockedIds.contains(candidateUserId)) {
            continue;
          }

          final candidate = NeedModel.fromMap(doc.id, data);
          final scoreBreakdown = computeMatchScore(
            need: need,
            candidateSkills: candidate.skills,
            candidateLocation: candidate.location,
            candidateAvailability: candidate.availability ?? 'Flexible',
            candidateCategory: candidate.category,
            candidateTrustScore: 100, // Standard base trust
          );

          candidates.add(
            MatchResult(
              id: candidate.needId,
              userId: candidate.userId,
              name: candidate.authorName ?? 'Community Helper',
              category: candidate.category,
              skills: candidate.skills,
              location: candidate.location,
              availability: candidate.availability ?? 'Flexible',
              trustScore: 100,
              score: scoreBreakdown.totalScore,
              matchedSkills: scoreBreakdown.matchedSkills,
              offerTitle: candidate.title,
              skillScore: scoreBreakdown.skillScore,
              locationScore: scoreBreakdown.locationScore,
              availabilityScore: scoreBreakdown.availabilityScore,
              categoryScore: scoreBreakdown.categoryScore,
              trustScoreComponent: scoreBreakdown.trustScore,
            ),
          );

          seenUserIds.add(candidateUserId);
        }
      } catch (e) {
        debugPrint('MatchingService: help items query notice: $e');
      }

      // 2. Fetch User profiles with skills/help capabilities (limited to 20 documents)
      try {
        final usersSnapshot = await _firestore
            .collection('users')
            .limit(20)
            .get();

        for (final doc in usersSnapshot.docs) {
          final candidateUserId = doc.id;
          if (candidateUserId == need.userId ||
              (activeUserId.isNotEmpty && candidateUserId == activeUserId) ||
              seenUserIds.contains(candidateUserId) ||
              blockedIds.contains(candidateUserId)) {
            continue;
          }

          final user = UserModel.fromMap(candidateUserId, doc.data());

          // Merge profile skills and canHelpWith
          final allSkills = {...user.skills, ...user.canHelpWith}.toList();

          final scoreBreakdown = computeMatchScore(
            need: need,
            candidateSkills: allSkills,
            candidateLocation: user.city.isNotEmpty ? user.city : user.country,
            candidateAvailability: user.availability,
            candidateCategory: 'General',
            candidateTrustScore: user.trustScore,
          );

          candidates.add(
            MatchResult(
              id: user.uid,
              userId: user.uid,
              name: user.name.isNotEmpty ? user.name : 'NIVA Member',
              category: 'General',
              skills: allSkills,
              location: user.city.isNotEmpty ? user.city : user.country,
              availability: user.availability,
              trustScore: user.trustScore,
              score: scoreBreakdown.totalScore,
              matchedSkills: scoreBreakdown.matchedSkills,
              skillScore: scoreBreakdown.skillScore,
              locationScore: scoreBreakdown.locationScore,
              availabilityScore: scoreBreakdown.availabilityScore,
              categoryScore: scoreBreakdown.categoryScore,
              trustScoreComponent: scoreBreakdown.trustScore,
            ),
          );
        }
      } catch (e) {
        debugPrint('MatchingService: users query notice: $e');
      }

      // 3. Rank candidates by highest total match score descending
      candidates.sort((a, b) => b.score.compareTo(a.score));

      return candidates.take(limit).toList(growable: false);
    } catch (e) {
      debugPrint('MatchingService.findMatches error: $e');
      return const [];
    }
  }

  /// Pure rule-based scoring engine applying exact weights:
  /// - Skill: 40%
  /// - Location: 20%
  /// - Availability: 15%
  /// - Category/Intent: 15%
  /// - Trust: 10%
  static ({
    double totalScore,
    double skillScore,
    double locationScore,
    double availabilityScore,
    double categoryScore,
    double trustScore,
    List<String> matchedSkills,
  })
  computeMatchScore({
    required NeedModel need,
    required List<String> candidateSkills,
    required String candidateLocation,
    required String candidateAvailability,
    required String candidateCategory,
    required int candidateTrustScore,
  }) {
    // 1. Skill Relevance (40%)
    final matchedSkills = <String>[];
    double skillRatio = 0.0;

    if (need.skills.isNotEmpty) {
      final needSkillsLower = need.skills
          .map((s) => s.toLowerCase().trim())
          .where((s) => s.isNotEmpty)
          .toSet();
      for (final skill in candidateSkills) {
        final sLower = skill.toLowerCase().trim();
        if (sLower.isEmpty) continue;
        for (final ns in needSkillsLower) {
          if (sLower == ns || sLower.contains(ns) || ns.contains(sLower)) {
            if (!matchedSkills.contains(skill)) {
              matchedSkills.add(skill);
            }
            break;
          }
        }
      }
      if (matchedSkills.isNotEmpty) {
        final matchFraction = matchedSkills.length / needSkillsLower.length;
        skillRatio = (0.5 + (0.5 * matchFraction)).clamp(0.0, 1.0);
      }
    } else {
      final needKeywords = _extractKeywords(need);
      for (final skill in candidateSkills) {
        final sLower = skill.toLowerCase().trim();
        if (sLower.isEmpty) continue;
        for (final kw in needKeywords) {
          if (sLower == kw || sLower.contains(kw) || kw.contains(sLower)) {
            if (!matchedSkills.contains(skill)) {
              matchedSkills.add(skill);
            }
            break;
          }
        }
      }
      if (needKeywords.isNotEmpty && matchedSkills.isNotEmpty) {
        final matchRatio = matchedSkills.length / needKeywords.length;
        skillRatio = (0.5 + (matchRatio * 0.5)).clamp(0.0, 1.0);
      }
    }

    if (skillRatio == 0.0 && matchedSkills.isNotEmpty) {
      skillRatio = 0.8;
    } else if (skillRatio == 0.0 &&
        need.category.toLowerCase() == candidateCategory.toLowerCase()) {
      skillRatio = 0.25;
    }
    final skillScore = skillRatio * 40.0;

    // 2. Location Relevance (20%)
    final needLoc = need.location.toLowerCase().trim();
    final candLoc = candidateLocation.toLowerCase().trim();
    double locationRatio = 0.2; // default for different non-remote locations

    final isNeedRemote =
        needLoc == 'remote' ||
        needLoc == 'online' ||
        needLoc.contains('remote');
    final isCandRemote =
        candLoc == 'remote' ||
        candLoc == 'online' ||
        candLoc.contains('remote');

    if (isNeedRemote && isCandRemote) {
      locationRatio = 1.0;
    } else if (isNeedRemote || isCandRemote) {
      locationRatio = 0.9;
    } else if (needLoc.isNotEmpty &&
        candLoc.isNotEmpty &&
        (needLoc == candLoc ||
            needLoc.contains(candLoc) ||
            candLoc.contains(needLoc))) {
      locationRatio = 1.0;
    }
    final locationScore = locationRatio * 20.0;

    // 3. Availability Relevance (15%)
    final urgency = need.urgency.toLowerCase().trim();
    final avail = candidateAvailability.toLowerCase().trim();
    double availRatio = 0.5;

    if (urgency.contains('urgent')) {
      if (avail.contains('today') || avail == 'available') {
        availRatio = 1.0;
      } else if (avail.contains('flexible')) {
        availRatio = 0.75;
      } else if (avail.contains('weekend')) {
        availRatio = 0.4;
      }
    } else if (urgency.contains('week')) {
      if (avail.contains('today') ||
          avail.contains('flexible') ||
          avail.contains('part-time')) {
        availRatio = 1.0;
      } else if (avail.contains('weekend')) {
        availRatio = 0.85;
      }
    } else {
      // Flexible need
      if (avail.contains('today') || avail == 'available') {
        availRatio = 1.0;
      } else if (avail.contains('flexible')) {
        availRatio = 0.9;
      } else {
        availRatio = 0.8;
      }
    }
    final availabilityScore = availRatio * 15.0;

    // 4. Category/Intent Relevance (15%)
    final needCat = need.category.toLowerCase().trim();
    final candCat = candidateCategory.toLowerCase().trim();
    double catRatio = 0.2;

    if (needCat.isNotEmpty && candCat.isNotEmpty && needCat == candCat) {
      catRatio = 1.0;
    } else if (needCat == 'general' || candCat == 'general') {
      catRatio = 0.6;
    } else if ((needCat.contains('edu') && candCat.contains('info')) ||
        (needCat.contains('tech') && candCat.contains('serv')) ||
        (needCat.contains('creat') && candCat.contains('peop'))) {
      catRatio = 0.75;
    }
    final categoryScore = catRatio * 15.0;

    // 5. Trust Score (10%)
    final trustRatio = (candidateTrustScore.clamp(0, 100)) / 100.0;
    final trustScore = trustRatio * 10.0;

    final totalScore =
        (skillScore +
                locationScore +
                availabilityScore +
                categoryScore +
                trustScore)
            .clamp(0.0, 100.0);

    return (
      totalScore: totalScore,
      skillScore: skillScore,
      locationScore: locationScore,
      availabilityScore: availabilityScore,
      categoryScore: categoryScore,
      trustScore: trustScore,
      matchedSkills: matchedSkills,
    );
  }

  static Set<String> _extractKeywords(NeedModel need) {
    final keywords = <String>{};
    for (final s in need.skills) {
      final trimmed = s.toLowerCase().trim();
      if (trimmed.isNotEmpty) keywords.add(trimmed);
    }

    const stopWords = {
      'need',
      'looking',
      'want',
      'help',
      'with',
      'for',
      'the',
      'and',
      'a',
      'an',
      'in',
      'to',
      'of',
      'from',
      'someone',
      'who',
      'can',
      'please',
    };

    final text = '${need.title} ${need.description}'.toLowerCase();
    final words = text.split(RegExp(r'[^a-zA-Z0-9+#]'));
    for (final w in words) {
      final trimmed = w.trim();
      if (trimmed.length >= 3 && !stopWords.contains(trimmed)) {
        keywords.add(trimmed);
      }
    }
    return keywords;
  }
}
