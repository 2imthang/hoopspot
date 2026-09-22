import '../../../core/di/injection_container.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/image_upload_service.dart';
import '../../booking/domain/usecases/get_owner_court_bookings_usecase.dart';
import '../../review/domain/usecases/get_court_reviews_usecase.dart';
import '../data/datasources/court_remote_datasource.dart';
import '../data/repositories/court_repository_impl.dart';
import '../domain/entities/day_schedule.dart';
import '../domain/entities/court_entity.dart' show Weekday;
import '../domain/repositories/court_repository.dart';
import '../domain/usecases/create_court_usecase.dart';
import '../domain/usecases/delete_court_usecase.dart';
import '../domain/usecases/get_court_by_id_usecase.dart';
import '../domain/usecases/get_owner_courts_usecase.dart';
import '../domain/usecases/get_visible_courts_usecase.dart';
import '../domain/usecases/update_court_schedule_usecase.dart';
import '../domain/usecases/update_court_usecase.dart';
import '../presentation/bloc/court_detail_cubit.dart';
import '../presentation/bloc/court_form_cubit.dart';
import '../presentation/bloc/court_schedule_cubit.dart';
import '../presentation/bloc/owner_courts_cubit.dart';

void initCourtDependencies() {
  sl.registerLazySingleton<CourtRemoteDataSource>(
    () => CourtRemoteDataSourceImpl(firestore: sl(), firebaseAuth: sl()),
  );
  sl.registerLazySingleton<CourtRepository>(() => CourtRepositoryImpl(sl()));

  sl.registerLazySingleton(() => CreateCourtUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCourtUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCourtUseCase(sl()));
  sl.registerLazySingleton(() => GetOwnerCourtsUseCase(sl()));
  sl.registerLazySingleton(() => GetCourtByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetVisibleCourtsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCourtScheduleUseCase(sl()));

  sl.registerFactory(
    () => CourtDetailCubit(
      getCourtByIdUseCase: sl(),
      getCourtReviewsUseCase: sl<GetCourtReviewsUseCase>(),
    ),
  );

  sl.registerFactory(
    () => OwnerCourtsCubit(
      getOwnerCourtsUseCase: sl(),
      updateCourtUseCase: sl(),
      deleteCourtUseCase: sl(),
      getOwnerCourtBookingsUseCase: sl<GetOwnerCourtBookingsUseCase>(),
    ),
  );

  sl.registerFactoryParam<CourtFormCubit, List<String>, void>(
    (initialImageUrls, _) => CourtFormCubit(
      createCourtUseCase: sl(),
      updateCourtUseCase: sl(),
      imageUploadService: sl<ImageUploadService>(),
      geocodingService: sl<GeocodingService>(),
      initialImageUrls: initialImageUrls,
    ),
  );

  sl.registerFactoryParam<CourtScheduleCubit, String, Map<Weekday, DaySchedule>>(
    (courtId, initialSchedule) => CourtScheduleCubit(
      courtId: courtId,
      updateCourtScheduleUseCase: sl(),
      initialSchedule: initialSchedule,
    ),
  );
}
