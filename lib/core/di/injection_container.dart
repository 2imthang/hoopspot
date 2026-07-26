import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/di/auth_injection.dart';
import '../network/dio_client.dart';

final GetIt sl = GetIt.instance;

/// Registers cross-cutting singletons. Each feature registers its own
/// datasources/repositories/usecases/blocs from its own `di` entry point,
/// called from here once that feature exists.
Future<void> initDependencies() async {
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  initAuthDependencies();
}
