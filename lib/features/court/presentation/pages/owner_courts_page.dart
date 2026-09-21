import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/court_entity.dart';
import '../../domain/entities/day_schedule.dart';
import '../bloc/owner_courts_cubit.dart';
import 'court_form_page.dart';

/// TASK-031 — tab "Sân của tôi", chỉ hiện với tài khoản Owner (khớp mockup
/// `docs/screens/my courts.png`).
class OwnerCourtsPage extends StatelessWidget {
  const OwnerCourtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OwnerCourtsCubit>()..load(),
      child: const _OwnerCourtsView(),
    );
  }
}

class _OwnerCourtsView extends StatelessWidget {
  const _OwnerCourtsView();

  Future<void> _openForm(BuildContext context, {CourtEntity? court}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CourtFormPage(court: court)),
    );
    if (saved == true && context.mounted) {
      context.read<OwnerCourtsCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<OwnerCourtsCubit, OwnerCourtsState>(
      listener: (context, state) {
        if (state is OwnerCourtsLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sân của tôi',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, OwnerCourtsState state) {
    if (state is OwnerCourtsLoading) {
      return SkeletonList(itemBuilder: () => const SkeletonCourtCard(), padding: const EdgeInsets.fromLTRB(16, 0, 16, 16));
    }
    if (state is OwnerCourtsError) {
      return ErrorState(
        message: state.message,
        onRetry: () => context.read<OwnerCourtsCubit>().load(),
      );
    }
    final loaded = state as OwnerCourtsLoaded;
    return RefreshIndicator(
      onRefresh: () => context.read<OwnerCourtsCubit>().load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (loaded.courts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyState(
                message: 'Chưa có sân nào, thêm sân đầu tiên nhé',
                icon: Icons.stadium_outlined,
              ),
            )
          else
            for (final court in loaded.courts) ...[
              _OwnerCourtCard(
                court: court,
                busy: loaded.busyCourtId == court.id,
                onEdit: () => _openForm(context, court: court),
              ),
              const SizedBox(height: 16),
            ],
          OutlinedButton.icon(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Thêm sân mới'),
          ),
        ],
      ),
    );
  }
}

class _OwnerCourtCard extends StatelessWidget {
  final CourtEntity court;
  final bool busy;
  final VoidCallback onEdit;

  const _OwnerCourtCard({required this.court, required this.busy, required this.onEdit});

  DateTime get _nowVn => DateTime.now().toUtc().add(const Duration(hours: 7));

  DaySchedule? get _todaySchedule =>
      court.weeklySchedule[Weekday.values[_nowVn.weekday - 1]];

  bool get _isOpenNow {
    final today = _todaySchedule;
    if (today == null || !today.isOpen) return false;
    final nowMinutes = _nowVn.hour * 60 + _nowVn.minute;
    return nowMinutes >= _toMinutes(today.openTime) && nowMinutes < _toMinutes(today.closeTime);
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sân?'),
        content: Text('Xóa "${court.name}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<OwnerCourtsCubit>().deleteCourt(court);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _todaySchedule;
    final hoursText = today == null || !today.isOpen
        ? 'Đóng cửa hôm nay'
        : '${today.openTime}-${today.closeTime}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: court.imageUrls.isEmpty
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHigh,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Image.network(court.imageUrls.first, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${court.name} — ${court.isOutdoor ? 'Ngoài trời' : 'Trong nhà'}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isOpenNow ? AppColors.success : theme.colorScheme.error)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isOpenNow ? 'Đang mở' : 'Tạm đóng',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _isOpenNow ? AppColors.success : theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatVnd(court.pricePerSlot)}/giờ · $hoursText',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text('Sân ngoài trời', style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    Switch(
                      value: court.isOutdoor,
                      onChanged: busy
                          ? null
                          : (_) => context.read<OwnerCourtsCubit>().toggleOutdoor(court),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: busy ? null : onEdit,
                child: const Text('Sửa'),
              ),
              TextButton(
                onPressed: busy ? null : () => _confirmDelete(context),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Xóa'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
