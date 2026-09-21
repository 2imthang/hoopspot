import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton.dart';

/// TASK-030 — tab "Thông báo": danh sách các lời nhắc trước giờ chơi đang
/// chờ (đã đặt lịch qua [NotificationService], chưa tới giờ hiện). Phạm vi
/// đã thu gọn theo lựa chọn của người dùng — chỉ nhắc lịch chơi, không làm
/// thêm thông báo "đặt sân đã xác nhận"/"hủy do mưa" như mockup gốc.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<PendingNotificationRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<NotificationService>().pendingNotifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = sl<NotificationService>().pendingNotifications();
    });
    await _future;
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
            'Thông báo',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<PendingNotificationRequest>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SkeletonList(itemBuilder: () => const SkeletonListCard(), spacing: 12);
                }
                if (snapshot.hasError) {
                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: ErrorState(
                          message: 'Không thể tải thông báo',
                          onRetry: _refresh,
                        ),
                      ),
                    ),
                  );
                }
                final reminders = snapshot.data ?? const [];
                if (reminders.isEmpty) {
                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: const EmptyState(
                          message: 'Chưa có thông báo nào',
                          icon: Icons.notifications_none_rounded,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: reminders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _ReminderCard(
                    reminder: reminders[index],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final PendingNotificationRequest reminder;

  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.notifications_active_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title ?? 'Nhắc lịch',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (reminder.body != null) ...[
                  const SizedBox(height: 2),
                  Text(reminder.body!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
