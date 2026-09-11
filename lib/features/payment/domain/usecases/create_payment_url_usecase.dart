import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_url_entity.dart';
import '../repositories/payment_repository.dart';

class CreatePaymentUrlUseCase
    implements UseCase<PaymentUrlEntity, CreatePaymentUrlParams> {
  final PaymentRepository repository;

  const CreatePaymentUrlUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentUrlEntity>> call(
    CreatePaymentUrlParams params,
  ) {
    return repository.createPaymentUrl(
      userId: params.userId,
      bookingIds: params.bookingIds,
    );
  }
}

class CreatePaymentUrlParams extends Equatable {
  final String userId;
  final List<String> bookingIds;

  const CreatePaymentUrlParams({
    required this.userId,
    required this.bookingIds,
  });

  @override
  List<Object?> get props => [userId, bookingIds];
}
