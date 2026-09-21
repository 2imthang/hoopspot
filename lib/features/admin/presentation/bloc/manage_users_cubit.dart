import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/get_manageable_users_usecase.dart';
import '../../domain/usecases/set_user_locked_usecase.dart';

part 'manage_users_state.dart';

/// TASK-034 — tab "Người dùng" trong "Quản lý Người dùng & Sân" (chỉ
/// Admin). Chỉ liệt kê tài khoản đã ở trạng thái ổn định (`active`/
/// `locked`) — Owner đang chờ duyệt/bị từ chối đã có màn riêng ở
/// [OwnerApprovalCubit] (TASK-033), tránh 2 màn dẫm chân nhau.
class ManageUsersCubit extends Cubit<ManageUsersState> {
  final GetManageableUsersUseCase getManageableUsersUseCase;
  final SetUserLockedUseCase setUserLockedUseCase;

  ManageUsersCubit({
    required this.getManageableUsersUseCase,
    required this.setUserLockedUseCase,
  }) : super(const ManageUsersLoading());

  Future<void> load() async {
    emit(const ManageUsersLoading());
    final result = await getManageableUsersUseCase(const NoParams());
    result.fold(
      (failure) => emit(ManageUsersError(failure.message)),
      (users) => emit(ManageUsersLoaded(users: users)),
    );
  }

  /// Optimistic: đổi UI ngay, rollback nếu Firestore ghi lỗi.
  Future<void> toggleLock(UserEntity user) async {
    final current = state;
    if (current is! ManageUsersLoaded) return;

    final wasLocked = user.status == UserStatus.locked;
    final locked = !wasLocked;
    emit(
      current.copyWith(
        users: _replaceStatus(current.users, user.uid, locked),
        busyUid: user.uid,
        clearMessage: true,
      ),
    );

    final result = await setUserLockedUseCase(
      SetUserLockedParams(uid: user.uid, locked: locked),
    );
    result.fold(
      (failure) => emit(
        (state as ManageUsersLoaded).copyWith(
          users: _replaceStatus(current.users, user.uid, wasLocked),
          clearBusy: true,
          message: failure.message,
        ),
      ),
      (_) => emit((state as ManageUsersLoaded).copyWith(clearBusy: true)),
    );
  }

  List<UserEntity> _replaceStatus(List<UserEntity> users, String uid, bool locked) {
    return users
        .map(
          (u) => u.uid == uid
              ? u.copyWith(status: locked ? UserStatus.locked : UserStatus.active)
              : u,
        )
        .toList();
  }
}
