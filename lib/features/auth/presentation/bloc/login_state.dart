part of 'login_cubit.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  final UserEntity user;

  const LoginSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class LoginNeedsVerification extends LoginState {
  final String email;

  const LoginNeedsVerification(this.email);

  @override
  List<Object?> get props => [email];
}

class LoginNeedsGoogleRoleSelection extends LoginState {
  final PendingGoogleProfile profile;

  const LoginNeedsGoogleRoleSelection(this.profile);

  @override
  List<Object?> get props => [profile];
}

class LoginFailure extends LoginState {
  final String message;

  const LoginFailure(this.message);

  @override
  List<Object?> get props => [message];
}
