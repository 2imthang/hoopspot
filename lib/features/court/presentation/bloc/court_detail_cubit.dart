import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../review/domain/entities/review_entity.dart';
import '../../../review/domain/usecases/get_court_reviews_usecase.dart';
import '../../domain/entities/court_entity.dart';
import '../../domain/usecases/get_court_by_id_usecase.dart';

part 'court_detail_state.dart';

class CourtDetailCubit extends Cubit<CourtDetailState> {
  final GetCourtByIdUseCase getCourtByIdUseCase;
  final GetCourtReviewsUseCase getCourtReviewsUseCase;

  CourtDetailCubit({
    required this.getCourtByIdUseCase,
    required this.getCourtReviewsUseCase,
  }) : super(const CourtDetailLoading());

  Future<void> loadCourt(String courtId) async {
    emit(const CourtDetailLoading());
    final result = await getCourtByIdUseCase(GetCourtByIdParams(courtId));
    await result.fold(
      (failure) async => emit(CourtDetailError(failure.message)),
      (court) async {
        final reviewsResult = await getCourtReviewsUseCase(courtId);
        final reviews = reviewsResult.fold((_) => <ReviewEntity>[], (r) => r);
        emit(CourtDetailLoaded(court, reviews: reviews));
      },
    );
  }
}
