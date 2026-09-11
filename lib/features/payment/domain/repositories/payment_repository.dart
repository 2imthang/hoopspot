import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_url_entity.dart';

abstract class PaymentRepository {
  /// Gọi Cloudflare Worker (TASK-020) để tạo URL thanh toán VNPay đã ký.
  /// Worker tự tính lại số tiền từ Firestore, không tin [bookingIds] đi kèm
  /// giá — xem giải thích trong Worker.
  Future<Either<Failure, PaymentUrlEntity>> createPaymentUrl({
    required String userId,
    required List<String> bookingIds,
  });
}
