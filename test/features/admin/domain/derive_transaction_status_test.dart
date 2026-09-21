import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_spot/features/admin/domain/derive_transaction_status.dart';
import 'package:hoop_spot/features/admin/presentation/bloc/transactions_cubit.dart';
import 'package:hoop_spot/features/booking/domain/entities/booking_entity.dart';

/// TASK-037 — [deriveTransactionStatus] là logic "tính hoàn tiền" hiển thị
/// cho Admin (màn Giao dịch, TASK-035): suy trạng thái giao dịch từ
/// status/refundStatus/cancelReason của booking, vì collection `payments`
/// thật không lưu trạng thái hoàn tiền. Mỗi nhánh dưới đây ứng với đúng 1
/// tình huống thật có thể xảy ra trên Firestore — xem doc comment tại nơi
/// khai báo để hiểu vì sao từng nhánh map ra kết quả đó.
void main() {
  BookingEntity booking({
    required BookingStatus status,
    String? refundStatus,
    String? cancelReason,
  }) {
    return BookingEntity(
      id: 'b1',
      userId: 'u1',
      userName: 'Test User',
      courtId: 'c1',
      ownerId: 'o1',
      date: '2026-09-20',
      timeSlot: '18:00-20:00',
      pricePerSlot: 200000,
      status: status,
      expiresAt: null,
      createdAt: DateTime(2026, 9, 1),
      refundStatus: refundStatus,
      cancelReason: cancelReason,
    );
  }

  group('deriveTransactionStatus', () {
    test('confirmed -> thành công', () {
      final result = deriveTransactionStatus(booking(status: BookingStatus.confirmed));
      expect(result, TransactionStatus.success);
    });

    test('completed -> thành công', () {
      final result = deriveTransactionStatus(booking(status: BookingStatus.completed));
      expect(result, TransactionStatus.success);
    });

    test('cancelled + refundStatus=refunded -> đã hoàn tiền', () {
      final result = deriveTransactionStatus(
        booking(
          status: BookingStatus.cancelled,
          refundStatus: 'refunded',
          cancelReason: 'rain',
        ),
      );
      expect(result, TransactionStatus.refunded);
    });

    test('cancelled không có refundStatus/cancelReason -> thất bại (IPN báo thanh toán fail)', () {
      // Đây là dạng doc thật mà vnpay-ipn.ts ghi khi isSuccess=false: chỉ
      // {status: 'cancelled'}, không kèm field nào khác — khác hẳn 1 booking
      // đã thanh toán rồi mới bị hủy sau (luôn có refundStatus).
      final result = deriveTransactionStatus(booking(status: BookingStatus.cancelled));
      expect(result, TransactionStatus.failed);
    });

    test('cancelled + refundStatus=not_eligible -> vẫn tính thành công (đã thu tiền, chỉ không hoàn)', () {
      final result = deriveTransactionStatus(
        booking(
          status: BookingStatus.cancelled,
          refundStatus: 'not_eligible',
          cancelReason: 'user_cancel',
        ),
      );
      expect(result, TransactionStatus.success);
    });

    test('cancelled + refundStatus=refund_pending -> vẫn tính thành công (VNPay refund lỗi, không phải thanh toán lỗi)', () {
      final result = deriveTransactionStatus(
        booking(
          status: BookingStatus.cancelled,
          refundStatus: 'refund_pending',
          cancelReason: 'user_cancel',
        ),
      );
      expect(result, TransactionStatus.success);
    });
  });
}
