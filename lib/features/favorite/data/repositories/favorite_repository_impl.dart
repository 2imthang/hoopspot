import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../datasources/favorite_remote_datasource.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteRemoteDataSource remoteDataSource;

  const FavoriteRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Set<String>>> getFavoriteCourtIds(String userId) async {
    try {
      final ids = await remoteDataSource.getFavoriteCourtIds(userId);
      return Right(ids);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addFavorite({
    required String userId,
    required String courtId,
  }) async {
    try {
      await remoteDataSource.addFavorite(userId: userId, courtId: courtId);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> removeFavorite({
    required String userId,
    required String courtId,
  }) async {
    try {
      await remoteDataSource.removeFavorite(userId: userId, courtId: courtId);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
