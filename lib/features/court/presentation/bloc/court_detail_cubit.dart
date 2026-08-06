import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/court_entity.dart';
import '../../domain/usecases/get_court_by_id_usecase.dart';

part 'court_detail_state.dart';

class CourtDetailCubit extends Cubit<CourtDetailState> {
  final GetCourtByIdUseCase getCourtByIdUseCase;

  CourtDetailCubit({required this.getCourtByIdUseCase})
    : super(const CourtDetailLoading());

  Future<void> loadCourt(String courtId) async {
    emit(const CourtDetailLoading());
    final result = await getCourtByIdUseCase(GetCourtByIdParams(courtId));
    result.fold(
      (failure) => emit(CourtDetailError(failure.message)),
      (court) => emit(CourtDetailLoaded(court)),
    );
  }
}
