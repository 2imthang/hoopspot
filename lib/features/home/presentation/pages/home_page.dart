import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../admin/presentation/pages/owner_approval_page.dart';
import '../../../admin/presentation/pages/user_court_management_page.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/sign_out_usecase.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../booking/presentation/pages/booking_history_page.dart';
import '../../../booking/presentation/pages/owner_bookings_page.dart';
import '../../../court/presentation/pages/court_detail_page.dart';
import '../../../court/presentation/pages/owner_courts_page.dart';
import '../../../favorite/presentation/bloc/favorite_cubit.dart';
import '../../../favorite/presentation/pages/favorites_page.dart';
import '../../../notification/presentation/pages/notifications_page.dart';
import '../../../notification/services/booking_reminder_scheduler.dart';
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

  /// Owner thấy thêm tab "Sân của tôi" (TASK-031) — vẫn dùng chung
  /// `HomePage`, không tách app/dashboard riêng, đúng tinh thần CLAUDE.md
  /// ("Owner: tất cả quyền User + CRUD sân...").
  bool get _isOwner => widget.user.role == UserRole.owner;

  /// Admin KHÔNG "giữ tất cả quyền User" như Owner — spec liệt kê hẳn một
  /// bộ tính năng riêng (duyệt Owner, khóa/mở, xem giao dịch) và Admin
  /// không bao giờ đặt sân. Vì vậy thanh tab của Admin thay hẳn bằng tab
  /// admin-only, không cộng dồn vào tab User như cách làm với Owner (đã hỏi
  /// người dùng ở TASK-033, chọn phương án này để tránh tràn tab như từng
  /// gặp ở TASK-032 và vì không hợp lý khi Admin thấy Trang chủ/Yêu
  /// thích/Lịch sử).
  bool get _isAdmin => widget.user.role == UserRole.admin;

  List<String> get _tabs {
    if (_isAdmin) {
      return ['Duyệt Chủ sân', 'Quản lý', 'Cá nhân'];
    }
    return [
      'Trang chủ',
      if (_isOwner) 'Sân của tôi',
      // Nhãn tab rút gọn để 7 tab vẫn vừa 1 dòng trên NavigationBar — trang
      // đích (OwnerBookingsPage) vẫn hiện tiêu đề đầy đủ "Đặt sân của
      // khách" đúng mockup.
      if (_isOwner) 'Booking',
      'Yêu thích',
      'Lịch sử',
      'Thông báo',
      'Cá nhân',
    ];
  }

  List<IconData> get _tabIcons {
    if (_isAdmin) {
      return [
        Icons.fact_check_outlined,
        Icons.manage_accounts_outlined,
        Icons.person_outline_rounded,
      ];
    }
    return [
      Icons.home_rounded,
      if (_isOwner) Icons.stadium_outlined,
      if (_isOwner) Icons.event_note_outlined,
      Icons.favorite_border_rounded,
      Icons.calendar_month_outlined,
      Icons.notifications_none_rounded,
      Icons.person_outline_rounded,
    ];
  }

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
    // Không xóa để lẫn dữ liệu yêu thích nếu 1 phiên app đăng nhập tài
    // khoản khác sau đó.
    await sl<FavoriteCubit>().setUser(null);
    sl<BookingReminderScheduler>().stop();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody(context)),
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

  Widget _buildBody(BuildContext context) {
    final label = _tabs[_selectedIndex];
    switch (label) {
      case 'Trang chủ':
        return _buildHomeBody(context);
      case 'Sân của tôi':
        return const OwnerCourtsPage();
      case 'Booking':
        return OwnerBookingsPage(ownerId: widget.user.uid);
      case 'Duyệt Chủ sân':
        return const OwnerApprovalPage();
      case 'Quản lý':
        return const UserCourtManagementPage();
      case 'Yêu thích':
        return const FavoritesPage();
      case 'Lịch sử':
        return BookingHistoryPage(userId: widget.user.uid);
      case 'Thông báo':
        return const NotificationsPage();
      default:
        return _buildComingSoonTab(context, label);
    }
  }

  Widget _buildComingSoonTab(BuildContext context, String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label sắp ra mắt',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (label == 'Cá nhân') ...[
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
