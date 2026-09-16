import '../../../core/di/injection_container.dart';
import '../../../core/network/dio_client.dart';
import '../../court/domain/entities/court_entity.dart';
import '../../court/domain/usecases/get_court_by_id_usecase.dart';
import '../../review/domain/usecases/get_my_reviewed_booking_ids_usecase.dart';
import '../data/datasources/booking_refund_remote_datasource.dart';
import '../data/datasources/booking_remote_datasource.dart';
import '../data/repositories/booking_repository_impl.dart';
import '../domain/repositories/booking_repository.dart';
import '../domain/usecases/cancel_booking_usecase.dart';
import '../domain/usecases/create_booking_usecase.dart';
import '../domain/usecases/get_booked_slots_usecase.dart';
import '../domain/usecases/get_owner_court_bookings_usecase.dart';
import '../domain/usecases/rain_cancel_booking_usecase.dart';
import '../domain/usecases/watch_bookings_status_usecase.dart';
import '../domain/usecases/watch_my_bookings_usecase.dart';
import '../domain/usecases/watch_owner_bookings_usecase.dart';
import '../presentation/bloc/booking_history_cubit.dart';
import '../presentation/bloc/booking_slots_cubit.dart';
import '../presentation/bloc/owner_bookings_cubit.dart';

void initBookingDependencies() {
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(firestore: sl(), firebaseAuth: sl()),
  );
  sl.registerLazySingleton<BookingRefundRemoteDataSource>(
    () => BookingRefundRemoteDataSourceImpl(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(sl(), sl()),
  );

  sl.registerLazySingleton(() => CreateBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetBookedSlotsUseCase(sl()));
  sl.registerLazySingleton(() => WatchBookingsStatusUseCase(sl()));
  sl.registerLazySingleton(() => WatchMyBookingsUseCase(sl()));
  sl.registerLazySingleton(() => CancelBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetOwnerCourtBookingsUseCase(sl()));
  sl.registerLazySingleton(() => WatchOwnerBookingsUseCase(sl()));
  sl.registerLazySingleton(() => RainCancelBookingUseCase(sl()));

  sl.registerFactoryParam<BookingSlotsCubit, CourtEntity, void>(
    (court, _) => BookingSlotsCubit(
      court: court,
      getBookedSlotsUseCase: sl(),
      createBookingUseCase: sl(),
    ),
  );

  sl.registerFactoryParam<BookingHistoryCubit, String, void>(
    (userId, _) => BookingHistoryCubit(
      userId: userId,
      watchMyBookingsUseCase: sl(),
      getCourtByIdUseCase: sl<GetCourtByIdUseCase>(),
      cancelBookingUseCase: sl(),
      getMyReviewedBookingIdsUseCase: sl<GetMyReviewedBookingIdsUseCase>(),
    ),
  );

  sl.registerFactoryParam<OwnerBookingsCubit, String, void>(
    (ownerId, _) => OwnerBookingsCubit(
      ownerId: ownerId,
      watchOwnerBookingsUseCase: sl(),
      getCourtByIdUseCase: sl<GetCourtByIdUseCase>(),
      rainCancelBookingUseCase: sl(),
    ),
  );
}
