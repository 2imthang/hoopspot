part of 'favorite_cubit.dart';

abstract class FavoriteState extends Equatable {
  const FavoriteState();

  @override
  List<Object?> get props => [];
}

class FavoriteLoading extends FavoriteState {
  const FavoriteLoading();
}

class FavoriteLoaded extends FavoriteState {
  final Set<String> courtIds;

  /// Lỗi tạm thời để hiện snackbar sau khi rollback — không nằm trong
  /// `props` để không hiện lại khi rebuild vì lý do khác.
  final String? message;

  const FavoriteLoaded(this.courtIds, {this.message});

  @override
  List<Object?> get props => [courtIds];
}
