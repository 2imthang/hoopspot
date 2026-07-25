import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// Every domain usecase implements this so Blocs depend only on the
/// abstraction, never on a concrete repository or datasource.
abstract class UseCase<ResultType, Params> {
  Future<Either<Failure, ResultType>> call(Params params);
}

/// Use for usecases that take no parameters (e.g. GetCurrentUser).
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
