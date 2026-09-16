import 'package:equatable/equatable.dart';

/// Operating hours for a single weekday, configured by the Owner (TASK-018).
/// Times are plain "HH:mm" 24h strings (e.g. "06:00") — simple to display
/// and edit in a time picker, no timezone math needed.
class DaySchedule extends Equatable {
  final bool isOpen;
  final String openTime;
  final String closeTime;

  const DaySchedule({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  static const defaultOpen = DaySchedule(
    isOpen: true,
    openTime: '06:00',
    closeTime: '22:00',
  );

  DaySchedule copyWith({bool? isOpen, String? openTime, String? closeTime}) {
    return DaySchedule(
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  @override
  List<Object?> get props => [isOpen, openTime, closeTime];
}
