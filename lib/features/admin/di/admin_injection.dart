import '../../../core/di/injection_container.dart';
import '../../court/domain/usecases/get_court_by_id_usecase.dart';
import '../domain/usecases/approve_owner_usecase.dart';
import '../domain/usecases/get_all_courts_usecase.dart';
import '../domain/usecases/get_all_transactions_usecase.dart';
import '../domain/usecases/get_manageable_users_usecase.dart';
import '../domain/usecases/reject_owner_usecase.dart';
import '../domain/usecases/set_court_hidden_usecase.dart';
import '../domain/usecases/set_user_locked_usecase.dart';
import '../domain/usecases/watch_pending_owners_usecase.dart';
import '../presentation/bloc/manage_courts_cubit.dart';
import '../presentation/bloc/manage_users_cubit.dart';
import '../presentation/bloc/owner_approval_cubit.dart';
import '../presentation/bloc/transactions_cubit.dart';

/// Dùng lại [AuthRepository]/[CourtRepository]/[BookingRepository] (đã
/// đăng ký ở [initAuthDependencies]/[initCourtDependencies]/
/// [initBookingDependencies]) cho mọi thao tác trên `users`/`courts`/
/// `bookings` — Admin chỉ là một góc nhìn/khả năng khác trên cùng dữ liệu
/// đó, không cần datasource/repository riêng.
void initAdminDependencies() {
  sl.registerLazySingleton(() => WatchPendingOwnersUseCase(sl()));
  sl.registerLazySingleton(() => ApproveOwnerUseCase(sl()));
  sl.registerLazySingleton(() => RejectOwnerUseCase(sl()));
  sl.registerLazySingleton(() => GetManageableUsersUseCase(sl()));
  sl.registerLazySingleton(() => SetUserLockedUseCase(sl()));
  sl.registerLazySingleton(() => GetAllCourtsUseCase(sl()));
  sl.registerLazySingleton(() => SetCourtHiddenUseCase(sl()));
  sl.registerLazySingleton(() => GetAllTransactionsUseCase(sl()));

  sl.registerFactory(
    () => OwnerApprovalCubit(
      watchPendingOwnersUseCase: sl(),
      approveOwnerUseCase: sl(),
      rejectOwnerUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => ManageUsersCubit(
      getManageableUsersUseCase: sl(),
      setUserLockedUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => ManageCourtsCubit(
      getAllCourtsUseCase: sl(),
      setCourtHiddenUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => TransactionsCubit(
      getAllTransactionsUseCase: sl(),
      getCourtByIdUseCase: sl<GetCourtByIdUseCase>(),
    ),
  );
}
