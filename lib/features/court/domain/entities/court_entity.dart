import 'package:equatable/equatable.dart';
import 'day_schedule.dart';

/// Keys for [CourtEntity.weeklySchedule] — matches `DateTime.weekday` order
/// (mon..sun) so converting between the two is straightforward.
enum Weekday { mon, tue, wed, thu, fri, sat, sun }

class CourtEntity extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final int pricePerSlot;
  final List<String> amenities;
  final bool isOutdoor;
  final bool isHidden;
  final Map<Weekday, DaySchedule> weeklySchedule;
  final DateTime createdAt;

  const CourtEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.pricePerSlot,
    required this.amenities,
    required this.isOutdoor,
    required this.isHidden,
    required this.weeklySchedule,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    address,
    latitude,
    longitude,
    imageUrls,
    pricePerSlot,
    amenities,
    isOutdoor,
    isHidden,
    weeklySchedule,
    createdAt,
  ];
}
