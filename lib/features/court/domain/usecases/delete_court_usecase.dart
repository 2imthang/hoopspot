import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/court_repository.dart';

class DeleteCourtUseCase implements UseCase<void, DeleteCourtParams> {
  final CourtRepository repository;

  const DeleteCourtUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCourtParams params) {
    return repository.deleteCourt(params.courtId);
  }
}

class DeleteCourtParams extends Equatable {
  final String courtId;

  const DeleteCourtParams(this.courtId);

  @override
  List<Object?> get props => [courtId];
}
