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
}
