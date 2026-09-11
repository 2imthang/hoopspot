import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/payment_url_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  const PaymentRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PaymentUrlEntity>> createPaymentUrl({
    required String userId,
    required List<String> bookingIds,
  }) async {
    try {
      final result = await remoteDataSource.createPaymentUrl(
        userId: userId,
        bookingIds: bookingIds,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
