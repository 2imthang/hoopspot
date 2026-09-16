import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/court_entity.dart';
import '../../domain/entities/day_schedule.dart';
import '../bloc/court_schedule_cubit.dart';

const _dayLabels = {
  Weekday.mon: 'Thứ Hai',
  Weekday.tue: 'Thứ Ba',
  Weekday.wed: 'Thứ Tư',
  Weekday.thu: 'Thứ Năm',
  Weekday.fri: 'Thứ Sáu',
  Weekday.sat: 'Thứ Bảy',
  Weekday.sun: 'Chủ Nhật',
};

/// TASK-031 — khớp mockup `docs/screens/court schedule config.png`.
class CourtSchedulePage extends StatelessWidget {
  final CourtEntity court;

  const CourtSchedulePage({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CourtScheduleCubit>(
        param1: court.id,
        param2: court.weeklySchedule,
      ),
      child: _CourtScheduleView(courtName: court.name),
    );
  }
}

class _CourtScheduleView extends StatelessWidget {
  final String courtName;

  const _CourtScheduleView({required this.courtName});

  Future<void> _pickTime(BuildContext context, Weekday day, {required bool isOpenTime}) async {
    final cubit = context.read<CourtScheduleCubit>();
    final current = cubit.state.schedule[day]!;
    final currentText = isOpenTime ? current.openTime : current.closeTime;
    final parts = currentText.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    isOpenTime ? cubit.setOpenTime(day, formatted) : cubit.setCloseTime(day, formatted);
  }

  Future<void> _save(BuildContext context) async {
    final saved = await context.read<CourtScheduleCubit>().save();
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu giờ hoạt động')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Giờ hoạt động — $courtName')),
      body: BlocConsumer<CourtScheduleCubit, CourtScheduleState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bật/tắt và chỉnh khung giờ mở cửa cho từng ngày trong tuần',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final day in Weekday.values) ...[
                        _DayRow(
                          label: _dayLabels[day]!,
                          schedule: state.schedule[day]!,
                          onToggle: () => context.read<CourtScheduleCubit>().toggleDay(day),
                          onTapOpenTime: () => _pickTime(context, day, isOpenTime: true),
                          onTapCloseTime: () => _pickTime(context, day, isOpenTime: false),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.saving ? null : () => _save(context),
                      child: state.saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Lưu thay đổi'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final DaySchedule schedule;
  final VoidCallback onToggle;
  final VoidCallback onTapOpenTime;
  final VoidCallback onTapCloseTime;

  const _DayRow({
    required this.label,
    required this.schedule,
    required this.onToggle,
    required this.onTapOpenTime,
    required this.onTapCloseTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (schedule.isOpen)
            Row(
              children: [
                InkWell(
                  onTap: onTapOpenTime,
                  child: Text(schedule.openTime, style: theme.textTheme.bodyMedium),
                ),
                Text(' - ', style: theme.textTheme.bodyMedium),
                InkWell(
                  onTap: onTapCloseTime,
                  child: Text(schedule.closeTime, style: theme.textTheme.bodyMedium),
                ),
              ],
            )
          else
            Text(
              'Đóng cửa',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 12),
          Switch(value: schedule.isOpen, onChanged: (_) => onToggle()),
        ],
      ),
    );
  }
}
