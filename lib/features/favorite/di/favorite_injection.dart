import '../../../core/di/injection_container.dart';
import '../data/datasources/favorite_remote_datasource.dart';
import '../data/repositories/favorite_repository_impl.dart';
import '../domain/repositories/favorite_repository.dart';
import '../domain/usecases/get_favorite_court_ids_usecase.dart';
import '../domain/usecases/toggle_favorite_usecase.dart';
import '../presentation/bloc/favorite_cubit.dart';

void initFavoriteDependencies() {
  sl.registerLazySingleton<FavoriteRemoteDataSource>(
    () => FavoriteRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<FavoriteRepository>(() => FavoriteRepositoryImpl(sl()));

  sl.registerLazySingleton(() => GetFavoriteCourtIdsUseCase(sl()));
  sl.registerLazySingleton(() => ToggleFavoriteUseCase(sl()));

  // Singleton (không phải factory theo trang) — xem giải thích trong
  // [FavoriteCubit] vì sao phải cung cấp ở gốc app thay vì bọc quanh
  // HomePage.
  sl.registerLazySingleton(
    () => FavoriteCubit(
      getFavoriteCourtIdsUseCase: sl(),
      toggleFavoriteUseCase: sl(),
    ),
  );
}
