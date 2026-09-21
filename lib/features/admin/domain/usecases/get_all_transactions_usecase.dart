import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../booking/domain/repositories/booking_repository.dart';

class GetAllTransactionsUseCase implements UseCase<List<BookingEntity>, NoParams> {
  final BookingRepository repository;

  const GetAllTransactionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<BookingEntity>>> call(NoParams params) {
    return repository.getAllTransactions();
  }
}
