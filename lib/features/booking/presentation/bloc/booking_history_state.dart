part of 'booking_history_cubit.dart';

abstract class BookingHistoryState extends Equatable {
  const BookingHistoryState();

  @override
  List<Object?> get props => [];
}

class BookingHistoryLoading extends BookingHistoryState {
  const BookingHistoryLoading();
}

class BookingHistoryItem extends Equatable {
  final BookingEntity booking;
  final String courtName;

  /// Slot đã qua giờ chơi chưa (giờ VN) — quyết định hiện "Hủy đặt sân" hay
  /// "Viết đánh giá" cho booking `confirmed` (TASK-029).
  final bool hasSlotEnded;

  /// Đã có review cho booking này chưa (TASK-029) — ẩn nút "Viết đánh giá"
  /// nếu đã đánh giá rồi.
  final bool hasReviewed;

  const BookingHistoryItem({
    required this.booking,
    required this.courtName,
    required this.hasSlotEnded,
    required this.hasReviewed,
  });

  @override
  List<Object?> get props => [booking, courtName, hasSlotEnded, hasReviewed];
}

class BookingHistoryLoaded extends BookingHistoryState {
  final List<BookingHistoryItem> items;
  final BookingHistoryFilter filter;

  /// ID booking đang gọi `/refund`, để khóa đúng nút đang bấm (không khóa
  /// toàn màn hình).
  final String? cancellingBookingId;

  /// Lỗi hủy tạm thời để hiện SnackBar — không nằm trong `props` để không
  /// bị hiện lại khi rebuild vì lý do khác.
  final String? message;

  const BookingHistoryLoaded({
    required this.items,
    required this.filter,
    this.cancellingBookingId,
    this.message,
  });

  BookingHistoryLoaded copyWith({
    List<BookingHistoryItem>? items,
    BookingHistoryFilter? filter,
    String? cancellingBookingId,
    String? message,
    bool clearMessage = false,
  }) {
    return BookingHistoryLoaded(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      cancellingBookingId: cancellingBookingId,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [items, filter, cancellingBookingId];
}
