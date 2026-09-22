import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;

  const ReviewRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> createReview({
    required String bookingId,
    required String courtId,
    required int rating,
    required String comment,
  }) async {
    try {
      await remoteDataSource.createReview(
        bookingId: bookingId,
        courtId: courtId,
        rating: rating,
        comment: comment,
      );
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> getCourtReviews(String courtId) async {
    try {
      final reviews = await remoteDataSource.getCourtReviews(courtId);
      return Right(reviews);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getMyReviewedBookingIds(String userId) async {
    try {
      final ids = await remoteDataSource.getMyReviewedBookingIds(userId);
      return Right(ids);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
