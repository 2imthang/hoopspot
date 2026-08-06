import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/sign_out_usecase.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../court/presentation/pages/court_detail_page.dart';
import '../bloc/home_cubit.dart';
import '../widgets/court_card.dart';
import 'search_page.dart';

class HomePage extends StatelessWidget {
  final UserEntity user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeCubit>()..loadCourts(),
      child: _HomeView(user: user),
    );
  }
}

class _HomeView extends StatefulWidget {
  final UserEntity user;

  const _HomeView({required this.user});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _selectedIndex = 0;

  static const _tabs = ['Trang chủ', 'Yêu thích', 'Lịch sử', 'Thông báo', 'Cá nhân'];
  static const _tabIcons = [
    Icons.home_rounded,
    Icons.favorite_border_rounded,
    Icons.calendar_month_outlined,
    Icons.notifications_none_rounded,
    Icons.person_outline_rounded,
  ];

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  }

  void _openCourtDetail(BuildContext context, String courtId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourtDetailPage(courtId: courtId)),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await sl<SignOutUseCase>()(const NoParams());
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildHomeBody(context)
            : _buildComingSoonTab(context),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(icon: Icon(_tabIcons[i]), label: _tabs[i]),
        ],
      ),
    );
  }

  Widget _buildComingSoonTab(BuildContext context) {
    final label = _tabs[_selectedIndex];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label sắp ra mắt',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_selectedIndex == 4) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _signOut(context),
              child: const Text('Đăng xuất'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<HomeCubit>().loadCourts(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationRow(context),
            const SizedBox(height: 16),
            _buildSearchRow(context),
            const SizedBox(height: 16),
            _buildPromoBanner(context),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sân gần bạn',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _openSearch(context),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCourtsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initialsOf(widget.user.displayName);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VỊ TRÍ HIỆN TẠI',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Quận 1, TP.HCM',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.expand_more),
                ],
              ),
            ],
          ),
        ),
        CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            initials,
            style: TextStyle(color: theme.colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _openSearch(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Tìm sân bóng rổ...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () => _openSearch(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.tune, color: theme.colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giảm 20% khung giờ sáng',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Áp dụng cuối tuần này · Mã HOOP20',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtsList() {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is HomeError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<HomeCubit>().loadCourts(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is HomeEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('Chưa có sân nào, quay lại sau nhé')),
          );
        }
        final courts = (state as HomeLoaded).courts;
        return Column(
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
    );
  }

  String _initialsOf(String displayName) {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
