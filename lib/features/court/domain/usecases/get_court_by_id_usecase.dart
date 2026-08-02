import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/court_entity.dart';
import '../repositories/court_repository.dart';

class GetCourtByIdUseCase implements UseCase<CourtEntity, GetCourtByIdParams> {
  final CourtRepository repository;

  const GetCourtByIdUseCase(this.repository);

  @override
  Future<Either<Failure, CourtEntity>> call(GetCourtByIdParams params) {
    return repository.getCourtById(params.courtId);
  }
}

class GetCourtByIdParams extends Equatable {
  final String courtId;

  const GetCourtByIdParams(this.courtId);

  @override
  List<Object?> get props => [courtId];
}
