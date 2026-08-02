part of 'search_cubit.dart';

/// Which filter panel (if any) is expanded below the chip row.
enum SearchFilterPanel { none, price, distance, amenities }

class SearchState extends Equatable {
  final bool loading;
  final String? errorMessage;
  final List<CourtEntity> allCourts;
  final String query;
  final RangeValues priceRange;
  final double minPrice;
  final double maxPrice;
  final List<String> availableAmenities;
  final Set<String> selectedAmenities;
  final SearchFilterPanel activePanel;

  const SearchState({
    required this.loading,
    required this.errorMessage,
    required this.allCourts,
    required this.query,
    required this.priceRange,
    required this.minPrice,
    required this.maxPrice,
    required this.availableAmenities,
    required this.selectedAmenities,
    required this.activePanel,
  });

  factory SearchState.initial(String query) => SearchState(
    loading: true,
    errorMessage: null,
    allCourts: const [],
    query: query,
    priceRange: const RangeValues(0, 0),
    minPrice: 0,
    maxPrice: 0,
    availableAmenities: const [],
    selectedAmenities: const {},
    activePanel: SearchFilterPanel.none,
  );

  /// Distance filtering isn't real yet (no GPS, see TASK-013 notes) so only
  /// text query, price range, and amenities actually narrow this list.
  List<CourtEntity> get filteredCourts {
    final q = query.trim().toLowerCase();
    return allCourts.where((court) {
      final matchesQuery =
          q.isEmpty ||
          court.name.toLowerCase().contains(q) ||
          court.address.toLowerCase().contains(q);
      final matchesPrice =
          court.pricePerSlot >= priceRange.start &&
          court.pricePerSlot <= priceRange.end;
      final matchesAmenities =
          selectedAmenities.isEmpty ||
          selectedAmenities.every(court.amenities.contains);
      return matchesQuery && matchesPrice && matchesAmenities;
    }).toList();
  }

  SearchState copyWith({
    bool? loading,
    String? errorMessage,
    String? query,
    RangeValues? priceRange,
    Set<String>? selectedAmenities,
    SearchFilterPanel? activePanel,
  }) {
    return SearchState(
      loading: loading ?? this.loading,
      errorMessage: errorMessage ?? this.errorMessage,
      allCourts: allCourts,
      query: query ?? this.query,
      priceRange: priceRange ?? this.priceRange,
      minPrice: minPrice,
      maxPrice: maxPrice,
      availableAmenities: availableAmenities,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      activePanel: activePanel ?? this.activePanel,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    errorMessage,
    allCourts,
    query,
    priceRange,
    minPrice,
    maxPrice,
    availableAmenities,
    selectedAmenities,
    activePanel,
  ];
}
