part of 'complete_profile_cubit.dart';

abstract class CompleteProfileState extends Equatable {
  const CompleteProfileState();

  @override
  List<Object?> get props => [];
}

class CompleteProfileInitial extends CompleteProfileState {
  const CompleteProfileInitial();
}

class CompleteProfileLoading extends CompleteProfileState {
  const CompleteProfileLoading();
}

class CompleteProfileSuccess extends CompleteProfileState {
  final UserEntity user;

  const CompleteProfileSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class CompleteProfileFailure extends CompleteProfileState {
  final String message;

  const CompleteProfileFailure(this.message);

  @override
  List<Object?> get props => [message];
}
