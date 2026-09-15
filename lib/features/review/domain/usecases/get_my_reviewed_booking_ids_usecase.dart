import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/review_repository.dart';

class GetMyReviewedBookingIdsUseCase implements UseCase<Set<String>, String> {
  final ReviewRepository repository;

  const GetMyReviewedBookingIdsUseCase(this.repository);

  @override
  Future<Either<Failure, Set<String>>> call(String userId) {
    return repository.getMyReviewedBookingIds(userId);
  }
}
