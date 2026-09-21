import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../court/domain/entities/court_entity.dart';
import '../../../court/domain/repositories/court_repository.dart';

class GetAllCourtsUseCase implements UseCase<List<CourtEntity>, NoParams> {
  final CourtRepository repository;

  const GetAllCourtsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CourtEntity>>> call(NoParams params) {
    return repository.getAllCourts();
  }
}
