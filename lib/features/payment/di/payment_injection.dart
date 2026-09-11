import '../../../core/di/injection_container.dart';
import '../../../core/network/dio_client.dart';
import '../../booking/domain/usecases/watch_bookings_status_usecase.dart';
import '../data/datasources/payment_remote_datasource.dart';
import '../data/repositories/payment_repository_impl.dart';
import '../domain/repositories/payment_repository.dart';
import '../domain/usecases/create_payment_url_usecase.dart';
import '../presentation/bloc/payment_cubit.dart';

void initPaymentDependencies() {
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(() => CreatePaymentUrlUseCase(sl()));

  sl.registerFactory(
    () => PaymentCubit(
      createPaymentUrlUseCase: sl(),
      watchBookingsStatusUseCase: sl<WatchBookingsStatusUseCase>(),
    ),
  );
}
