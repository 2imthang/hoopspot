import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_refund_remote_datasource.dart';
import '../datasources/booking_remote_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;
  final BookingRefundRemoteDataSource refundRemoteDataSource;

  const BookingRepositoryImpl(this.remoteDataSource, this.refundRemoteDataSource);

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

  @override
  Future<Either<Failure, List<String>>> getBookedSlots({
    required String courtId,
    required String date,
  }) async {
    try {
      final bookedSlots = await remoteDataSource.getBookedSlots(
        courtId: courtId,
        date: date,
      );
      return Right(bookedSlots);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<List<BookingEntity>> watchBookingsStatus(List<String> bookingIds) {
    return remoteDataSource.watchBookingsStatus(bookingIds);
  }

  @override
  Stream<List<BookingEntity>> watchMyBookings(String userId) {
    return remoteDataSource.watchMyBookings(userId);
  }

  @override
  Future<Either<Failure, void>> cancelBooking({
    required String userId,
    required String bookingId,
  }) async {
    try {
      await refundRemoteDataSource.cancelBooking(userId: userId, bookingId: bookingId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
