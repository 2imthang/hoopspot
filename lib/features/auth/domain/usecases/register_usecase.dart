import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return repository.register(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
      phone: params.phone,
      role: params.role,
    );
  }
}

class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String displayName;
  final String phone;
  final UserRole role;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.displayName,
    required this.phone,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, displayName, phone, role];
}
