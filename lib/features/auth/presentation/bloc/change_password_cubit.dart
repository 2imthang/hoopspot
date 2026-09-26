import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/change_password_usecase.dart';

part 'change_password_state.dart';

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final ChangePasswordUseCase changePasswordUseCase;

  ChangePasswordCubit(this.changePasswordUseCase) : super(const ChangePasswordState());

  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(state.copyWith(submitting: true, clearError: true));
    final result = await changePasswordUseCase(
      ChangePasswordParams(currentPassword: currentPassword, newPassword: newPassword),
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(submitting: false, errorMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(submitting: false));
        return true;
      },
    );
  }
}
