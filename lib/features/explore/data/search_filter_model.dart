import 'discovery_model.dart';

/// Supported sort orders for discovery and search results.
enum SearchSortBy {
  relevance,
  recent;

  String get label => switch (this) {
    SearchSortBy.relevance => 'Most Relevant',
    SearchSortBy.recent => 'Most Recent',
  };
}

/// Filter criteria container for NIVA Search & Discovery.
class SearchFilter {
  const SearchFilter({
    this.category,
    this.location,
    this.type,
    this.availability,
    this.sortBy = SearchSortBy.relevance,
  });

  /// Category filter (All if null, or specific DiscoveryType).
  final DiscoveryType? category;

  /// Location filter ('Remote', custom city, or null/'All' for any location).
  final String? location;

  /// Type filter ('need', 'help', or null/'All' for both).
  final String? type;

  /// Availability filter ('Available today', 'Weekends', 'Flexible', or null for any).
  final String? availability;

  /// Sort option (relevance or recent).
  final SearchSortBy sortBy;

  /// Empty / default filter state.
  static const SearchFilter empty = SearchFilter();

  /// Whether any non-default filter is currently applied.
  bool get hasActiveFilters =>
      category != null ||
      (location != null &&
          location!.trim().isNotEmpty &&
          location!.toLowerCase() != 'all') ||
      (type != null && type!.isNotEmpty && type!.toLowerCase() != 'all') ||
      (availability != null &&
          availability!.trim().isNotEmpty &&
          availability!.toLowerCase() != 'any') ||
      sortBy != SearchSortBy.relevance;

  /// Count of active filters for UI badges.
  int get activeFiltersCount {
    int count = 0;
    if (category != null) count++;
    if (location != null &&
        location!.trim().isNotEmpty &&
        location!.toLowerCase() != 'all') {
      count++;
    }
    if (type != null && type!.isNotEmpty && type!.toLowerCase() != 'all') {
      count++;
    }
    if (availability != null &&
        availability!.trim().isNotEmpty &&
        availability!.toLowerCase() != 'any') {
      count++;
    }
    if (sortBy != SearchSortBy.relevance) count++;
    return count;
  }

  SearchFilter copyWith({
    DiscoveryType? Function()? category,
    String? Function()? location,
    String? Function()? type,
    String? Function()? availability,
    SearchSortBy? sortBy,
  }) {
    return SearchFilter(
      category: category != null ? category() : this.category,
      location: location != null ? location() : this.location,
      type: type != null ? type() : this.type,
      availability: availability != null ? availability() : this.availability,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFilter &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          location == other.location &&
          type == other.type &&
          availability == other.availability &&
          sortBy == other.sortBy;

  @override
  int get hashCode =>
      category.hashCode ^
      location.hashCode ^
      type.hashCode ^
      availability.hashCode ^
      sortBy.hashCode;
}
