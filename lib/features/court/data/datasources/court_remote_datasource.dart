import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../models/court_model.dart';

abstract class CourtRemoteDataSource {
  Future<CourtModel> createCourt({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> imageUrls,
    required int pricePerSlot,
    required List<String> amenities,
    required bool isOutdoor,
  });

  Future<CourtModel> updateCourt({
    required String courtId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> imageUrls,
    required int pricePerSlot,
    required List<String> amenities,
    required bool isOutdoor,
  });

  Future<void> deleteCourt(String courtId);

  Future<List<CourtModel>> getOwnerCourts();

  Future<CourtModel> getCourtById(String courtId);

  Future<List<CourtModel>> getVisibleCourts();
}

class CourtRemoteDataSourceImpl implements CourtRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  CourtRemoteDataSourceImpl({required this.firestore, required this.firebaseAuth});

  CollectionReference<Map<String, dynamic>> get _courts =>
      firestore.collection(FirestoreCollections.courts);

  String get _currentOwnerId {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw const ServerException(message: 'Chưa đăng nhập');
    }
    return uid;
  }

  @override
  Future<CourtModel> createCourt({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> imageUrls,
    required int pricePerSlot,
    required List<String> amenities,
    required bool isOutdoor,
  }) async {
    final docRef = _courts.doc();
    final court = CourtModel(
      id: docRef.id,
      ownerId: _currentOwnerId,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      imageUrls: imageUrls,
      pricePerSlot: pricePerSlot,
      amenities: amenities,
      isOutdoor: isOutdoor,
      isHidden: false,
      weeklySchedule: CourtModel.defaultWeeklySchedule(),
      createdAt: DateTime.now(),
    );
    try {
      await docRef.set(court.toFirestore());
      return court;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể tạo sân');
    }
  }

  @override
  Future<CourtModel> updateCourt({
    required String courtId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> imageUrls,
    required int pricePerSlot,
    required List<String> amenities,
    required bool isOutdoor,
  }) async {
    try {
      await _courts.doc(courtId).update({
        'name': name,
        'address': address,
        'location': GeoPoint(latitude, longitude),
        'imageUrls': imageUrls,
        'pricePerSlot': pricePerSlot,
        'amenities': amenities,
        'isOutdoor': isOutdoor,
      });
      return getCourtById(courtId);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể cập nhật sân');
    }
  }

  @override
  Future<void> deleteCourt(String courtId) async {
    try {
      await _courts.doc(courtId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể xóa sân');
    }
  }

  @override
  Future<List<CourtModel>> getOwnerCourts() async {
    try {
      final snapshot = await _courts
          .where('ownerId', isEqualTo: _currentOwnerId)
          .get();
      return snapshot.docs
          .map((doc) => CourtModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể tải danh sách sân');
    }
  }

  @override
  Future<CourtModel> getCourtById(String courtId) async {
    try {
      final doc = await _courts.doc(courtId).get();
      if (!doc.exists) {
        throw const ServerException(message: 'Không tìm thấy sân');
      }
      return CourtModel.fromFirestore(doc.id, doc.data()!);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể tải thông tin sân');
    }
  }

  @override
  Future<List<CourtModel>> getVisibleCourts() async {
    try {
      final snapshot = await _courts
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => CourtModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể tải danh sách sân');
    }
  }
}
