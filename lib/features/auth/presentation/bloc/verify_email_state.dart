part of 'verify_email_cubit.dart';

abstract class VerifyEmailState extends Equatable {
  const VerifyEmailState();

  @override
  List<Object?> get props => [];
}

class VerifyEmailInitial extends VerifyEmailState {
  const VerifyEmailInitial();
}

class VerifyEmailChecking extends VerifyEmailState {
  const VerifyEmailChecking();
}

class VerifyEmailVerified extends VerifyEmailState {
  final UserEntity user;

  const VerifyEmailVerified(this.user);

  @override
  List<Object?> get props => [user];
}

class VerifyEmailNotYet extends VerifyEmailState {
  const VerifyEmailNotYet();
}

class VerifyEmailResent extends VerifyEmailState {
  const VerifyEmailResent();
}

class VerifyEmailSignedOut extends VerifyEmailState {
  const VerifyEmailSignedOut();
}

class VerifyEmailFailure extends VerifyEmailState {
  final String message;

  const VerifyEmailFailure(this.message);

  @override
  List<Object?> get props => [message];
}
