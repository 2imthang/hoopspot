import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/court_entity.dart';
import '../repositories/court_repository.dart';

class CreateCourtUseCase implements UseCase<CourtEntity, CreateCourtParams> {
  final CourtRepository repository;

  const CreateCourtUseCase(this.repository);

  @override
  Future<Either<Failure, CourtEntity>> call(CreateCourtParams params) {
    return repository.createCourt(
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

class CreateCourtParams extends Equatable {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final int pricePerSlot;
  final List<String> amenities;
  final bool isOutdoor;

  const CreateCourtParams({
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
