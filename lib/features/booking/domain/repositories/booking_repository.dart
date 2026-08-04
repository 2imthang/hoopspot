import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';

abstract class BookingRepository {
  /// Creates a booking for the given (courtId, date, timeSlot), holding it
  /// as `pendingPayment` for 10 minutes. Uses a Firestore transaction so
  /// two users booking the same slot at the same time can't both succeed —
  /// returns [SlotUnavailableFailure] for whichever one loses the race.
  Future<Either<Failure, BookingEntity>> createBooking({
    required String courtId,
    required String ownerId,
    required String date,
    required String timeSlot,
    required int pricePerSlot,
  });
}
