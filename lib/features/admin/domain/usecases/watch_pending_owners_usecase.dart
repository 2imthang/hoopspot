import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

/// Không implement [UseCase] (Future-based) — đây là stream, giống
/// [WatchMyBookingsUseCase] bên feature booking.
class WatchPendingOwnersUseCase {
  final AuthRepository repository;

  const WatchPendingOwnersUseCase(this.repository);

  Stream<List<UserEntity>> call() {
    return repository.watchPendingOwners();
  }
}
