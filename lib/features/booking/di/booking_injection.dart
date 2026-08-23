import '../../../core/di/injection_container.dart';
import '../../court/domain/entities/court_entity.dart';
import '../data/datasources/booking_remote_datasource.dart';
import '../data/repositories/booking_repository_impl.dart';
import '../domain/repositories/booking_repository.dart';
import '../domain/usecases/create_booking_usecase.dart';
import '../domain/usecases/get_booked_slots_usecase.dart';
import '../presentation/bloc/booking_slots_cubit.dart';

void initBookingDependencies() {
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(firestore: sl(), firebaseAuth: sl()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(() => CreateBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetBookedSlotsUseCase(sl()));

  sl.registerFactoryParam<BookingSlotsCubit, CourtEntity, void>(
    (court, _) => BookingSlotsCubit(
      court: court,
      getBookedSlotsUseCase: sl(),
      createBookingUseCase: sl(),
    ),
  );
}
