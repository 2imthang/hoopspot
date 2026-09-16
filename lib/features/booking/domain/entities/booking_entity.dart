import 'package:equatable/equatable.dart';

/// Mirrors the booking lifecycle described in the functional spec (4.4/4.11).
/// `pendingPayment` is held for 10 minutes (see [BookingEntity.expiresAt])
/// before auto-expiring back to an open slot if unpaid.
enum BookingStatus { pendingPayment, confirmed, cancelled, completed }

class BookingEntity extends Equatable {
  final String id;
  final String userId;

  /// Snapshot of the renter's `displayName` at booking time (TASK-032) —
  /// Owner Bookings shows "khách" nhưng Owner không có quyền đọc
  /// `users/{userId}` của người khác (Security Rules chỉ cho tự đọc), nên
  /// phải lưu kèm ở đây, giống cách Review (TASK-029) snapshot `userName`.
  final String userName;

  final String courtId;
  final String ownerId;

  /// Day of the booking, `yyyy-MM-dd` — kept as a plain string (not a
  /// [DateTime]) so exact-match Firestore queries by day don't need to
  /// worry about time-of-day/timezone parts.
  final String date;

  /// A fixed 2-hour "ca", e.g. `06:00-08:00`.
  final String timeSlot;

  /// Snapshot of the court's price at booking time, so a later price
  /// change on the court doesn't alter what an existing booking owes/paid.
  final int pricePerSlot;

  final BookingStatus status;

  /// Only meaningful while [status] is `pendingPayment` — the slot-hold
  /// deadline (10 minutes after creation). Null for every other status.
  final DateTime? expiresAt;

  final DateTime createdAt;

  /// Set by the payment Worker (TASK-025/026) once a cancel+refund was
  /// attempted: `'refunded'` or `'refund_pending'` (VNPay call failed,
  /// functional-spec says don't leave it ambiguous). Null = never attempted.
  final String? refundStatus;

  /// `'user_cancel'` or `'rain'` — only set alongside [refundStatus], lets
  /// Booking History (TASK-027) show *why* a booking was cancelled.
  final String? cancelReason;

  const BookingEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.courtId,
    required this.ownerId,
    required this.date,
    required this.timeSlot,
    required this.pricePerSlot,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.refundStatus,
    this.cancelReason,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    courtId,
    ownerId,
    date,
    timeSlot,
    pricePerSlot,
    status,
    expiresAt,
    createdAt,
    refundStatus,
    cancelReason,
  ];
}
