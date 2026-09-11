import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

/// Không implement [UseCase] (Future-based) — đây là stream nên không có
/// khái niệm "1 lần gọi trả về Either", cứ để Firestore tự báo lỗi qua
/// stream nếu có, UI xử lý qua `StreamBuilder`/`BlocBuilder` như bình thường.
class WatchBookingsStatusUseCase {
  final BookingRepository repository;

  const WatchBookingsStatusUseCase(this.repository);

  Stream<List<BookingEntity>> call(List<String> bookingIds) {
    return repository.watchBookingsStatus(bookingIds);
  }
}
