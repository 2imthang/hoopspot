import '../../../core/di/injection_container.dart';
import '../data/datasources/review_remote_datasource.dart';
import '../data/repositories/review_repository_impl.dart';
import '../domain/repositories/review_repository.dart';
import '../domain/usecases/create_review_usecase.dart';
import '../domain/usecases/get_court_reviews_usecase.dart';
import '../domain/usecases/get_my_reviewed_booking_ids_usecase.dart';

void initReviewDependencies() {
  sl.registerLazySingleton<ReviewRemoteDataSource>(
    () => ReviewRemoteDataSourceImpl(firestore: sl(), firebaseAuth: sl()),
  );
  sl.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(sl()));

  sl.registerLazySingleton(() => CreateReviewUseCase(sl()));
  sl.registerLazySingleton(() => GetCourtReviewsUseCase(sl()));
  sl.registerLazySingleton(() => GetMyReviewedBookingIdsUseCase(sl()));
}
