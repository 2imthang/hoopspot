import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/favorite_repository.dart';

class ToggleFavoriteUseCase implements UseCase<void, ToggleFavoriteParams> {
  final FavoriteRepository repository;

  const ToggleFavoriteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ToggleFavoriteParams params) {
    return params.addToFavorites
        ? repository.addFavorite(userId: params.userId, courtId: params.courtId)
        : repository.removeFavorite(userId: params.userId, courtId: params.courtId);
  }
}

class ToggleFavoriteParams extends Equatable {
  final String userId;
  final String courtId;

  /// `true` để thêm vào yêu thích, `false` để bỏ — Cubit đã biết trạng thái
  /// hiện tại (đang giữ optimistic state trong bộ nhớ) nên quyết định luôn,
  /// không cần đọc lại Firestore trước khi ghi.
  final bool addToFavorites;

  const ToggleFavoriteParams({
    required this.userId,
    required this.courtId,
    required this.addToFavorites,
  });

  @override
  List<Object?> get props => [userId, courtId, addToFavorites];
}
