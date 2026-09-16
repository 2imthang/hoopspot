import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/vn_time.dart';
import '../../../court/domain/entities/court_entity.dart';
import '../../../court/domain/usecases/get_court_by_id_usecase.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/usecases/rain_cancel_booking_usecase.dart';
import '../../domain/usecases/watch_owner_bookings_usecase.dart';

part 'owner_bookings_state.dart';

enum OwnerBookingsFilter { all, pendingPayment, confirmed, cancelled }

/// TASK-032 — tab "Đặt sân của khách" (chỉ Owner). Chỉ hiển thị trạng thái
/// booking, KHÔNG cho Owner tự xác nhận/từ chối thanh toán — mockup gốc có
/// nút này nhưng mâu thuẫn thật với functional-spec 4.11 ("tránh gian lận
/// xác nhận thanh toán giả"), người dùng đã chọn theo đúng spec chữ.
class OwnerBookingsCubit extends Cubit<OwnerBookingsState> {
  final String ownerId;
  final WatchOwnerBookingsUseCase watchOwnerBookingsUseCase;
  final GetCourtByIdUseCase getCourtByIdUseCase;
  final RainCancelBookingUseCase rainCancelBookingUseCase;

  StreamSubscription<List<BookingEntity>>? _subscription;
  final Map<String, CourtEntity> _courts = {};
  List<BookingEntity> _allBookings = const [];
  OwnerBookingsFilter _filter = OwnerBookingsFilter.all;

  OwnerBookingsCubit({
    required this.ownerId,
    required this.watchOwnerBookingsUseCase,
    required this.getCourtByIdUseCase,
    required this.rainCancelBookingUseCase,
  }) : super(const OwnerBookingsLoading()) {
    _subscription = watchOwnerBookingsUseCase(ownerId).listen(_onBookingsUpdate);
  }

  Future<void> _onBookingsUpdate(List<BookingEntity> bookings) async {
    _allBookings = bookings;

    final missingCourtIds = bookings
        .map((b) => b.courtId)
        .toSet()
        .difference(_courts.keys.toSet());
    for (final courtId in missingCourtIds) {
      final result = await getCourtByIdUseCase(GetCourtByIdParams(courtId));
      result.fold((_) {}, (court) => _courts[courtId] = court);
    }

    _emit();
  }

  void setFilter(OwnerBookingsFilter filter) {
    _filter = filter;
    _emit();
  }

  Future<void> rainCancel(String bookingId) async {
    final current = state;
    if (current is! OwnerBookingsLoaded) return;

    emit(current.copyWith(busyBookingId: bookingId, clearMessage: true));
    final result = await rainCancelBookingUseCase(
      RainCancelBookingParams(ownerId: ownerId, bookingId: bookingId),
    );
    result.fold(
      (failure) => emit(
        state is OwnerBookingsLoaded
            ? (state as OwnerBookingsLoaded).copyWith(
                busyBookingId: null,
                message: failure.message,
              )
            : current,
      ),
      // Không tự đổi state — Firestore stream sẽ tự đẩy status mới khi
      // Worker ghi xong, giống BookingHistoryCubit.cancelBooking.
      (_) {
        if (state is OwnerBookingsLoaded) {
          emit((state as OwnerBookingsLoaded).copyWith(busyBookingId: null));
        }
      },
    );
  }

  void _emit() {
    final previous = state is OwnerBookingsLoaded ? state as OwnerBookingsLoaded : null;
    final items = _allBookings
        .where(_matchesFilter)
        .map(
          (booking) => OwnerBookingsItem(
            booking: booking,
            courtName: _courts[booking.courtId]?.name ?? 'Sân bóng rổ',
            courtIsOutdoor: _courts[booking.courtId]?.isOutdoor ?? false,
          ),
        )
        .toList();
    emit(
      OwnerBookingsLoaded(
        items: items,
        filter: _filter,
        busyBookingId: previous?.busyBookingId,
      ),
    );
  }

  bool _matchesFilter(BookingEntity booking) {
    switch (_filter) {
      case OwnerBookingsFilter.all:
        return true;
      case OwnerBookingsFilter.pendingPayment:
        return booking.status == BookingStatus.pendingPayment;
      case OwnerBookingsFilter.confirmed:
        return booking.status == BookingStatus.confirmed;
      case OwnerBookingsFilter.cancelled:
        return booking.status == BookingStatus.cancelled;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
