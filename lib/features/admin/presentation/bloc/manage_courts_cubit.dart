import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../court/domain/entities/court_entity.dart';
import '../../domain/usecases/get_all_courts_usecase.dart';
import '../../domain/usecases/set_court_hidden_usecase.dart';

part 'manage_courts_state.dart';

/// TASK-034 — tab "Sân" trong "Quản lý Người dùng & Sân" (chỉ Admin). Lấy
/// TẤT CẢ sân (kể cả đã ẩn) — khác [GetVisibleCourtsUseCase] mà Home/Search
/// dùng, vì Admin cần thấy sân đã ẩn để có thể hiện lại.
class ManageCourtsCubit extends Cubit<ManageCourtsState> {
  final GetAllCourtsUseCase getAllCourtsUseCase;
  final SetCourtHiddenUseCase setCourtHiddenUseCase;

  ManageCourtsCubit({
    required this.getAllCourtsUseCase,
    required this.setCourtHiddenUseCase,
  }) : super(const ManageCourtsLoading());

  Future<void> load() async {
    emit(const ManageCourtsLoading());
    final result = await getAllCourtsUseCase(const NoParams());
    result.fold(
      (failure) => emit(ManageCourtsError(failure.message)),
      (courts) => emit(ManageCourtsLoaded(courts: courts)),
    );
  }

  /// Optimistic: đổi UI ngay, rollback nếu Firestore ghi lỗi.
  Future<void> toggleHidden(CourtEntity court) async {
    final current = state;
    if (current is! ManageCourtsLoaded) return;

    final updated = court.copyWith(isHidden: !court.isHidden);
    emit(
      current.copyWith(
        courts: _replace(current.courts, updated),
        busyCourtId: court.id,
        clearMessage: true,
      ),
    );

    final result = await setCourtHiddenUseCase(
      SetCourtHiddenParams(courtId: court.id, isHidden: updated.isHidden),
    );
    result.fold(
      (failure) => emit(
        (state as ManageCourtsLoaded).copyWith(
          courts: _replace(current.courts, court),
          clearBusy: true,
          message: failure.message,
        ),
      ),
      (_) => emit((state as ManageCourtsLoaded).copyWith(clearBusy: true)),
    );
  }

  List<CourtEntity> _replace(List<CourtEntity> courts, CourtEntity updated) {
    return courts.map((c) => c.id == updated.id ? updated : c).toList();
  }
}
