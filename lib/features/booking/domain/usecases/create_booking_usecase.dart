import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase
    implements UseCase<BookingEntity, CreateBookingParams> {
  final BookingRepository repository;

  const CreateBookingUseCase(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(CreateBookingParams params) {
    return repository.createBooking(
      courtId: params.courtId,
      ownerId: params.ownerId,
      date: params.date,
      timeSlot: params.timeSlot,
      pricePerSlot: params.pricePerSlot,
    );
  }
}

class CreateBookingParams extends Equatable {
  final String courtId;
  final String ownerId;

  /// `yyyy-MM-dd`.
  final String date;

  /// e.g. `06:00-08:00`.
  final String timeSlot;
  final int pricePerSlot;

  const CreateBookingParams({
    required this.courtId,
    required this.ownerId,
    required this.date,
    required this.timeSlot,
    required this.pricePerSlot,
  });

  @override
  List<Object?> get props => [courtId, ownerId, date, timeSlot, pricePerSlot];
}
