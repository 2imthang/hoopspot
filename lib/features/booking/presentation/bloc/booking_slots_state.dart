part of 'booking_slots_cubit.dart';

abstract class BookingSlotsState extends Equatable {
  const BookingSlotsState();

  @override
  List<Object?> get props => [];
}

class BookingSlotsLoading extends BookingSlotsState {
  const BookingSlotsLoading();
}

class BookingSlotsError extends BookingSlotsState {
  final String message;

  const BookingSlotsError(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingSlotsLoaded extends BookingSlotsState {
  final DateTime date;
  final List<String> allSlots;
  final Set<String> bookedSlots;
  final Set<String> selectedSlots;
  final bool submitting;

  /// Set once after [BookingSlotsCubit.confirmBooking] holds every selected
  /// slot successfully — the UI reacts to it once via `BlocListener`.
  final bool success;

  /// IDs of the bookings just created — only meaningful when [success] is
  /// true, that's what the Payment screen (TASK-023) needs to pay for.
  final List<String> createdBookingIds;

  /// The time slots that were just confirmed — captured before
  /// [selectedSlots] gets cleared on success, so the Terms Confirmation
  /// screen (TASK-024) can show what's being paid for without re-fetching.
  final List<String> confirmedTimeSlots;

  /// Transient error to surface via SnackBar (e.g. a slot was taken by
  /// someone else in the meantime) — not part of `props` on purpose so it
  /// doesn't linger/re-trigger on unrelated rebuilds.
  final String? message;

  const BookingSlotsLoaded({
    required this.date,
    required this.allSlots,
    required this.bookedSlots,
    this.selectedSlots = const {},
    this.submitting = false,
    this.success = false,
    this.createdBookingIds = const [],
    this.confirmedTimeSlots = const [],
    this.message,
  });

  BookingSlotsLoaded copyWith({
    DateTime? date,
    List<String>? allSlots,
    Set<String>? bookedSlots,
    Set<String>? selectedSlots,
    bool? submitting,
    bool success = false,
    List<String> createdBookingIds = const [],
    List<String> confirmedTimeSlots = const [],
    String? message,
    bool clearMessage = false,
  }) {
    return BookingSlotsLoaded(
      date: date ?? this.date,
      allSlots: allSlots ?? this.allSlots,
      bookedSlots: bookedSlots ?? this.bookedSlots,
      selectedSlots: selectedSlots ?? this.selectedSlots,
      submitting: submitting ?? this.submitting,
      success: success,
      createdBookingIds: createdBookingIds,
      confirmedTimeSlots: confirmedTimeSlots,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    date,
    allSlots,
    bookedSlots,
    selectedSlots,
    submitting,
    success,
  ];
}
