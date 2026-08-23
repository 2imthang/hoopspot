import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../court/domain/entities/court_entity.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_booked_slots_usecase.dart';

part 'booking_slots_state.dart';

/// Length of 1 "ca" (fixed 2h slot), per functional spec 4.5.
const _slotHours = 2;

class BookingSlotsCubit extends Cubit<BookingSlotsState> {
  final CourtEntity court;
  final GetBookedSlotsUseCase getBookedSlotsUseCase;
  final CreateBookingUseCase createBookingUseCase;

  BookingSlotsCubit({
    required this.court,
    required this.getBookedSlotsUseCase,
    required this.createBookingUseCase,
  }) : super(const BookingSlotsLoading());

  Future<void> selectDate(DateTime date) async {
    emit(const BookingSlotsLoading());

    final weekday = Weekday.values[date.weekday - 1];
    final schedule = court.weeklySchedule[weekday];

    if (schedule == null || !schedule.isOpen) {
      emit(BookingSlotsLoaded(date: date, allSlots: const [], bookedSlots: const {}));
      return;
    }

    final allSlots = _generateSlots(schedule.openTime, schedule.closeTime);
    final result = await getBookedSlotsUseCase(
      GetBookedSlotsParams(courtId: court.id, date: formatDateKey(date)),
    );
    result.fold(
      (failure) => emit(BookingSlotsError(failure.message)),
      (booked) => emit(
        BookingSlotsLoaded(date: date, allSlots: allSlots, bookedSlots: booked.toSet()),
      ),
    );
  }

  void toggleSlot(String slot) {
    final current = state;
    if (current is! BookingSlotsLoaded || current.submitting) return;
    if (_isUnavailable(current, slot)) return;

    final selected = Set<String>.from(current.selectedSlots);
    if (!selected.remove(slot)) selected.add(slot);
    emit(current.copyWith(selectedSlots: selected, clearMessage: true));
  }

  bool _isUnavailable(BookingSlotsLoaded state, String slot) {
    if (state.bookedSlots.contains(slot)) return true;
    if (isPastSlot(state.date, slot)) return true;
    return false;
  }

  /// A slot on today's date whose start time has already gone by — not
  /// selectable (spec: "Không cho đặt slot trong quá khứ"). Exposed so the
  /// UI can grey it out the same way it greys out booked slots.
  bool isPastSlot(DateTime date, String slot) {
    final now = DateTime.now();
    if (!_isSameDay(date, now)) return false;
    final startHour = int.parse(slot.split(':')[0]);
    return startHour <= now.hour;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> confirmBooking() async {
    final current = state;
    if (current is! BookingSlotsLoaded || current.selectedSlots.isEmpty) return;

    emit(current.copyWith(submitting: true, clearMessage: true));

    final dateKey = formatDateKey(current.date);
    final failedSlots = <String>{};
    for (final slot in current.selectedSlots) {
      final result = await createBookingUseCase(
        CreateBookingParams(
          courtId: court.id,
          ownerId: court.ownerId,
          date: dateKey,
          timeSlot: slot,
          pricePerSlot: court.pricePerSlot,
        ),
      );
      result.fold((failure) => failedSlots.add(slot), (_) {});
    }

    final refreshed = await getBookedSlotsUseCase(
      GetBookedSlotsParams(courtId: court.id, date: dateKey),
    );

    refreshed.fold(
      (failure) => emit(BookingSlotsError(failure.message)),
      (booked) {
        if (failedSlots.isEmpty) {
          emit(
            current.copyWith(
              bookedSlots: booked.toSet(),
              selectedSlots: const {},
              submitting: false,
              success: true,
            ),
          );
        } else {
          emit(
            current.copyWith(
              bookedSlots: booked.toSet(),
              selectedSlots: current.selectedSlots.difference(failedSlots),
              submitting: false,
              message: 'Khung giờ vừa được đặt, vui lòng chọn khung giờ khác',
            ),
          );
        }
      },
    );
  }

  List<String> _generateSlots(String openTime, String closeTime) {
    final openHour = int.parse(openTime.split(':')[0]);
    final closeHour = int.parse(closeTime.split(':')[0]);
    final slots = <String>[];
    for (var h = openHour; h + _slotHours <= closeHour; h += _slotHours) {
      slots.add('${_pad(h)}:00-${_pad(h + _slotHours)}:00');
    }
    return slots;
  }

  String _pad(int h) => h.toString().padLeft(2, '0');
}

/// `yyyy-MM-dd`, matches how `BookingEntity.date`/`slotLocks` are keyed.
String formatDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
