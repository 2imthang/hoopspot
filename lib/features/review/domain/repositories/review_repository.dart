import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/review_entity.dart';

/// Doc ID của mỗi review == bookingId nó thuộc về — 1 booking chỉ tạo được
/// đúng 1 review (enforce bằng Firestore Security Rules: ghi lần 2 vào cùng
/// ID bị coi là `update`, bị chặn — xem `firestore.rules`).
abstract class ReviewRepository {
  Future<Either<Failure, void>> createReview({
    required String bookingId,
    required String courtId,
    required int rating,
    required String comment,
  });

  Future<Either<Failure, List<ReviewEntity>>> getCourtReviews(String courtId);

  Future<Either<Failure, Set<String>>> getMyReviewedBookingIds(String userId);
}
