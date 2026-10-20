/// Model representing a ranked match candidate for a specific need.
class MatchResult {
  const MatchResult({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.skills,
    required this.location,
    required this.availability,
    required this.trustScore,
    required this.score,
    required this.matchedSkills,
    this.offerTitle,
    this.skillScore = 0.0,
    this.locationScore = 0.0,
    this.availabilityScore = 0.0,
    this.categoryScore = 0.0,
    this.trustScoreComponent = 0.0,
  });

  final String id;
  final String userId;
  final String name;
  final String category;
  final List<String> skills;
  final String location;
  final String availability;
  final int trustScore;
  final double score; // 0.0 to 100.0
  final List<String> matchedSkills;
  final String? offerTitle;

  // Breakdown components
  final double skillScore; // max 40.0
  final double locationScore; // max 20.0
  final double availabilityScore; // max 15.0
  final double categoryScore; // max 15.0
  final double trustScoreComponent; // max 10.0

  int get matchPercentage => score.round().clamp(0, 100);
}
