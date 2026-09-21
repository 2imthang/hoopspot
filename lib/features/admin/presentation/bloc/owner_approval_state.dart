part of 'owner_approval_cubit.dart';

abstract class OwnerApprovalState extends Equatable {
  const OwnerApprovalState();

  @override
  List<Object?> get props => [];
}

class OwnerApprovalLoading extends OwnerApprovalState {
  const OwnerApprovalLoading();
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
