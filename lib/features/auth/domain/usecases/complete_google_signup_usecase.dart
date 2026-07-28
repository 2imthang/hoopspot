import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class CompleteGoogleSignUpUseCase
    implements UseCase<UserEntity, CompleteGoogleSignUpParams> {
  final AuthRepository repository;

  const CompleteGoogleSignUpUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(
    CompleteGoogleSignUpParams params,
  ) {
    return repository.completeGoogleSignUp(
      uid: params.uid,
      email: params.email,
      displayName: params.displayName,
      avatarUrl: params.avatarUrl,
      phone: params.phone,
      role: params.role,
    );
  }
}

class CompleteGoogleSignUpParams extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String phone;
  final UserRole role;

  const CompleteGoogleSignUpParams({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.phone,
    required this.role,
  });

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    avatarUrl,
    phone,
    role,
  ];
}
