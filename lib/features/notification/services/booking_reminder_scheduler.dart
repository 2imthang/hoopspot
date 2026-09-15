import 'dart:async';
import '../../../core/services/notification_service.dart';
import '../../booking/domain/entities/booking_entity.dart';
import '../../booking/domain/usecases/watch_my_bookings_usecase.dart';
import '../../court/domain/usecases/get_court_by_id_usecase.dart';

/// TASK-030 — dịch vụ nền (không phải Cubit, không có UI state riêng) chạy
/// suốt phiên đăng nhập: nghe live mọi booking của user, tự lên lịch nhắc
/// khi 1 booking chuyển `confirmed`, tự hủy lịch nhắc khi không còn
/// `confirmed` nữa (user tự hủy, hết hạn hoàn tiền, Owner hủy do mưa...) —
/// tất cả các luồng đó cuối cùng đều chỉ đổi `status` trên cùng 1 Firestore
/// doc, nên nghe đúng 1 stream này là đủ, không cần móc riêng vào từng nơi.
///
/// Được `start()` 1 lần ở `routeAfterAuth` (giống [FavoriteCubit] — bài học
/// từ TASK-028: phải là dịch vụ sống suốt phiên app, không gắn vào 1 trang
/// cụ thể, vì user có thể không bao giờ mở tab "Lịch sử").
class BookingReminderScheduler {
  final WatchMyBookingsUseCase watchMyBookingsUseCase;
  final GetCourtByIdUseCase getCourtByIdUseCase;
  final NotificationService notificationService;

  StreamSubscription<List<BookingEntity>>? _subscription;
  final Map<String, String> _courtNames = {};

  BookingReminderScheduler({
    required this.watchMyBookingsUseCase,
    required this.getCourtByIdUseCase,
    required this.notificationService,
  });

  void start(String userId) {
    stop();
    _subscription = watchMyBookingsUseCase(userId).listen(_reconcile);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _reconcile(List<BookingEntity> bookings) async {
    final pendingIds = await notificationService.pendingNotificationIds();

    for (final booking in bookings) {
      final hasScheduled = notificationService.hasScheduledReminder(
        booking.id,
        pendingIds,
      );
      if (booking.status == BookingStatus.confirmed) {
        if (hasScheduled) continue;
        final playStart = _parsePlayStart(booking.date, booking.timeSlot);
        if (!playStart.isAfter(DateTime.now().toUtc())) continue;
        final courtName = await _resolveCourtName(booking.courtId);
        await notificationService.scheduleBookingReminders(
          bookingId: booking.id,
          courtName: courtName,
          playStartUtc: playStart,
        );
      } else if (hasScheduled) {
        await notificationService.cancelBookingReminders(booking.id);
      }
    }
  }

  Future<String> _resolveCourtName(String courtId) async {
    final cached = _courtNames[courtId];
    if (cached != null) return cached;
    final result = await getCourtByIdUseCase(GetCourtByIdParams(courtId));
    return result.fold((_) => 'bóng rổ', (court) {
      _courtNames[courtId] = court.name;
      return court.name;
    });
  }

  /// `date`/`timeSlot` là giờ VN (GMT+7) dạng chuỗi thuần — quy đổi đúng
  /// thời điểm UTC thật, giống hệt cách làm ở `BookingHistoryCubit` và
  /// Worker's `refundExecution.ts`.
  DateTime _parsePlayStart(String date, String timeSlot) {
    final parts = date.split('-').map(int.parse).toList();
    final startHour = int.parse(timeSlot.split('-')[0].split(':')[0]);
    return DateTime.utc(
      parts[0],
      parts[1],
      parts[2],
      startHour,
    ).subtract(const Duration(hours: 7));
  }
}
