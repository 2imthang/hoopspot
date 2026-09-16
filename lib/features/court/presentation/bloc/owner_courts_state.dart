part of 'owner_courts_cubit.dart';

abstract class OwnerCourtsState extends Equatable {
  const OwnerCourtsState();

  @override
  List<Object?> get props => [];
}

class OwnerCourtsLoading extends OwnerCourtsState {
  const OwnerCourtsLoading();
}

class OwnerCourtsError extends OwnerCourtsState {
  final String message;

  const OwnerCourtsError(this.message);

  @override
  List<Object?> get props => [message];
}

class OwnerCourtsLoaded extends OwnerCourtsState {
  final List<CourtEntity> courts;

  /// ID sân đang xóa/toggle, để khóa đúng dòng đang thao tác thay vì khóa
  /// toàn màn hình.
  final String? busyCourtId;

  /// Lỗi tạm thời (VD chặn xóa vì còn booking đã xác nhận) — hiện snackbar.
  final String? message;

  const OwnerCourtsLoaded({
    required this.courts,
    this.busyCourtId,
    this.message,
  });

  OwnerCourtsLoaded copyWith({
    List<CourtEntity>? courts,
    String? busyCourtId,
    String? message,
    bool clearMessage = false,
  }) {
    return OwnerCourtsLoaded(
      courts: courts ?? this.courts,
      busyCourtId: busyCourtId,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [courts, busyCourtId];
}
