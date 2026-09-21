import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class SetUserLockedUseCase implements UseCase<void, SetUserLockedParams> {
  final AuthRepository repository;

  const SetUserLockedUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SetUserLockedParams params) {
    return repository.setUserLocked(uid: params.uid, locked: params.locked);
  }
}

class SetUserLockedParams extends Equatable {
  final String uid;
  final bool locked;

  const SetUserLockedParams({required this.uid, required this.locked});

  @override
  List<Object?> get props => [uid, locked];
}
