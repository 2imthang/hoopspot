import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class FavoriteRepository {
  Future<Either<Failure, Set<String>>> getFavoriteCourtIds(String userId);

  Future<Either<Failure, void>> addFavorite({
    required String userId,
    required String courtId,
  });

  Future<Either<Failure, void>> removeFavorite({
    required String userId,
    required String courtId,
  });
}
