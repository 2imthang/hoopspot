import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/booking_entity.dart';
import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<BookingModel> createBooking({
    required String courtId,
    required String ownerId,
    required String date,
    required String timeSlot,
    required int pricePerSlot,
  });

  /// Time slots on [courtId] + [date] that are still actually taken —
  /// a `slotLocks` doc whose 10-minute hold already expired is treated as
  /// free again, exactly like the anti-double-booking transaction does.
  Future<List<String>> getBookedSlots({
    required String courtId,
    required String date,
  });

  Stream<List<BookingModel>> watchBookingsStatus(List<String> bookingIds);

  /// Toàn bộ booking của 1 user, mới nhất trước — dùng cho Booking History
  /// (TASK-027).
  Stream<List<BookingModel>> watchMyBookings(String userId);

  /// Toàn bộ booking tại [courtId] của chính Owner đang đăng nhập
  /// (TASK-031) — filter theo `ownerId` (không phải `courtId` đơn lẻ) để
  /// thỏa điều kiện Security Rule cho phép list-query trên `bookings`.
  Future<List<BookingModel>> getOwnerCourtBookings(String courtId);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  BookingRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference<Map<String, dynamic>> get _bookings =>
      firestore.collection(FirestoreCollections.bookings);

  CollectionReference<Map<String, dynamic>> get _slotLocks =>
      firestore.collection(FirestoreCollections.slotLocks);

  String get _currentUserId {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw const ServerException(message: 'Chưa đăng nhập');
    }
    return uid;
  }

  /// One doc ID per (courtId, date, timeSlot) — none of the 3 parts can
  /// contain `_`, so joining with it can't collide two different slots
  /// onto the same ID.
  String _slotLockId(String courtId, String date, String timeSlot) =>
      '${courtId}_${date}_$timeSlot';

  @override
  Future<BookingModel> createBooking({
    required String courtId,
    required String ownerId,
    required String date,
    required String timeSlot,
    required int pricePerSlot,
  }) async {
    final userId = _currentUserId;
    final bookingRef = _bookings.doc();
    final slotLockRef = _slotLocks.doc(_slotLockId(courtId, date, timeSlot));

    try {
      // Returning `null` (instead of throwing) when the slot is taken —
      // throwing a non-FirebaseException out of the transaction closure
      // trips a bug in cloud_firestore's Android transaction bridge
      // ("Bad state: Future already completed"). Deciding whether to
      // throw SlotUnavailableException happens after runTransaction
      // returns, once we're safely back on the normal await path.
      final booking = await firestore.runTransaction<BookingModel?>((
        tx,
      ) async {
        final now = DateTime.now();
        final lockSnap = await tx.get(slotLockRef);

        if (lockSnap.exists) {
          final lockData = lockSnap.data()!;
          final lockStatus = lockData['status'] as String;
          final lockExpiresAt = (lockData['expiresAt'] as Timestamp?)
              ?.toDate();
          final holdExpired =
              lockStatus == BookingStatus.pendingPayment.name &&
              lockExpiresAt != null &&
              lockExpiresAt.isBefore(now);
          // Confirmed bookings never expire; a pending hold blocks the slot
          // only until its 10-minute `expiresAt` passes.
          if (!holdExpired) {
            return null;
          }
        }

        final newBooking = BookingModel(
          id: bookingRef.id,
          userId: userId,
          courtId: courtId,
          ownerId: ownerId,
          date: date,
          timeSlot: timeSlot,
          pricePerSlot: pricePerSlot,
          status: BookingStatus.pendingPayment,
          expiresAt: now.add(const Duration(minutes: 10)),
          createdAt: now,
        );

        tx.set(bookingRef, newBooking.toFirestore());
        tx.set(slotLockRef, {
          'bookingId': newBooking.id,
          'courtId': courtId,
          'date': date,
          'timeSlot': timeSlot,
          'status': newBooking.status.name,
          'expiresAt': Timestamp.fromDate(newBooking.expiresAt!),
        });

        return newBooking;
      });

      if (booking == null) {
        throw const SlotUnavailableException();
      }
      return booking;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể tạo booking');
    }
  }

  @override
  Future<List<String>> getBookedSlots({
    required String courtId,
    required String date,
  }) async {
    try {
      final snapshot = await _slotLocks
          .where('courtId', isEqualTo: courtId)
          .where('date', isEqualTo: date)
          .get();

      final now = DateTime.now();
      final bookedSlots = <String>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
        final holdExpired =
            status == BookingStatus.pendingPayment.name &&
            expiresAt != null &&
            expiresAt.isBefore(now);
        if (!holdExpired) {
          bookedSlots.add(data['timeSlot'] as String);
        }
      }
      return bookedSlots;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Không thể tải danh sách khung giờ',
      );
    }
  }

  @override
  Stream<List<BookingModel>> watchBookingsStatus(List<String> bookingIds) {
    // `whereIn` caps at 30 values — plenty for 1 checkout's worth of slots.
    // Also filtering by `userId` isn't just belt-and-suspenders here: the
    // `bookings` security rule checks `resource.data.userId`, and Firestore
    // rejects a list query with `permission-denied` unless that same field
    // is constrained by an equality filter in the query itself.
    return _bookings
        .where(FieldPath.documentId, whereIn: bookingIds)
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<BookingModel>> watchMyBookings(String userId) {
    return _bookings
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<List<BookingModel>> getOwnerCourtBookings(String courtId) async {
    try {
      final snapshot = await _bookings
          .where('ownerId', isEqualTo: _currentUserId)
          .where('courtId', isEqualTo: courtId)
          .get();
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể tải danh sách booking');
    }
  }
}
