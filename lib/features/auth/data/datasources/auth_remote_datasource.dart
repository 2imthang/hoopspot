import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
    required String phone,
    required UserRole role,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  const AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final user = UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        phone: phone,
        role: role,
        status: role == UserRole.owner ? UserStatus.pending : UserStatus.active,
        createdAt: DateTime.now(),
      );
      await firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .set(user.toFirestore());
      return user;
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: _mapFirebaseAuthError(e));
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email đã tồn tại';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      default:
        return e.message ?? 'Đăng ký thất bại';
    }
  }
}
