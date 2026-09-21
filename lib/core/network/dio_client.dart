import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

/// Single Dio instance shared across the app, registered once in
/// [InjectionContainer] — dùng cho Cloudinary upload và Cloudflare Worker
/// (VNPay). Mỗi nơi gọi tự truyền URL tuyệt đối riêng
/// ([CloudinaryConstants]/[PaymentWorkerConstants]) nên không cấu hình
/// `baseUrl` chung ở đây (xem [ApiConstants]).
class DioClient {
  final Dio dio;

  DioClient()
    : dio = Dio(
        BaseOptions(
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: const {'Content-Type': 'application/json'},
        ),
      ) {
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }
}
