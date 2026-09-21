import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class GetManageableUsersUseCase implements UseCase<List<UserEntity>, NoParams> {
  final AuthRepository repository;

  const GetManageableUsersUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(NoParams params) {
    return repository.getManageableUsers();
  }
}
