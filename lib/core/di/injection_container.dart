import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../features/admin/di/admin_injection.dart';
import '../../features/auth/di/auth_injection.dart';
import '../../features/booking/di/booking_injection.dart';
import '../../features/court/di/court_injection.dart';
import '../../features/favorite/di/favorite_injection.dart';
import '../../features/home/di/home_injection.dart';
import '../../features/notification/di/notification_injection.dart';
import '../../features/payment/di/payment_injection.dart';
import '../../features/review/di/review_injection.dart';
import '../network/dio_client.dart';
import '../services/geocoding_service.dart';
import '../services/image_upload_service.dart';
import '../services/location_service.dart';

final GetIt sl = GetIt.instance;

/// Registers cross-cutting singletons. Each feature registers its own
/// datasources/repositories/usecases/blocs from its own `di` entry point,
/// called from here once that feature exists.
Future<void> initDependencies() async {
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<ImageUploadService>(
    () => CloudinaryImageUploadService(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<GeocodingService>(
    () => NominatimGeocodingService(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<LocationService>(
    () => DeviceLocationService(sl<GeocodingService>()),
  );

  initAuthDependencies();
  initAdminDependencies();
  initCourtDependencies();
  initFavoriteDependencies();
  initReviewDependencies();
  initHomeDependencies();
  initBookingDependencies();
  initPaymentDependencies();
  initNotificationDependencies();
}
