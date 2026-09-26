import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase implements UseCase<UserEntity, UpdateProfileParams> {
  final AuthRepository repository;

  const UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) {
    return repository.updateProfile(
      displayName: params.displayName,
      phone: params.phone,
      avatarUrl: params.avatarUrl,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String displayName;
  final String phone;
  final String? avatarUrl;

  const UpdateProfileParams({
    required this.displayName,
    required this.phone,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [displayName, phone, avatarUrl];
}
