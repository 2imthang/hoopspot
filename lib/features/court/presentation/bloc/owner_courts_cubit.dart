import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/vn_time.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../booking/domain/usecases/get_owner_court_bookings_usecase.dart';
import '../../domain/entities/court_entity.dart';
import '../../domain/usecases/delete_court_usecase.dart';
import '../../domain/usecases/get_owner_courts_usecase.dart';
import '../../domain/usecases/update_court_usecase.dart';

part 'owner_courts_state.dart';

/// TASK-031 — tab "Sân của tôi" (chỉ Owner thấy). Sửa/xóa/toggle "ngoài
/// trời" thao tác trực tiếp trên sân, không cần mở form đầy đủ.
class OwnerCourtsCubit extends Cubit<OwnerCourtsState> {
  final GetOwnerCourtsUseCase getOwnerCourtsUseCase;
  final UpdateCourtUseCase updateCourtUseCase;
  final DeleteCourtUseCase deleteCourtUseCase;
  final GetOwnerCourtBookingsUseCase getOwnerCourtBookingsUseCase;

  OwnerCourtsCubit({
    required this.getOwnerCourtsUseCase,
    required this.updateCourtUseCase,
    required this.deleteCourtUseCase,
    required this.getOwnerCourtBookingsUseCase,
  }) : super(const OwnerCourtsLoading());

  Future<void> load() async {
    emit(const OwnerCourtsLoading());
    final result = await getOwnerCourtsUseCase(const NoParams());
    result.fold(
      (failure) => emit(OwnerCourtsError(failure.message)),
      (courts) => emit(OwnerCourtsLoaded(courts: courts)),
    );
  }

  /// Optimistic: đổi UI ngay, rollback nếu Firestore ghi lỗi.
  Future<void> toggleOutdoor(CourtEntity court) async {
    final current = state;
    if (current is! OwnerCourtsLoaded) return;

    final updated = court.copyWith(isOutdoor: !court.isOutdoor);
    emit(current.copyWith(courts: _replace(current.courts, updated)));

    final result = await updateCourtUseCase(
      UpdateCourtParams(
        courtId: court.id,
        name: court.name,
        address: court.address,
        latitude: court.latitude,
        longitude: court.longitude,
        imageUrls: court.imageUrls,
        pricePerSlot: court.pricePerSlot,
        amenities: court.amenities,
        isOutdoor: !court.isOutdoor,
      ),
    );
    result.fold(
      (failure) => emit(
        (state as OwnerCourtsLoaded).copyWith(
          courts: _replace(current.courts, court),
          message: failure.message,
        ),
      ),
      (_) {},
    );
  }

  Future<void> deleteCourt(CourtEntity court) async {
    final current = state;
    if (current is! OwnerCourtsLoaded) return;

    emit(current.copyWith(busyCourtId: court.id, clearMessage: true));

    final bookingsResult = await getOwnerCourtBookingsUseCase(court.id);
    final blocked = bookingsResult.fold(
      (_) => false,
      (bookings) => bookings.any(_isActiveFutureBooking),
    );
    if (blocked) {
      emit(
        (state as OwnerCourtsLoaded).copyWith(
          busyCourtId: null,
          message: 'Không thể xóa sân đang có booking đã xác nhận, xử lý các booking đó trước',
        ),
      );
      return;
    }

    final result = await deleteCourtUseCase(DeleteCourtParams(court.id));
    result.fold(
      (failure) => emit(
        (state as OwnerCourtsLoaded).copyWith(busyCourtId: null, message: failure.message),
      ),
      (_) => emit(
        OwnerCourtsLoaded(
          courts: current.courts.where((c) => c.id != court.id).toList(),
        ),
      ),
    );
  }

  bool _isActiveFutureBooking(BookingEntity booking) {
    if (booking.status != BookingStatus.confirmed) return false;
    final end = parseSlotEndUtc(booking.date, booking.timeSlot);
    return end.isAfter(DateTime.now().toUtc());
  }

  List<CourtEntity> _replace(List<CourtEntity> courts, CourtEntity updated) {
    return courts.map((c) => c.id == updated.id ? updated : c).toList();
  }
}
