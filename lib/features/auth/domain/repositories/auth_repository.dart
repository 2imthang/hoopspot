import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/google_auth_result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String displayName,
    required String phone,
    required UserRole role,
  });

  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, GoogleAuthResult>> loginWithGoogle();

  /// Creates the `users/{uid}` doc for a Google account that just signed in
  /// for the first time (see [GoogleAuthResult.needsRoleSelection]).
  Future<Either<Failure, UserEntity>> completeGoogleSignUp({
    required String uid,
    required String email,
    required String displayName,
    String? avatarUrl,
    required String phone,
    required UserRole role,
  });

  Future<Either<Failure, void>> sendEmailVerification();

  /// Refreshes the current Firebase user then returns whether their email
  /// is verified — a fresh reload is needed since verification can happen
  /// on another device (clicking the link) while this session is idle.
  Future<Either<Failure, bool>> isEmailVerified();

  Future<Either<Failure, void>> signOut();

  /// Re-reads the signed-in user's `users/{uid}` doc — used after actions
  /// (email verified, Google profile completed) that need the full profile
  /// but only had a uid/email on hand.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Sets the current (rejected) Owner's status back to `pending` so Admin
  /// can review again, clearing the previous rejection reason.
  Future<Either<Failure, UserEntity>> resubmitOwnerApplication();

  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Admin (TASK-033) — mọi tài khoản Owner đang chờ duyệt, realtime.
  Stream<List<UserEntity>> watchPendingOwners();

  Future<Either<Failure, void>> approveOwner(String uid);

  Future<Either<Failure, void>> rejectOwner({
    required String uid,
    required String reason,
  });

  /// Admin (TASK-034) — mọi User/Owner đã có trạng thái ổn định
  /// (`active`/`locked`), không lấy Admin và không lấy Owner đang chờ
  /// duyệt/bị từ chối (đã có màn riêng ở TASK-033).
  Future<Either<Failure, List<UserEntity>>> getManageableUsers();

  Future<Either<Failure, void>> setUserLocked({
    required String uid,
    required bool locked,
  });

  /// Màn "Hồ sơ cá nhân" (functional-spec 4.2) — sửa tên/SĐT/ảnh đại diện.
  Future<Either<Failure, UserEntity>> updateProfile({
    required String displayName,
    required String phone,
    String? avatarUrl,
  });

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Tài khoản đăng nhập bằng Google không có mật khẩu để đổi — dùng để ẩn
  /// mục "Đổi mật khẩu" trên màn Hồ sơ cho các tài khoản này.
  bool isPasswordAccount();
}
