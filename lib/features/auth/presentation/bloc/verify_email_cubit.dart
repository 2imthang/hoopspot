import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/check_email_verified_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/send_email_verification_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';

part 'verify_email_state.dart';

class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  final CheckEmailVerifiedUseCase checkEmailVerifiedUseCase;
  final SendEmailVerificationUseCase sendEmailVerificationUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  VerifyEmailCubit({
    required this.checkEmailVerifiedUseCase,
    required this.sendEmailVerificationUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const VerifyEmailInitial());

  Future<void> checkVerified() async {
    emit(const VerifyEmailChecking());
    final result = await checkEmailVerifiedUseCase(const NoParams());
    await result.fold(
      (failure) async => emit(VerifyEmailFailure(failure.message)),
      (isVerified) async {
        if (!isVerified) {
          emit(const VerifyEmailNotYet());
          return;
        }
        final userResult = await getCurrentUserUseCase(const NoParams());
        userResult.fold(
          (failure) => emit(VerifyEmailFailure(failure.message)),
          (user) => emit(VerifyEmailVerified(user)),
        );
      },
    );
  }

  Future<void> resend() async {
    emit(const VerifyEmailChecking());
    final result = await sendEmailVerificationUseCase(const NoParams());
    result.fold(
      (failure) => emit(VerifyEmailFailure(failure.message)),
      (_) => emit(const VerifyEmailResent()),
    );
  }

  Future<void> signOut() async {
    await signOutUseCase(const NoParams());
    emit(const VerifyEmailSignedOut());
  }
}
