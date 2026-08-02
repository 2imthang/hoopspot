import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/court_entity.dart';
import '../../domain/entities/day_schedule.dart';

/// Maps [CourtEntity] to/from the `courts/{courtId}` Firestore document.
/// `id` is the document ID, not a stored field, so it's passed in
/// separately on read (same convention as [UserModel]).
class CourtModel extends CourtEntity {
  const CourtModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.imageUrls,
    required super.pricePerSlot,
    required super.amenities,
    required super.isOutdoor,
    required super.isHidden,
    required super.weeklySchedule,
    required super.createdAt,
  });

  /// Every day open 06:00-22:00 — starting point for a newly created court,
  /// the Owner adjusts it later in the Schedule Config screen (TASK-018).
  static Map<Weekday, DaySchedule> defaultWeeklySchedule() => {
    for (final day in Weekday.values) day: DaySchedule.defaultOpen,
  };

  factory CourtModel.fromFirestore(String id, Map<String, dynamic> data) {
    final location = data['location'] as GeoPoint;
    final scheduleData = Map<String, dynamic>.from(
      data['weeklySchedule'] as Map,
    );

    return CourtModel(
      id: id,
      ownerId: data['ownerId'] as String,
      name: data['name'] as String,
      address: data['address'] as String,
      latitude: location.latitude,
      longitude: location.longitude,
      imageUrls: List<String>.from(data['imageUrls'] as List),
      pricePerSlot: data['pricePerSlot'] as int,
      amenities: List<String>.from(data['amenities'] as List),
      isOutdoor: data['isOutdoor'] as bool,
      isHidden: data['isHidden'] as bool,
      weeklySchedule: {
        for (final day in Weekday.values)
          day: _dayScheduleFromMap(
            Map<String, dynamic>.from(scheduleData[day.name] as Map),
          ),
      },
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  static DaySchedule _dayScheduleFromMap(Map<String, dynamic> map) {
    return DaySchedule(
      isOpen: map['isOpen'] as bool,
      openTime: map['openTime'] as String,
      closeTime: map['closeTime'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'location': GeoPoint(latitude, longitude),
      'imageUrls': imageUrls,
      'pricePerSlot': pricePerSlot,
      'amenities': amenities,
      'isOutdoor': isOutdoor,
      'isHidden': isHidden,
      'weeklySchedule': {
        for (final entry in weeklySchedule.entries)
          entry.key.name: {
            'isOpen': entry.value.isOpen,
            'openTime': entry.value.openTime,
            'closeTime': entry.value.closeTime,
          },
      },
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
