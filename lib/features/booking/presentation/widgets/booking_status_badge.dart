import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/booking_entity.dart';

/// TASK-039 — trước đây Booking History và Owner Bookings mỗi trang tự
/// định nghĩa 1 bản `_StatusBadge` giống hệt nhau (copy-paste), gộp lại
/// đây theo DRY. Admin's Giao dịch (TASK-035) hiển thị trạng thái suy ra
/// từ [BookingEntity] chứ không phải chính nó (`TransactionStatus`) nên
/// vẫn giữ badge riêng ở `transactions_page.dart`, chỉ dùng chung màu qua
/// [AppColors].
class BookingStatusBadge extends StatelessWidget {
  final BookingEntity booking;

  const BookingStatusBadge({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (booking.status) {
      BookingStatus.pendingPayment => ('Chờ xác nhận', AppColors.warningFg(context)),
      BookingStatus.confirmed => ('Đã xác nhận', AppColors.successFg(context)),
      BookingStatus.completed => ('Hoàn thành', theme.colorScheme.primary),
      BookingStatus.cancelled => booking.refundStatus == RefundStatusValue.refunded
          ? ('Đã hoàn tiền', AppColors.infoFg(context))
          : ('Đã hủy', theme.colorScheme.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
