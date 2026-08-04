import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  const BookingRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    required String courtId,
    required String ownerId,
    required String date,
    required String timeSlot,
    required int pricePerSlot,
  }) async {
    try {
      final booking = await remoteDataSource.createBooking(
        courtId: courtId,
        ownerId: ownerId,
        date: date,
        timeSlot: timeSlot,
        pricePerSlot: pricePerSlot,
      );
      return Right(booking);
    } on SlotUnavailableException {
      return const Left(SlotUnavailableFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
