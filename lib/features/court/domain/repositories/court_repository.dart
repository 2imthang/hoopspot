import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/court_entity.dart';
import '../entities/day_schedule.dart';

abstract class CourtRepository {
  Future<Either<Failure, CourtEntity>> createCourt({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> imageUrls,
    required int pricePerSlot,
    required List<String> amenities,
    required bool isOutdoor,
  });

  /// Updates the editable info fields of a court. Does not touch
  /// `weeklySchedule` (configured separately, see TASK-018) or `isHidden`
  /// (Admin-only, see TASK-034).
  Future<Either<Failure, CourtEntity>> updateCourt({
    required String courtId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> imageUrls,
    required int pricePerSlot,
    required List<String> amenities,
    required bool isOutdoor,
  });

  Future<Either<Failure, void>> deleteCourt(String courtId);

  /// TASK-031 — cấu hình giờ hoạt động riêng, tách khỏi [updateCourt] vì
  /// màn Schedule Config chỉ sửa đúng field này.
  Future<Either<Failure, CourtEntity>> updateCourtSchedule({
    required String courtId,
    required Map<Weekday, DaySchedule> weeklySchedule,
  });

  /// Courts owned by the currently signed-in Owner.
  Future<Either<Failure, List<CourtEntity>>> getOwnerCourts();

  Future<Either<Failure, CourtEntity>> getCourtById(String courtId);

  /// All non-hidden courts — used by Home/Search for browsing.
  Future<Either<Failure, List<CourtEntity>>> getVisibleCourts();

  /// TASK-034 — mọi sân, kể cả đã ẩn (Admin cần thấy để có thể hiện lại).
  Future<Either<Failure, List<CourtEntity>>> getAllCourts();

  /// TASK-034 — Admin ẩn/hiện sân vi phạm. Chỉ đổi đúng field `isHidden`,
  /// không đụng tới field khác (Firestore rule cũng chỉ cho phép đúng
  /// field này khi người gọi là Admin, xem `firestore.rules`).
  Future<Either<Failure, void>> setCourtHidden({
    required String courtId,
    required bool isHidden,
  });
}
