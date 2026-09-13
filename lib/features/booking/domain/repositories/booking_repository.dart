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

  /// Time slots on [courtId] + [date] that are still actually taken — a
  /// slot whose 10-minute payment hold already expired counts as free.
  Future<Either<Failure, List<String>>> getBookedSlots({
    required String courtId,
    required String date,
  });

  /// Real-time updates for [bookingIds] — used by the Payment screen
  /// (TASK-023) to detect the moment IPN (TASK-021) flips a booking to
  /// `confirmed`/`cancelled`, instead of a manually-timed polling loop.
  Stream<List<BookingEntity>> watchBookingsStatus(List<String> bookingIds);

  /// Toàn bộ booking của 1 user — Booking History (TASK-027).
  Stream<List<BookingEntity>> watchMyBookings(String userId);

  /// Hủy 1 booking đã `confirmed` qua Worker (áp rule ≥6 tiếng + gọi VNPay
  /// Refund thật — TASK-025). Không tự sửa Firestore ở đây: Worker ghi
  /// `status`/`refundStatus` thật, [watchMyBookings]/[watchBookingsStatus]
  /// sẽ tự cập nhật UI qua stream khi Worker ghi xong.
  Future<Either<Failure, void>> cancelBooking({
    required String userId,
    required String bookingId,
  });
}
