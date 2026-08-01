part of 'account_status_cubit.dart';

abstract class AccountStatusState extends Equatable {
  const AccountStatusState();

  @override
  List<Object?> get props => [];
}

class AccountStatusInitial extends AccountStatusState {
  const AccountStatusInitial();
}

class AccountStatusLoading extends AccountStatusState {
  const AccountStatusLoading();
}

class AccountStatusResubmitted extends AccountStatusState {
  final UserEntity user;

  const AccountStatusResubmitted(this.user);

  @override
  List<Object?> get props => [user];
}

class AccountStatusFailure extends AccountStatusState {
  final String message;

  const AccountStatusFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AccountStatusSignedOut extends AccountStatusState {
  const AccountStatusSignedOut();
}
