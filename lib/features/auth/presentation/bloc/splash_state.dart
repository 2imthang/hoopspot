part of 'splash_cubit.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashChecking extends SplashState {
  const SplashChecking();
}

class SplashGoLogin extends SplashState {
  const SplashGoLogin();
}

class SplashGoVerify extends SplashState {
  final String email;

  const SplashGoVerify(this.email);

  @override
  List<Object?> get props => [email];
}

class SplashGoUser extends SplashState {
  final UserEntity user;

  const SplashGoUser(this.user);

  @override
  List<Object?> get props => [user];
}
