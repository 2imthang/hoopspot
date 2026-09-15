import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../court/presentation/pages/court_detail_page.dart';
import '../../../home/presentation/widgets/court_card.dart';
import '../bloc/favorite_cubit.dart';
import '../bloc/favorites_list_cubit.dart';

/// TASK-028 — nhúng vào tab "Yêu thích" của [HomePage] (giống cách tab
/// "Lịch sử" nhúng [BookingHistoryPage]).
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FavoritesListCubit(
        favoriteCubit: context.read<FavoriteCubit>(),
        getCourtByIdUseCase: sl(),
      ),
      child: const _FavoritesView(),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  void _openCourtDetail(BuildContext context, String courtId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CourtDetailPage(courtId: courtId)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Yêu thích',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<FavoritesListCubit, FavoritesListState>(
            builder: (context, state) {
              if (state is FavoritesListLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final courts = (state as FavoritesListLoaded).courts;
              if (courts.isEmpty) {
                return const Center(
                  child: Text('Chưa có sân yêu thích nào'),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: courts
                    .map(
                      (court) => CourtCard(
                        court: court,
                        onTap: () => _openCourtDetail(context, court.id),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
