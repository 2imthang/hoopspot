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

  const CourtDetailLoaded(this.court);

  @override
  List<Object?> get props => [court];
}

class CourtDetailError extends CourtDetailState {
  final String message;

  const CourtDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
