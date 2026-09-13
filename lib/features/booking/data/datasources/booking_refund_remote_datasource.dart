import 'package:dio/dio.dart';
import '../../../../core/constants/payment_worker_constants.dart';
import '../../../../core/error/exceptions.dart';

/// Gọi Cloudflare Worker để hủy + hoàn tiền 1 booking (TASK-025/027) — khác
/// với [BookingRemoteDataSource] vì đây là gọi HTTP tới Worker, không phải
/// đọc/ghi Firestore trực tiếp (client không được phép tự sửa `bookings`,
/// xem Security Rules).
abstract class BookingRefundRemoteDataSource {
  Future<void> cancelBooking({required String userId, required String bookingId});
}

class BookingRefundRemoteDataSourceImpl implements BookingRefundRemoteDataSource {
  final Dio dio;

  const BookingRefundRemoteDataSourceImpl(this.dio);

  @override
  Future<void> cancelBooking({
    required String userId,
    required String bookingId,
  }) async {
    try {
      await dio.post<Map<String, dynamic>>(
        PaymentWorkerConstants.refundEndpoint,
        data: {'userId': userId, 'bookingId': bookingId},
      );
    } on DioException catch (e) {
      final message =
          (e.response?.data is Map ? e.response?.data['error'] : null)
              as String? ??
          e.message ??
          'Không thể hủy booking';
      throw ServerException(message: message, statusCode: e.response?.statusCode);
    }
  }
}
