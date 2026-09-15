import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../court/domain/entities/court_entity.dart';
import '../../../court/domain/usecases/get_court_by_id_usecase.dart';
import 'favorite_cubit.dart';

part 'favorites_list_state.dart';

/// TASK-028 — riêng cho tab "Yêu thích": lấy tập courtId đang yêu thích từ
/// [FavoriteCubit] (nguồn sự thật dùng chung), rồi tải đầy đủ [CourtEntity]
/// từng sân để hiển thị Card (giống cách BookingHistoryCubit resolve tên
/// sân) — không đặt logic này vào [FavoriteCubit] để cubit đó luôn nhẹ
/// (chỉ set ID), phục vụ được từ trái tim nhỏ ở mọi màn hình.
class FavoritesListCubit extends Cubit<FavoritesListState> {
  final FavoriteCubit favoriteCubit;
  final GetCourtByIdUseCase getCourtByIdUseCase;

  StreamSubscription<FavoriteState>? _subscription;
  final Map<String, CourtEntity> _courtCache = {};

  FavoritesListCubit({required this.favoriteCubit, required this.getCourtByIdUseCase})
    : super(const FavoritesListLoading()) {
    _subscription = favoriteCubit.stream.listen(_onFavoriteStateChanged);
    _onFavoriteStateChanged(favoriteCubit.state);
  }

  Future<void> _onFavoriteStateChanged(FavoriteState favoriteState) async {
    if (favoriteState is! FavoriteLoaded) return;
    final ids = favoriteState.courtIds;

    final missingIds = ids.difference(_courtCache.keys.toSet());
    for (final id in missingIds) {
      final result = await getCourtByIdUseCase(GetCourtByIdParams(id));
      result.fold((_) {}, (court) => _courtCache[id] = court);
    }
    _courtCache.removeWhere((id, _) => !ids.contains(id));

    emit(
      FavoritesListLoaded(
        ids.map((id) => _courtCache[id]).whereType<CourtEntity>().toList(),
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
