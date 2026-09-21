import '../../../core/di/injection_container.dart';
import '../domain/usecases/approve_owner_usecase.dart';
import '../domain/usecases/reject_owner_usecase.dart';
import '../domain/usecases/watch_pending_owners_usecase.dart';
import '../presentation/bloc/owner_approval_cubit.dart';

/// Dùng lại [AuthRepository] (đã đăng ký ở [initAuthDependencies]) cho mọi
/// thao tác trên collection `users` — Admin chỉ là một góc nhìn/khả năng
/// khác trên cùng dữ liệu đó, không cần datasource/repository riêng.
void initAdminDependencies() {
  sl.registerLazySingleton(() => WatchPendingOwnersUseCase(sl()));
  sl.registerLazySingleton(() => ApproveOwnerUseCase(sl()));
  sl.registerLazySingleton(() => RejectOwnerUseCase(sl()));

  sl.registerFactory(
    () => OwnerApprovalCubit(
      watchPendingOwnersUseCase: sl(),
      approveOwnerUseCase: sl(),
      rejectOwnerUseCase: sl(),
    ),
  );
}
