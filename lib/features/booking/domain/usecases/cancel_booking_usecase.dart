import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/booking_repository.dart';

class CancelBookingUseCase implements UseCase<void, CancelBookingParams> {
  final BookingRepository repository;

  const CancelBookingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CancelBookingParams params) {
    return repository.cancelBooking(
      userId: params.userId,
      bookingId: params.bookingId,
    );
  }
}

class CancelBookingParams extends Equatable {
  final String userId;
  final String bookingId;

  const CancelBookingParams({required this.userId, required this.bookingId});

  @override
  List<Object?> get props => [userId, bookingId];
}
