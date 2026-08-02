import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/court_entity.dart';
import '../repositories/court_repository.dart';

class UpdateCourtUseCase implements UseCase<CourtEntity, UpdateCourtParams> {
  final CourtRepository repository;

  const UpdateCourtUseCase(this.repository);

  @override
  Future<Either<Failure, CourtEntity>> call(UpdateCourtParams params) {
    return repository.updateCourt(
      courtId: params.courtId,
      name: params.name,
      address: params.address,
      latitude: params.latitude,
      longitude: params.longitude,
      imageUrls: params.imageUrls,
      pricePerSlot: params.pricePerSlot,
      amenities: params.amenities,
      isOutdoor: params.isOutdoor,
    );
  }
}

class UpdateCourtParams extends Equatable {
  final String courtId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final int pricePerSlot;
  final List<String> amenities;
  final bool isOutdoor;

  const UpdateCourtParams({
    required this.courtId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.pricePerSlot,
    required this.amenities,
    required this.isOutdoor,
  });

  @override
  List<Object?> get props => [
    courtId,
    name,
    address,
    latitude,
    longitude,
    imageUrls,
    pricePerSlot,
    amenities,
    isOutdoor,
  ];
}
