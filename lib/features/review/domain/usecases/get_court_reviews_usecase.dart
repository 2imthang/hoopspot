import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/review_entity.dart';
import '../repositories/review_repository.dart';

class GetCourtReviewsUseCase implements UseCase<List<ReviewEntity>, String> {
  final ReviewRepository repository;

  const GetCourtReviewsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ReviewEntity>>> call(String courtId) {
    return repository.getCourtReviews(courtId);
  }
}
