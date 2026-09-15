import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../court/domain/usecases/get_court_by_id_usecase.dart';
import '../../../review/domain/usecases/get_my_reviewed_booking_ids_usecase.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/usecases/cancel_booking_usecase.dart';
import '../../domain/usecases/watch_my_bookings_usecase.dart';

part 'booking_history_state.dart';

enum BookingHistoryFilter { all, upcoming, cancelled }

/// TASK-027 — danh sách booking của user + hủy lịch (gọi thật Worker
/// `/refund` xây ở TASK-025). Không tự cập nhật `status`/`refundStatus` sau
/// khi hủy — Worker ghi Firestore thật, [WatchMyBookingsUseCase]'s stream tự
/// đẩy trạng thái mới về UI, không cần refetch thủ công.
class BookingHistoryCubit extends Cubit<BookingHistoryState> {
  final String userId;
  final WatchMyBookingsUseCase watchMyBookingsUseCase;
  final GetCourtByIdUseCase getCourtByIdUseCase;
  final CancelBookingUseCase cancelBookingUseCase;
  final GetMyReviewedBookingIdsUseCase getMyReviewedBookingIdsUseCase;

  StreamSubscription<List<BookingEntity>>? _subscription;
  final Map<String, String> _courtNames = {};
  Set<String> _reviewedBookingIds = {};
  List<BookingEntity> _allBookings = const [];
  BookingHistoryFilter _filter = BookingHistoryFilter.all;

  BookingHistoryCubit({
    required this.userId,
    required this.watchMyBookingsUseCase,
    required this.getCourtByIdUseCase,
    required this.cancelBookingUseCase,
    required this.getMyReviewedBookingIdsUseCase,
  }) : super(const BookingHistoryLoading()) {
    _subscription = watchMyBookingsUseCase(userId).listen(_onBookingsUpdate);
  }

  Future<void> _onBookingsUpdate(List<BookingEntity> bookings) async {
    _allBookings = bookings;

    final missingCourtIds = bookings
        .map((b) => b.courtId)
        .toSet()
        .difference(_courtNames.keys.toSet());
    for (final courtId in missingCourtIds) {
      final result = await getCourtByIdUseCase(GetCourtByIdParams(courtId));
      result.fold((_) {}, (court) => _courtNames[courtId] = court.name);
    }

    await _loadReviewedBookingIds();
    _emit();
  }

  Future<void> _loadReviewedBookingIds() async {
    final result = await getMyReviewedBookingIdsUseCase(userId);
    result.fold((_) {}, (ids) => _reviewedBookingIds = ids);
  }

  /// Gọi sau khi [WriteReviewPage] gửi đánh giá thành công — ghi review
  /// không đổi `bookings` doc nên stream không tự đẩy cập nhật, phải refetch
  /// thủ công để ẩn nút "Viết đánh giá" ngay.
  Future<void> refreshReviewedIds() async {
    await _loadReviewedBookingIds();
    _emit();
  }

  void setFilter(BookingHistoryFilter filter) {
    _filter = filter;
    _emit();
  }

  Future<void> cancelBooking(String bookingId) async {
    final current = state;
    if (current is! BookingHistoryLoaded) return;

    emit(current.copyWith(cancellingBookingId: bookingId, clearMessage: true));
    final result = await cancelBookingUseCase(
      CancelBookingParams(userId: userId, bookingId: bookingId),
    );
    result.fold(
      (failure) => emit(
        state is BookingHistoryLoaded
            ? (state as BookingHistoryLoaded).copyWith(
                cancellingBookingId: null,
                message: failure.message,
              )
            : current,
      ),
      // Thành công thì không cần tự đổi state — booking stream (Firestore)
      // sẽ tự đẩy `status`/`refundStatus` mới khi Worker ghi xong.
      (_) {
        if (state is BookingHistoryLoaded) {
          emit((state as BookingHistoryLoaded).copyWith(cancellingBookingId: null));
        }
      },
    );
  }

  void _emit() {
    final previous = state is BookingHistoryLoaded
        ? state as BookingHistoryLoaded
        : null;
    final items = _allBookings
        .where(_matchesFilter)
        .map(
          (booking) => BookingHistoryItem(
            booking: booking,
            courtName: _courtNames[booking.courtId] ?? 'Sân bóng rổ',
            hasSlotEnded: _hasSlotEnded(booking),
            hasReviewed: _reviewedBookingIds.contains(booking.id),
          ),
        )
        .toList();
    emit(
      BookingHistoryLoaded(
        items: items,
        filter: _filter,
        cancellingBookingId: previous?.cancellingBookingId,
      ),
    );
  }

  bool _matchesFilter(BookingEntity booking) {
    switch (_filter) {
      case BookingHistoryFilter.all:
        return true;
      case BookingHistoryFilter.upcoming:
        return (booking.status == BookingStatus.pendingPayment ||
                booking.status == BookingStatus.confirmed) &&
            !_hasSlotEnded(booking);
      case BookingHistoryFilter.cancelled:
        return booking.status == BookingStatus.cancelled;
    }
  }

  bool _hasSlotEnded(BookingEntity booking) {
    final parts = booking.date.split('-').map(int.parse).toList();
    final endHour = int.parse(booking.timeSlot.split('-')[1].split(':')[0]);
    // `date`/`timeSlot` là giờ VN (GMT+7) — quy đổi đúng thời điểm UTC thật.
    final endUtcMs =
        DateTime.utc(parts[0], parts[1], parts[2], endHour).millisecondsSinceEpoch -
        7 * 60 * 60 * 1000;
    return DateTime.now().toUtc().millisecondsSinceEpoch >= endUtcMs;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
