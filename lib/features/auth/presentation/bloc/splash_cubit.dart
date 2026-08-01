import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/check_email_verified_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';

part 'splash_state.dart';

/// Floor on how long the Splash branding stays visible — the session check
/// itself is often near-instant, which would otherwise flash the logo by
/// too fast to read.
const _minSplashDuration = Duration(milliseconds: 1200);

class SplashCubit extends Cubit<SplashState> {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final CheckEmailVerifiedUseCase checkEmailVerifiedUseCase;
  final SignOutUseCase signOutUseCase;

  SplashCubit({
    required this.getCurrentUserUseCase,
    required this.checkEmailVerifiedUseCase,
    required this.signOutUseCase,
  }) : super(const SplashChecking());

  Future<void> checkSession() async {
    final minDelay = Future<void>.delayed(_minSplashDuration);
    final userResult = await getCurrentUserUseCase(const NoParams());

    final nextState = await userResult.fold<Future<SplashState>>(
      (failure) async {
        // No signed-in user, or a signed-in Auth user with no Firestore doc
        // (e.g. an orphaned account) — either way, land on Login with a
        // clean slate instead of a half-signed-in session.
        await signOutUseCase(const NoParams());
        return const SplashGoLogin();
      },
      (user) async {
        final verifiedResult = await checkEmailVerifiedUseCase(
          const NoParams(),
        );
        return verifiedResult.fold(
          (failure) => const SplashGoLogin(),
          (isVerified) =>
              isVerified ? SplashGoUser(user) : SplashGoVerify(user.email),
        );
      },
    );

    await minDelay;
    emit(nextState);
  }
}
