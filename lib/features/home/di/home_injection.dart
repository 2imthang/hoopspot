import '../../../core/di/injection_container.dart';
import '../presentation/bloc/home_cubit.dart';
import '../presentation/bloc/search_cubit.dart';

void initHomeDependencies() {
  sl.registerFactory(() => HomeCubit(getVisibleCourtsUseCase: sl()));
  sl.registerFactory(() => SearchCubit(getVisibleCourtsUseCase: sl()));
}
