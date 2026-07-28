import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/google_auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/check_email_verified_usecase.dart';
import '../../domain/usecases/google_sign_in_usecase.dart';
import '../../domain/usecases/login_usecase.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase loginUseCase;
  final GoogleSignInUseCase googleSignInUseCase;
  final CheckEmailVerifiedUseCase checkEmailVerifiedUseCase;

  LoginCubit({
    required this.loginUseCase,
    required this.googleSignInUseCase,
    required this.checkEmailVerifiedUseCase,
  }) : super(const LoginInitial());

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const LoginLoading());
    final result = await loginUseCase(
      LoginParams(email: email, password: password),
    );
    await result.fold((failure) async => emit(LoginFailure(failure.message)), (
      user,
    ) async {
      final verified = await checkEmailVerifiedUseCase(const NoParams());
      verified.fold(
        (failure) => emit(LoginFailure(failure.message)),
        (isVerified) => emit(
          isVerified ? LoginSuccess(user) : LoginNeedsVerification(user.email),
        ),
      );
    });
  }

  Future<void> loginWithGoogle() async {
    emit(const LoginLoading());
    final result = await googleSignInUseCase(const NoParams());
    result.fold((failure) => emit(LoginFailure(failure.message)), (
      googleResult,
    ) {
      if (googleResult.needsRoleSelection) {
        emit(LoginNeedsGoogleRoleSelection(googleResult.pendingProfile!));
      } else {
        emit(LoginSuccess(googleResult.user!));
      }
    });
  }
}
