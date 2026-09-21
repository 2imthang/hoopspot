import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../court/domain/entities/court_entity.dart';
import '../bloc/manage_courts_cubit.dart';
import '../bloc/manage_users_cubit.dart';

/// TASK-034 — "Quản lý Người dùng & Sân" (chỉ Admin), khớp mockup
/// `docs/screens/user and court management.png`. 2 tab: khóa/mở tài khoản
/// User/Owner đã `active`/`locked` (Owner đang chờ duyệt đã có màn riêng ở
/// TASK-033), và ẩn/hiện sân vi phạm.
class UserCourtManagementPage extends StatelessWidget {
  const UserCourtManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ManageUsersCubit>()..load()),
        BlocProvider(create: (_) => sl<ManageCourtsCubit>()..load()),
      ],
      child: const _ManagementView(),
    );
  }
}

enum _ManagementTab { users, courts }

class _ManagementView extends StatefulWidget {
  const _ManagementView();

  @override
  State<_ManagementView> createState() => _ManagementViewState();
}

class _ManagementViewState extends State<_ManagementView> {
  _ManagementTab _tab = _ManagementTab.users;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Quản lý Người dùng & Sân',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Người dùng'),
                selected: _tab == _ManagementTab.users,
                onSelected: (_) => setState(() => _tab = _ManagementTab.users),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: _tab == _ManagementTab.users
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Sân'),
                selected: _tab == _ManagementTab.courts,
                onSelected: (_) => setState(() => _tab = _ManagementTab.courts),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: _tab == _ManagementTab.courts
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _tab == _ManagementTab.users ? const _UsersTab() : const _CourtsTab(),
        ),
      ],
    );
  }
}

String _roleLabel(UserRole role) => switch (role) {
  UserRole.user => 'Người chơi',
  UserRole.owner => 'Chủ sân',
  UserRole.admin => 'Admin',
};

String _initialsOf(String displayName) {
  final parts = displayName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManageUsersCubit, ManageUsersState>(
      listener: (context, state) {
        if (state is ManageUsersLoaded && state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state is ManageUsersLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ManageUsersError) {
          return _ErrorRetry(
            message: state.message,
            onRetry: () => context.read<ManageUsersCubit>().load(),
          );
        }
        final loaded = state as ManageUsersLoaded;
        if (loaded.users.isEmpty) {
          return const Center(child: Text('Chưa có tài khoản nào'));
        }
        return RefreshIndicator(
          onRefresh: () => context.read<ManageUsersCubit>().load(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: loaded.users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = loaded.users[index];
              return _UserRow(
                user: user,
                busy: loaded.busyUid == user.uid,
                onToggle: () => context.read<ManageUsersCubit>().toggleLock(user),
              );
            },
          ),
        );
      },
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserEntity user;
  final bool busy;
  final VoidCallback onToggle;

  const _UserRow({required this.user, required this.busy, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = user.status == UserStatus.locked;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: locked
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.primary,
            child: Text(
              _initialsOf(user.displayName),
              style: TextStyle(
                color: locked ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_roleLabel(user.role)} · ${user.phone}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: !locked,
                onChanged: busy ? null : (_) => onToggle(),
              ),
              Text(
                locked ? 'Đã khóa' : 'Mở khóa',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: locked ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourtsTab extends StatelessWidget {
  const _CourtsTab();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManageCourtsCubit, ManageCourtsState>(
      listener: (context, state) {
        if (state is ManageCourtsLoaded && state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state is ManageCourtsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ManageCourtsError) {
          return _ErrorRetry(
            message: state.message,
            onRetry: () => context.read<ManageCourtsCubit>().load(),
          );
        }
        final loaded = state as ManageCourtsLoaded;
        if (loaded.courts.isEmpty) {
          return const Center(child: Text('Chưa có sân nào'));
        }
        return RefreshIndicator(
          onRefresh: () => context.read<ManageCourtsCubit>().load(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: loaded.courts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final court = loaded.courts[index];
              return _CourtRow(
                court: court,
                busy: loaded.busyCourtId == court.id,
                onToggle: () => context.read<ManageCourtsCubit>().toggleHidden(court),
              );
            },
          ),
        );
      },
    );
  }
}

class _CourtRow extends StatelessWidget {
  final CourtEntity court;
  final bool busy;
  final VoidCallback onToggle;

  const _CourtRow({required this.court, required this.busy, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  court.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  court.isHidden ? 'Đã ẩn' : 'Hiển thị trên ứng dụng',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: court.isHidden
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: !court.isHidden,
            onChanged: busy ? null : (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
