import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class CheckEmailVerifiedUseCase implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  const CheckEmailVerifiedUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.isEmailVerified();
  }
}
