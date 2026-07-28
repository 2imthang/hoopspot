import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/google_auth_result.dart';
import '../repositories/auth_repository.dart';

class GoogleSignInUseCase implements UseCase<GoogleAuthResult, NoParams> {
  final AuthRepository repository;

  const GoogleSignInUseCase(this.repository);

  @override
  Future<Either<Failure, GoogleAuthResult>> call(NoParams params) {
    return repository.loginWithGoogle();
  }
}
