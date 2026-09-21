part of 'owner_approval_cubit.dart';

abstract class OwnerApprovalState extends Equatable {
  const OwnerApprovalState();

  @override
  List<Object?> get props => [];
}

class OwnerApprovalLoading extends OwnerApprovalState {
  const OwnerApprovalLoading();
}

/// TASK-036 — bắt lỗi stream qua `onError` (xem [OwnerApprovalCubit]), tránh
/// kẹt ở [OwnerApprovalLoading] mãi mãi khi mất mạng/mất quyền.
class OwnerApprovalError extends OwnerApprovalState {
  final String message;

  const OwnerApprovalError(this.message);

  @override
  List<Object?> get props => [message];
}

class OwnerApprovalLoaded extends OwnerApprovalState {
  final List<UserEntity> owners;
  final String? busyUid;
  final String? message;

  const OwnerApprovalLoaded({
    required this.owners,
    this.busyUid,
    this.message,
  });

  OwnerApprovalLoaded copyWith({
    List<UserEntity>? owners,
    String? busyUid,
    bool clearBusy = false,
    String? message,
    bool clearMessage = false,
  }) {
    return OwnerApprovalLoaded(
      owners: owners ?? this.owners,
      busyUid: clearBusy ? null : (busyUid ?? this.busyUid),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [owners, busyUid, message];
}
