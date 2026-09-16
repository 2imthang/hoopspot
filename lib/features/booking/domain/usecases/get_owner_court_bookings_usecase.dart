import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class GetOwnerCourtBookingsUseCase implements UseCase<List<BookingEntity>, String> {
  final BookingRepository repository;

  const GetOwnerCourtBookingsUseCase(this.repository);

  @override
  Future<Either<Failure, List<BookingEntity>>> call(String courtId) {
    return repository.getOwnerCourtBookings(courtId);
  }
}
