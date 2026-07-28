import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/complete_google_signup_usecase.dart';

part 'complete_profile_state.dart';

class CompleteProfileCubit extends Cubit<CompleteProfileState> {
  final CompleteGoogleSignUpUseCase completeGoogleSignUpUseCase;

  CompleteProfileCubit(this.completeGoogleSignUpUseCase)
    : super(const CompleteProfileInitial());

  Future<void> submit({
    required String uid,
    required String email,
    required String displayName,
    String? avatarUrl,
    required String phone,
    required UserRole role,
  }) async {
    emit(const CompleteProfileLoading());
    final result = await completeGoogleSignUpUseCase(
      CompleteGoogleSignUpParams(
        uid: uid,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
        phone: phone,
        role: role,
      ),
    );
    result.fold(
      (failure) => emit(CompleteProfileFailure(failure.message)),
      (user) => emit(CompleteProfileSuccess(user)),
    );
  }
}
