import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class RejectOwnerUseCase implements UseCase<void, RejectOwnerParams> {
  final AuthRepository repository;

  const RejectOwnerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RejectOwnerParams params) {
    return repository.rejectOwner(uid: params.uid, reason: params.reason);
  }
}

class RejectOwnerParams extends Equatable {
  final String uid;
  final String reason;

  const RejectOwnerParams({required this.uid, required this.reason});

  @override
  List<Object?> get props => [uid, reason];
}
