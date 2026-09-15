import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/favorite_cubit.dart';

/// Trái tim yêu thích dùng chung ở Card sân (Home/Search/Favorites) và màn
/// Chi tiết sân (functional-spec 4.7) — đọc/ghi qua [FavoriteCubit] dùng
/// chung toàn app nên bấm ở màn nào cũng đồng bộ ngay các màn khác.
class FavoriteButton extends StatelessWidget {
  final String courtId;

  const FavoriteButton({super.key, required this.courtId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteCubit, FavoriteState>(
      buildWhen: (previous, current) =>
          current is FavoriteLoaded &&
          (previous is! FavoriteLoaded ||
              previous.courtIds.contains(courtId) != current.courtIds.contains(courtId)),
      builder: (context, state) {
        final isFavorite = state is FavoriteLoaded && state.courtIds.contains(courtId);
        return CircleAvatar(
          backgroundColor: Colors.black45,
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : Colors.white,
            ),
            onPressed: () => context.read<FavoriteCubit>().toggle(courtId),
          ),
        );
      },
    );
  }
}
