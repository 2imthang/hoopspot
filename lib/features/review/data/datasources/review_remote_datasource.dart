import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/network_error_mapper.dart';
import '../models/review_model.dart';

abstract class ReviewRemoteDataSource {
  Future<void> createReview({
    required String bookingId,
    required String courtId,
    required int rating,
    required String comment,
  });

  Future<List<ReviewModel>> getCourtReviews(String courtId);

  Future<Set<String>> getMyReviewedBookingIds(String userId);
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  ReviewRemoteDataSourceImpl({required this.firestore, required this.firebaseAuth});

  CollectionReference<Map<String, dynamic>> get _reviews =>
      firestore.collection(FirestoreCollections.reviews);

  @override
  Future<void> createReview({
    required String bookingId,
    required String courtId,
    required int rating,
    required String comment,
  }) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw const ServerException(message: 'Chưa đăng nhập');
    }
    final review = ReviewModel(
      id: bookingId,
      courtId: courtId,
      userId: user.uid,
      userName: user.displayName ?? 'Người dùng ẩn danh',
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    try {
      // `.set()` không `merge` — nếu doc đã tồn tại (đã đánh giá booking
      // này rồi), Firestore Rules coi đây là `update` và chặn lại (xem
      // `firestore.rules`).
      await _reviews.doc(bookingId).set(review.toFirestore());
    } on FirebaseException catch (e) {
      final message = firebaseErrorMessage(e, fallback: 'Không thể gửi đánh giá');
      if (isNetworkFirebaseError(e)) throw NetworkException(message: message);
      throw ServerException(message: message);
    }
  }

  @override
  Future<List<ReviewModel>> getCourtReviews(String courtId) async {
    try {
      final snapshot = await _reviews
          .where('courtId', isEqualTo: courtId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      final message = firebaseErrorMessage(e, fallback: 'Không thể tải đánh giá');
      if (isNetworkFirebaseError(e)) throw NetworkException(message: message);
      throw ServerException(message: message);
    }
  }

  @override
  Future<Set<String>> getMyReviewedBookingIds(String userId) async {
    try {
      final snapshot = await _reviews.where('userId', isEqualTo: userId).get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } on FirebaseException catch (e) {
      final message = firebaseErrorMessage(e, fallback: 'Không thể tải danh sách đã đánh giá');
      if (isNetworkFirebaseError(e)) throw NetworkException(message: message);
      throw ServerException(message: message);
    }
  }
}
