import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/booking_repository.dart';

class GetBookedSlotsUseCase
    implements UseCase<List<String>, GetBookedSlotsParams> {
  final BookingRepository repository;

  const GetBookedSlotsUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(GetBookedSlotsParams params) {
    return repository.getBookedSlots(
      courtId: params.courtId,
      date: params.date,
    );
  }
}

class GetBookedSlotsParams extends Equatable {
  final String courtId;

  /// `yyyy-MM-dd`.
  final String date;

  const GetBookedSlotsParams({required this.courtId, required this.date});

  @override
  List<Object?> get props => [courtId, date];
}
