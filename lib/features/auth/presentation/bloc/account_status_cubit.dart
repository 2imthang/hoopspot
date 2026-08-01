import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/resubmit_owner_application_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';

part 'account_status_state.dart';

class AccountStatusCubit extends Cubit<AccountStatusState> {
  final ResubmitOwnerApplicationUseCase resubmitOwnerApplicationUseCase;
  final SignOutUseCase signOutUseCase;

  AccountStatusCubit({
    required this.resubmitOwnerApplicationUseCase,
    required this.signOutUseCase,
  }) : super(const AccountStatusInitial());

  Future<void> resubmit() async {
    emit(const AccountStatusLoading());
    final result = await resubmitOwnerApplicationUseCase(const NoParams());
    result.fold(
      (failure) => emit(AccountStatusFailure(failure.message)),
      (user) => emit(AccountStatusResubmitted(user)),
    );
  }

  Future<void> signOut() async {
    await signOutUseCase(const NoParams());
    emit(const AccountStatusSignedOut());
  }
}
