part of 'owner_bookings_cubit.dart';

abstract class OwnerBookingsState extends Equatable {
  const OwnerBookingsState();

  @override
  List<Object?> get props => [];
}

class OwnerBookingsLoading extends OwnerBookingsState {
  const OwnerBookingsLoading();
}

/// TASK-036 — bắt lỗi stream qua `onError` (xem [OwnerBookingsCubit]), tránh
/// kẹt ở [OwnerBookingsLoading] mãi mãi khi mất mạng/mất quyền.
class OwnerBookingsError extends OwnerBookingsState {
  final String message;

  const OwnerBookingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class OwnerBookingsItem extends Equatable {
  final BookingEntity booking;
  final String courtName;

  /// Sân `isOutdoor` — quyết định có hiện nút "Hủy do mưa" hay không.
  final bool courtIsOutdoor;

  const OwnerBookingsItem({
    required this.booking,
    required this.courtName,
    required this.courtIsOutdoor,
  });

  /// `confirmed` + sân ngoài trời + buổi chơi CHƯA kết thúc — đúng điều
  /// kiện Worker `/rain-cancel` (functional-spec 4.5.B).
  bool get canRainCancel {
    if (booking.status != BookingStatus.confirmed || !courtIsOutdoor) return false;
    final end = parseSlotEndUtc(booking.date, booking.timeSlot);
    return end.isAfter(DateTime.now().toUtc());
  }

  @override
  List<Object?> get props => [booking, courtName, courtIsOutdoor];
}

class OwnerBookingsLoaded extends OwnerBookingsState {
  final List<OwnerBookingsItem> items;
  final OwnerBookingsFilter filter;

  /// ID booking đang gọi `/rain-cancel`, để khóa đúng nút đang bấm.
  final String? busyBookingId;

  /// Lỗi tạm thời để hiện snackbar — không nằm trong `props`.
  final String? message;

  const OwnerBookingsLoaded({
    required this.items,
    required this.filter,
    this.busyBookingId,
    this.message,
  });

  OwnerBookingsLoaded copyWith({
    List<OwnerBookingsItem>? items,
    OwnerBookingsFilter? filter,
    String? busyBookingId,
    String? message,
    bool clearMessage = false,
  }) {
    return OwnerBookingsLoaded(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      busyBookingId: busyBookingId,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [items, filter, busyBookingId];
}
