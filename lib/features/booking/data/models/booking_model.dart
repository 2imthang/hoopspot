import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking_entity.dart';

/// Maps [BookingEntity] to/from the `bookings/{bookingId}` Firestore
/// document. `id` is the document ID, not a stored field (same convention
/// as [CourtModel]).
class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.courtId,
    required super.ownerId,
    required super.date,
    required super.timeSlot,
    required super.pricePerSlot,
    required super.status,
    required super.expiresAt,
    required super.createdAt,
  });

  factory BookingModel.fromFirestore(String id, Map<String, dynamic> data) {
    return BookingModel(
      id: id,
      userId: data['userId'] as String,
      courtId: data['courtId'] as String,
      ownerId: data['ownerId'] as String,
      date: data['date'] as String,
      timeSlot: data['timeSlot'] as String,
      pricePerSlot: data['pricePerSlot'] as int,
      status: _statusFromString(data['status'] as String),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'courtId': courtId,
      'ownerId': ownerId,
      'date': date,
      'timeSlot': timeSlot,
      'pricePerSlot': pricePerSlot,
      'status': status.name,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static BookingStatus _statusFromString(String value) {
    return BookingStatus.values.firstWhere((s) => s.name == value);
  }
}
