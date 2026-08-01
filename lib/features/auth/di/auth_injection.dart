import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/di/injection_container.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/check_email_verified_usecase.dart';
import '../domain/usecases/complete_google_signup_usecase.dart';
import '../domain/usecases/get_current_user_usecase.dart';
import '../domain/usecases/google_sign_in_usecase.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/resubmit_owner_application_usecase.dart';
import '../domain/usecases/send_email_verification_usecase.dart';
import '../domain/usecases/sign_out_usecase.dart';
import '../presentation/bloc/account_status_cubit.dart';
import '../presentation/bloc/complete_profile_cubit.dart';
import '../presentation/bloc/login_cubit.dart';
import '../presentation/bloc/register_cubit.dart';
import '../presentation/bloc/verify_email_cubit.dart';

void initAuthDependencies() {
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      googleSignIn: sl(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => GoogleSignInUseCase(sl()));
  sl.registerLazySingleton(() => CompleteGoogleSignUpUseCase(sl()));
  sl.registerLazySingleton(() => SendEmailVerificationUseCase(sl()));
  sl.registerLazySingleton(() => CheckEmailVerifiedUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => ResubmitOwnerApplicationUseCase(sl()));

  sl.registerFactory(() => RegisterCubit(sl()));
  sl.registerFactory(
    () => LoginCubit(
      loginUseCase: sl(),
      googleSignInUseCase: sl(),
      checkEmailVerifiedUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => VerifyEmailCubit(
      checkEmailVerifiedUseCase: sl(),
      sendEmailVerificationUseCase: sl(),
      signOutUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );
  sl.registerFactory(() => CompleteProfileCubit(sl()));
  sl.registerFactory(
    () => AccountStatusCubit(
      resubmitOwnerApplicationUseCase: sl(),
      signOutUseCase: sl(),
    ),
  );
}
