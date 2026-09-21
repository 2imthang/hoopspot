part of 'manage_users_cubit.dart';

abstract class ManageUsersState extends Equatable {
  const ManageUsersState();

  @override
  List<Object?> get props => [];
}

class ManageUsersLoading extends ManageUsersState {
  const ManageUsersLoading();
}

class ManageUsersError extends ManageUsersState {
  final String message;

  const ManageUsersError(this.message);

  @override
  List<Object?> get props => [message];
}

class ManageUsersLoaded extends ManageUsersState {
  final List<UserEntity> users;
  final String? busyUid;
  final String? message;

  const ManageUsersLoaded({required this.users, this.busyUid, this.message});

  ManageUsersLoaded copyWith({
    List<UserEntity>? users,
    String? busyUid,
    bool clearBusy = false,
    String? message,
    bool clearMessage = false,
  }) {
    return ManageUsersLoaded(
      users: users ?? this.users,
      busyUid: clearBusy ? null : (busyUid ?? this.busyUid),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [users, busyUid, message];
}
