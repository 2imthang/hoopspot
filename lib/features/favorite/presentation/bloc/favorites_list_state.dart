part of 'favorites_list_cubit.dart';

abstract class FavoritesListState extends Equatable {
  const FavoritesListState();

  @override
  List<Object?> get props => [];
}

class FavoritesListLoading extends FavoritesListState {
  const FavoritesListLoading();
}

class FavoritesListLoaded extends FavoritesListState {
  final List<CourtEntity> courts;

  const FavoritesListLoaded(this.courts);

  @override
  List<Object?> get props => [courts];
}
