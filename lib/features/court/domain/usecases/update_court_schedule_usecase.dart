import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/court_entity.dart';
import '../entities/day_schedule.dart';
import '../repositories/court_repository.dart';

class UpdateCourtScheduleUseCase
    implements UseCase<CourtEntity, UpdateCourtScheduleParams> {
  final CourtRepository repository;

  const UpdateCourtScheduleUseCase(this.repository);

  @override
  Future<Either<Failure, CourtEntity>> call(UpdateCourtScheduleParams params) {
    return repository.updateCourtSchedule(
      courtId: params.courtId,
      weeklySchedule: params.weeklySchedule,
    );
  }
}

class UpdateCourtScheduleParams extends Equatable {
  final String courtId;
  final Map<Weekday, DaySchedule> weeklySchedule;

  const UpdateCourtScheduleParams({
    required this.courtId,
    required this.weeklySchedule,
  });

  @override
  List<Object?> get props => [courtId, weeklySchedule];
}
