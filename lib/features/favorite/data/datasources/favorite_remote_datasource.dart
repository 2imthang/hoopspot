import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';

abstract class FavoriteRemoteDataSource {
  Future<Set<String>> getFavoriteCourtIds(String userId);

  Future<void> addFavorite({required String userId, required String courtId});

  Future<void> removeFavorite({required String userId, required String courtId});
}

class FavoriteRemoteDataSourceImpl implements FavoriteRemoteDataSource {
  final FirebaseFirestore firestore;

  FavoriteRemoteDataSourceImpl({required this.firestore});

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      firestore.collection(FirestoreCollections.favorites).doc(userId);

  @override
  Future<Set<String>> getFavoriteCourtIds(String userId) async {
    try {
      final doc = await _doc(userId).get();
      if (!doc.exists) return {};
      final ids = doc.data()?['courtIds'] as List?;
      return Set<String>.from(ids ?? const []);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể tải danh sách yêu thích');
    }
  }

  @override
  Future<void> addFavorite({required String userId, required String courtId}) async {
    try {
      await _doc(userId).set({
        'courtIds': FieldValue.arrayUnion([courtId]),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể thêm yêu thích');
    }
  }

  @override
  Future<void> removeFavorite({required String userId, required String courtId}) async {
    try {
      await _doc(userId).set({
        'courtIds': FieldValue.arrayRemove([courtId]),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Không thể xóa yêu thích');
    }
  }
}
