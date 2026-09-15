import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/review_repository.dart';

class CreateReviewUseCase implements UseCase<void, CreateReviewParams> {
  final ReviewRepository repository;

  const CreateReviewUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CreateReviewParams params) {
    return repository.createReview(
      bookingId: params.bookingId,
      courtId: params.courtId,
      rating: params.rating,
      comment: params.comment,
    );
  }
}

class CreateReviewParams extends Equatable {
  final String bookingId;
  final String courtId;
  final int rating;
  final String comment;

  const CreateReviewParams({
    required this.bookingId,
    required this.courtId,
    required this.rating,
    required this.comment,
  });

  @override
  List<Object?> get props => [bookingId, courtId, rating, comment];
}
