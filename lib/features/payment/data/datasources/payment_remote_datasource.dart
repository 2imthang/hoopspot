import 'package:dio/dio.dart';
import '../../../../core/constants/payment_worker_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/payment_url_model.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentUrlModel> createPaymentUrl({
    required String userId,
    required List<String> bookingIds,
  });
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio dio;

  const PaymentRemoteDataSourceImpl(this.dio);

  @override
  Future<PaymentUrlModel> createPaymentUrl({
    required String userId,
    required List<String> bookingIds,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        PaymentWorkerConstants.createPaymentUrlEndpoint,
        data: {
          'userId': userId,
          'bookingIds': bookingIds,
          'returnUrl': PaymentWorkerConstants.returnUrl,
        },
      );
      return PaymentUrlModel.fromJson(response.data!);
    } on DioException catch (e) {
      final message =
          (e.response?.data is Map ? e.response?.data['error'] : null)
              as String? ??
          e.message ??
          'Không thể tạo URL thanh toán';
      throw ServerException(message: message, statusCode: e.response?.statusCode);
    }
  }
}
