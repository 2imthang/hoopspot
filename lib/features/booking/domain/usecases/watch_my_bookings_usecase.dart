import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

/// Không implement [UseCase] (Future-based) — đây là stream, giống
/// [WatchBookingsStatusUseCase].
class WatchMyBookingsUseCase {
  final BookingRepository repository;

  const WatchMyBookingsUseCase(this.repository);

  Stream<List<BookingEntity>> call(String userId) {
    return repository.watchMyBookings(userId);
  }
}
