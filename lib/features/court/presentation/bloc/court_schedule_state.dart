part of 'court_schedule_cubit.dart';

class CourtScheduleState extends Equatable {
  final Map<Weekday, DaySchedule> schedule;
  final bool saving;
  final String? errorMessage;

  const CourtScheduleState({
    required this.schedule,
    this.saving = false,
    this.errorMessage,
  });

  CourtScheduleState copyWith({
    Map<Weekday, DaySchedule>? schedule,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CourtScheduleState(
      schedule: schedule ?? this.schedule,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [schedule, saving, errorMessage];
}
