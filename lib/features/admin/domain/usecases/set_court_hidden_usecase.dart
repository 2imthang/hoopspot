import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../court/domain/repositories/court_repository.dart';

class SetCourtHiddenUseCase implements UseCase<void, SetCourtHiddenParams> {
  final CourtRepository repository;

  const SetCourtHiddenUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SetCourtHiddenParams params) {
    return repository.setCourtHidden(courtId: params.courtId, isHidden: params.isHidden);
  }
}

class SetCourtHiddenParams extends Equatable {
  final String courtId;
  final bool isHidden;

  const SetCourtHiddenParams({required this.courtId, required this.isHidden});

  @override
  List<Object?> get props => [courtId, isHidden];
}
