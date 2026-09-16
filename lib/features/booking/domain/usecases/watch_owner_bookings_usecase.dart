import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

/// Không implement [UseCase] (Future-based) — đây là stream, giống
/// [WatchMyBookingsUseCase].
class WatchOwnerBookingsUseCase {
  final BookingRepository repository;

  const WatchOwnerBookingsUseCase(this.repository);

  Stream<List<BookingEntity>> call(String ownerId) {
    return repository.watchOwnerBookings(ownerId);
  }
}
