import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/court_entity.dart';
import '../../domain/repositories/court_repository.dart';
import '../datasources/court_remote_datasource.dart';

class CourtRepositoryImpl implements CourtRepository {
  final CourtRemoteDataSource remoteDataSource;

  const CourtRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, CourtEntity>> createCourt({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> imageUrls,
    required int pricePerSlot,
    required List<String> amenities,
    required bool isOutdoor,
  }) async {
    try {
      final court = await remoteDataSource.createCourt(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        imageUrls: imageUrls,
        pricePerSlot: pricePerSlot,
        amenities: amenities,
        isOutdoor: isOutdoor,
      );
      return Right(court);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CourtEntity>> updateCourt({
    required String courtId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> imageUrls,
    required int pricePerSlot,
    required List<String> amenities,
    required bool isOutdoor,
  }) async {
    try {
      final court = await remoteDataSource.updateCourt(
        courtId: courtId,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        imageUrls: imageUrls,
        pricePerSlot: pricePerSlot,
        amenities: amenities,
        isOutdoor: isOutdoor,
      );
      return Right(court);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCourt(String courtId) async {
    try {
      await remoteDataSource.deleteCourt(courtId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CourtEntity>>> getOwnerCourts() async {
    try {
      final courts = await remoteDataSource.getOwnerCourts();
      return Right(courts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CourtEntity>> getCourtById(String courtId) async {
    try {
      final court = await remoteDataSource.getCourtById(courtId);
      return Right(court);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CourtEntity>>> getVisibleCourts() async {
    try {
      final courts = await remoteDataSource.getVisibleCourts();
      return Right(courts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
