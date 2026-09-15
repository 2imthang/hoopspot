import '../../../core/di/injection_container.dart';
import '../../../core/services/notification_service.dart';
import '../services/booking_reminder_scheduler.dart';

void initNotificationDependencies() {
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(
    () => BookingReminderScheduler(
      watchMyBookingsUseCase: sl(),
      getCourtByIdUseCase: sl(),
      notificationService: sl(),
    ),
  );
}
