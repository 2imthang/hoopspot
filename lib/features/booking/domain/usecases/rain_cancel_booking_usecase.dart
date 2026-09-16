import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/booking_repository.dart';

class RainCancelBookingUseCase implements UseCase<void, RainCancelBookingParams> {
  final BookingRepository repository;

  const RainCancelBookingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RainCancelBookingParams params) {
    return repository.rainCancelBooking(
      ownerId: params.ownerId,
      bookingId: params.bookingId,
    );
  }
}

class RainCancelBookingParams extends Equatable {
  final String ownerId;
  final String bookingId;

  const RainCancelBookingParams({required this.ownerId, required this.bookingId});

  @override
  List<Object?> get props => [ownerId, bookingId];
}
