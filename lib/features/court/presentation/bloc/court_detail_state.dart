part of 'court_detail_cubit.dart';

abstract class CourtDetailState extends Equatable {
  const CourtDetailState();

  @override
  List<Object?> get props => [];
}

class CourtDetailLoading extends CourtDetailState {
  const CourtDetailLoading();
}

class CourtDetailLoaded extends CourtDetailState {
  final CourtEntity court;
  final List<ReviewEntity> reviews;

  const CourtDetailLoaded(this.court, {this.reviews = const []});

  double get averageRating {
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  }

  @override
  List<Object?> get props => [court, reviews];
}

class CourtDetailError extends CourtDetailState {
  final String message;

  const CourtDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
