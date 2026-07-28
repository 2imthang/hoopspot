import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/google_auth_result.dart';
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

  Future<UserModel> login({required String email, required String password});

  Future<GoogleAuthResult> signInWithGoogle();

  Future<UserModel> completeGoogleSignUp({
    required String uid,
    required String email,
    required String displayName,
    String? avatarUrl,
    required String phone,
    required UserRole role,
  });

  Future<void> sendEmailVerification();

  Future<bool> isEmailVerified();

  Future<void> signOut();

  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  Future<void>? _googleInitFuture;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
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
      await credential.user!.sendEmailVerification();
      return user;
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: _mapFirebaseAuthError(e));
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _fetchUserDoc(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: _mapFirebaseAuthError(e));
    }
  }

  @override
  Future<GoogleAuthResult> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      final userCredential = await firebaseAuth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      final firebaseUser = userCredential.user!;
      final doc = await firestore
          .collection(FirestoreCollections.users)
          .doc(firebaseUser.uid)
          .get();
      if (!doc.exists) {
        return GoogleAuthResult.needsRoleSelection(
          PendingGoogleProfile(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? account.email,
            displayName:
                firebaseUser.displayName ?? account.displayName ?? '',
            avatarUrl: firebaseUser.photoURL ?? account.photoUrl,
          ),
        );
      }
      return GoogleAuthResult.existingUser(
        UserModel.fromFirestore(firebaseUser.uid, doc.data()!),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const ServerException(message: 'Đã hủy đăng nhập Google');
      }
      throw ServerException(
        message: 'Đăng nhập Google thất bại: ${e.description ?? e.code}',
      );
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: _mapFirebaseAuthError(e));
    }
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??= googleSignIn.initialize();
  }

  @override
  Future<UserModel> completeGoogleSignUp({
    required String uid,
    required String email,
    required String displayName,
    String? avatarUrl,
    required String phone,
    required UserRole role,
  }) async {
    final user = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      phone: phone,
      role: role,
      status: role == UserRole.owner ? UserStatus.pending : UserStatus.active,
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(),
    );
    await firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set(user.toFirestore());
    return user;
  }

  @override
  Future<void> sendEmailVerification() async {
    await firebaseAuth.currentUser?.sendEmailVerification();
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return false;
    await user.reload();
    return firebaseAuth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
    await googleSignIn.signOut();
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw const ServerException(message: 'Chưa đăng nhập');
    }
    return _fetchUserDoc(firebaseUser.uid);
  }

  Future<UserModel> _fetchUserDoc(String uid) async {
    final doc = await firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (!doc.exists) {
      throw const ServerException(
        message:
            'Tài khoản chưa hoàn tất đăng ký. Vui lòng liên hệ hỗ trợ.',
      );
    }
    return UserModel.fromFirestore(uid, doc.data()!);
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email đã tồn tại';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'user-not-found':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      case 'wrong-password':
        return 'Email hoặc mật khẩu không đúng';
      case 'user-disabled':
        return 'Tài khoản đã bị khóa';
      case 'too-many-requests':
        return 'Thử lại quá nhiều lần, vui lòng thử lại sau';
      default:
        return e.message ?? 'Thao tác thất bại';
    }
  }
}
