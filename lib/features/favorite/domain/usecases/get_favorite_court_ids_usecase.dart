import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/favorite_repository.dart';

class GetFavoriteCourtIdsUseCase implements UseCase<Set<String>, String> {
  final FavoriteRepository repository;

  const GetFavoriteCourtIdsUseCase(this.repository);

  @override
  Future<Either<Failure, Set<String>>> call(String userId) {
    return repository.getFavoriteCourtIds(userId);
  }
}
