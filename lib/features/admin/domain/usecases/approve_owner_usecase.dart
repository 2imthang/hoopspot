import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class ApproveOwnerUseCase implements UseCase<void, String> {
  final AuthRepository repository;

  const ApproveOwnerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String uid) {
    return repository.approveOwner(uid);
  }
}
