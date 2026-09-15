import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_favorite_court_ids_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';

part 'favorite_state.dart';

/// TASK-028 — nguồn sự thật DUY NHẤT cho "sân nào đang được yêu thích",
/// dùng chung cho mọi icon trái tim trong app (Home/Search/Court Detail).
///
/// Là 1 singleton (GetIt `registerLazySingleton`, KHÔNG phải factory theo
/// từng trang) được cung cấp (`BlocProvider.value`) NGAY TRÊN [MaterialApp]
/// trong `app.dart` — không phải chỉ bọc quanh [HomePage]. Lý do: mọi trang
/// được `Navigator.push` (Search, Court Detail...) trở thành route MỚI,
/// SONG SONG với route Home trong cùng Navigator, chứ không phải widget con
/// của Home — 1 `BlocProvider` chỉ bọc quanh HomePage sẽ không "với" tới
/// được các route đó (`ProviderNotFoundException`, đã gặp thật khi build
/// task này). Bọc ở gốc app thì mọi route đều thấy được.
///
/// Vì được tạo trước khi biết user là ai (app vừa khởi động), Cubit không
/// nhận `userId` qua constructor mà qua [setUser] — gọi đúng 1 lần ở
/// `routeAfterAuth` mỗi khi có user active mới đăng nhập, và gọi lại với
/// `null` lúc đăng xuất để không lẫn dữ liệu yêu thích giữa 2 tài khoản
/// dùng chung 1 phiên app.
class FavoriteCubit extends Cubit<FavoriteState> {
  final GetFavoriteCourtIdsUseCase getFavoriteCourtIdsUseCase;
  final ToggleFavoriteUseCase toggleFavoriteUseCase;

  String? _userId;

  FavoriteCubit({
    required this.getFavoriteCourtIdsUseCase,
    required this.toggleFavoriteUseCase,
  }) : super(const FavoriteLoading());

  Future<void> setUser(String? userId) async {
    _userId = userId;
    if (userId == null) {
      emit(const FavoriteLoaded({}));
      return;
    }
    emit(const FavoriteLoading());
    final result = await getFavoriteCourtIdsUseCase(userId);
    result.fold(
      (failure) => emit(const FavoriteLoaded({})),
      (ids) => emit(FavoriteLoaded(ids)),
    );
  }

  bool isFavorite(String courtId) {
    final current = state;
    return current is FavoriteLoaded && current.courtIds.contains(courtId);
  }

  /// Optimistic: đổi UI ngay lập tức, gọi Firestore ngầm, rollback nếu lỗi
  /// (đúng yêu cầu functional-spec 4.7).
  Future<void> toggle(String courtId) async {
    final userId = _userId;
    final current = state;
    if (userId == null || current is! FavoriteLoaded) return;

    final wasFavorite = current.courtIds.contains(courtId);
    final optimisticIds = Set<String>.from(current.courtIds);
    wasFavorite ? optimisticIds.remove(courtId) : optimisticIds.add(courtId);
    emit(FavoriteLoaded(optimisticIds));

    final result = await toggleFavoriteUseCase(
      ToggleFavoriteParams(
        userId: userId,
        courtId: courtId,
        addToFavorites: !wasFavorite,
      ),
    );
    result.fold(
      (failure) => emit(FavoriteLoaded(current.courtIds, message: failure.message)),
      (_) {},
    );
  }
}
