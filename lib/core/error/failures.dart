import 'package:equatable/equatable.dart';

/// Domain-layer error type. Repositories return `Either<Failure, T>` so
/// the presentation layer (Bloc) never has to catch raw exceptions.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// The slot the user tried to book was taken by someone else in the
/// meantime — presentation layer should show this distinctly (per spec:
/// "Khung giờ vừa được đặt, vui lòng chọn khung giờ khác") and refresh
/// the slot list, not just show a generic error.
class SlotUnavailableFailure extends Failure {
  const SlotUnavailableFailure([
    super.message = 'Khung giờ vừa được đặt, vui lòng chọn khung giờ khác',
  ]);
}
