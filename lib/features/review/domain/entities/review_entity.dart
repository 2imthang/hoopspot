import 'package:equatable/equatable.dart';

/// `id` == the bookingId it was written for (see [ReviewRepository] doc
/// comment for why) — not a separately generated ID.
class ReviewEntity extends Equatable {
  final String id;
  final String courtId;
  final String userId;

  /// Snapshot của `displayName` lúc viết đánh giá — tránh phải join sang
  /// `users` mỗi lần hiển thị (cùng lý do CourtModel snapshot `pricePerSlot`
  /// vào booking).
  final String userName;

  /// 1-5.
  final int rating;

  final String comment;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.courtId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, courtId, userId, userName, rating, comment, createdAt];
}
