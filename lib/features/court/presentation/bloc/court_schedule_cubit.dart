import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/court_entity.dart';
import '../../domain/entities/day_schedule.dart';
import '../../domain/usecases/update_court_schedule_usecase.dart';

part 'court_schedule_state.dart';

/// TASK-031 — màn "Giờ hoạt động", khớp mockup `court schedule config.png`.
/// Sửa cục bộ trong state, chỉ ghi Firestore 1 lần khi bấm "Lưu thay đổi".
class CourtScheduleCubit extends Cubit<CourtScheduleState> {
  final String courtId;
  final UpdateCourtScheduleUseCase updateCourtScheduleUseCase;

  CourtScheduleCubit({
    required this.courtId,
    required this.updateCourtScheduleUseCase,
    required Map<Weekday, DaySchedule> initialSchedule,
  }) : super(CourtScheduleState(schedule: initialSchedule));

  void toggleDay(Weekday day) {
    final current = state.schedule[day]!;
    _updateDay(day, current.copyWith(isOpen: !current.isOpen));
  }

  void setOpenTime(Weekday day, String time) {
    _updateDay(day, state.schedule[day]!.copyWith(openTime: time));
  }

  void setCloseTime(Weekday day, String time) {
    _updateDay(day, state.schedule[day]!.copyWith(closeTime: time));
  }

  void _updateDay(Weekday day, DaySchedule updated) {
    emit(
      state.copyWith(
        schedule: {...state.schedule, day: updated},
        clearError: true,
      ),
    );
  }

  /// `true` khi lưu thành công — trang gọi nên `Navigator.pop(context, true)`.
  Future<bool> save() async {
    emit(state.copyWith(saving: true, clearError: true));
    final result = await updateCourtScheduleUseCase(
      UpdateCourtScheduleParams(courtId: courtId, weeklySchedule: state.schedule),
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(saving: false, errorMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(saving: false));
        return true;
      },
    );
  }
}
