import '../../../core/di/injection_container.dart';
import '../data/datasources/court_remote_datasource.dart';
import '../data/repositories/court_repository_impl.dart';
import '../domain/repositories/court_repository.dart';
import '../domain/usecases/create_court_usecase.dart';
import '../domain/usecases/delete_court_usecase.dart';
import '../domain/usecases/get_court_by_id_usecase.dart';
import '../domain/usecases/get_owner_courts_usecase.dart';
import '../domain/usecases/get_visible_courts_usecase.dart';
import '../domain/usecases/update_court_usecase.dart';

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
}
