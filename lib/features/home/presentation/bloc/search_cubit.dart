import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show RangeValues;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../court/domain/entities/court_entity.dart';
import '../../../court/domain/usecases/get_visible_courts_usecase.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final GetVisibleCourtsUseCase getVisibleCourtsUseCase;

  Timer? _debounce;

  SearchCubit({required this.getVisibleCourtsUseCase})
    : super(SearchState.initial(''));

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final result = await getVisibleCourtsUseCase(const NoParams());
    result.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (courts) {
        final prices = courts.map((c) => c.pricePerSlot.toDouble());
        final minPrice = prices.isEmpty
            ? 0.0
            : prices.reduce((a, b) => a < b ? a : b);
        final maxPrice = prices.isEmpty
            ? 500000.0
            : prices.reduce((a, b) => a > b ? a : b);
        final amenities = <String>{};
        for (final court in courts) {
          amenities.addAll(court.amenities);
        }
        emit(
          SearchState(
            loading: false,
            errorMessage: null,
            allCourts: courts,
            query: state.query,
            priceRange: RangeValues(minPrice, maxPrice),
            minPrice: minPrice,
            maxPrice: maxPrice,
            availableAmenities: amenities.toList()..sort(),
            selectedAmenities: const {},
            activePanel: SearchFilterPanel.none,
          ),
        );
      },
    );
  }

  void updateQuery(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      emit(state.copyWith(query: query));
    });
  }

  /// Sets the query without the debounce delay — used to seed the initial
  /// text carried over from Home's search bar.
  void setQueryImmediate(String query) {
    emit(state.copyWith(query: query));
  }

  void togglePanel(SearchFilterPanel panel) {
    emit(
      state.copyWith(
        activePanel: state.activePanel == panel
            ? SearchFilterPanel.none
            : panel,
      ),
    );
  }

  void updatePriceRange(RangeValues range) {
    emit(state.copyWith(priceRange: range));
  }

  void toggleAmenity(String amenity) {
    final updated = Set<String>.from(state.selectedAmenities);
    if (!updated.remove(amenity)) updated.add(amenity);
    emit(state.copyWith(selectedAmenities: updated));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
