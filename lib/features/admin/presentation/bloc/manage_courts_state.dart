part of 'manage_courts_cubit.dart';

abstract class ManageCourtsState extends Equatable {
  const ManageCourtsState();

  @override
  List<Object?> get props => [];
}

class ManageCourtsLoading extends ManageCourtsState {
  const ManageCourtsLoading();
}

class ManageCourtsError extends ManageCourtsState {
  final String message;

  const ManageCourtsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ManageCourtsLoaded extends ManageCourtsState {
  final List<CourtEntity> courts;
  final String? busyCourtId;
  final String? message;

  const ManageCourtsLoaded({required this.courts, this.busyCourtId, this.message});

  ManageCourtsLoaded copyWith({
    List<CourtEntity>? courts,
    String? busyCourtId,
    bool clearBusy = false,
    String? message,
    bool clearMessage = false,
  }) {
    return ManageCourtsLoaded(
      courts: courts ?? this.courts,
      busyCourtId: clearBusy ? null : (busyCourtId ?? this.busyCourtId),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [courts, busyCourtId, message];
}
