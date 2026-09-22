import 'package:dio/dio.dart';
import '../../../../core/constants/payment_worker_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/network_error_mapper.dart';

/// Gọi Cloudflare Worker để hủy + hoàn tiền 1 booking (TASK-025/027) — khác
/// với [BookingRemoteDataSource] vì đây là gọi HTTP tới Worker, không phải
/// đọc/ghi Firestore trực tiếp (client không được phép tự sửa `bookings`,
/// xem Security Rules).
abstract class BookingRefundRemoteDataSource {
  Future<void> cancelBooking({required String userId, required String bookingId});

  /// TASK-032 — Owner đánh dấu hủy do mưa (`POST /rain-cancel`, TASK-026).
  Future<void> rainCancelBooking({required String ownerId, required String bookingId});
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
      final message = dioErrorMessage(e, fallback: 'Không thể hủy booking');
      if (isNetworkDioError(e)) throw NetworkException(message: message);
      throw ServerException(message: message, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> rainCancelBooking({
    required String ownerId,
    required String bookingId,
  }) async {
    try {
      await dio.post<Map<String, dynamic>>(
        PaymentWorkerConstants.rainCancelEndpoint,
        data: {'ownerId': ownerId, 'bookingId': bookingId},
      );
    } on DioException catch (e) {
      final message = dioErrorMessage(e, fallback: 'Không thể đánh dấu hủy do mưa');
      if (isNetworkDioError(e)) throw NetworkException(message: message);
      throw ServerException(message: message, statusCode: e.response?.statusCode);
    }
  }
}
