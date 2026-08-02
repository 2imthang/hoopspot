import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/court_entity.dart';
import '../repositories/court_repository.dart';

class GetOwnerCourtsUseCase implements UseCase<List<CourtEntity>, NoParams> {
  final CourtRepository repository;

  const GetOwnerCourtsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CourtEntity>>> call(NoParams params) {
    return repository.getOwnerCourts();
  }
}
