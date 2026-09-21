import '../../booking/domain/entities/booking_entity.dart';
import '../presentation/bloc/transactions_cubit.dart';

/// TASK-035/037 — suy trạng thái "giao dịch" hiển thị ở màn Admin từ
/// `status`/`refundStatus`/`cancelReason` của booking, tách khỏi
/// [TransactionsCubit] thành hàm thuần (không phụ thuộc DI/Firestore) để
/// unit test trực tiếp — logic gốc + lý do từng nhánh, xem doc comment
/// tại nơi dùng ([TransactionsCubit._emit]).
///
/// `payments` không track hoàn tiền (nằm trên `bookings`) nên suy trạng
/// thái "giao dịch" từ `status`/`refundStatus` của booking:
/// - `confirmed`/`completed` → thành công.
/// - `cancelled` + `refundStatus == 'refunded'` → đã hoàn tiền.
/// - `cancelled` + không có `refundStatus`/`cancelReason` nào cả → đây là
///   nhánh IPN báo thanh toán thất bại (`vnpay-ipn.ts` chỉ ghi
///   `{status: 'cancelled'}` trơn khi `isSuccess == false`, không kèm 2
///   field kia) → thất bại thật sự, tiền chưa từng vào.
/// - `cancelled` với `refundStatus` khác (`not_eligible`/`refund_pending`)
///   → tiền ĐÃ được thu thành công lúc thanh toán, chỉ là hủy sau đó
///   không được hoàn (hoặc hoàn lỗi) — vẫn tính là giao dịch thành công,
///   đúng 3 trạng thái mockup có (không thêm trạng thái thứ 4).
TransactionStatus deriveTransactionStatus(BookingEntity booking) {
  if (booking.status != BookingStatus.cancelled) return TransactionStatus.success;
  if (booking.refundStatus == RefundStatusValue.refunded) return TransactionStatus.refunded;
  if (booking.refundStatus == null && booking.cancelReason == null) {
    return TransactionStatus.failed;
  }
  return TransactionStatus.success;
}
