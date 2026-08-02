import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../court/domain/entities/court_entity.dart';
import '../../../court/domain/usecases/get_visible_courts_usecase.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetVisibleCourtsUseCase getVisibleCourtsUseCase;

  HomeCubit({required this.getVisibleCourtsUseCase})
    : super(const HomeLoading());

  Future<void> loadCourts() async {
    emit(const HomeLoading());
    final result = await getVisibleCourtsUseCase(const NoParams());
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (courts) =>
          emit(courts.isEmpty ? const HomeEmpty() : HomeLoaded(courts)),
    );
  }
}
