import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';

// TASK-041 — "Error handling toàn cục: network error, retry". Trước đây
// mỗi datasource tự viết `on DioException`/`on FirebaseException` riêng,
// hầu hết fallback về `e.message` — với lỗi MẤT MẠNG THẬT (không có
// response, không phải lỗi server trả về), `e.message` là chuỗi kỹ thuật
// tiếng Anh của Dio/Firebase (vd "DioException [connection error]:
// Failed host lookup...") lọt thẳng ra UI cho người dùng — không phải lỗi
// giả định, đã xác nhận qua code review. `NetworkException`/
// `NetworkFailure` (core/error/exceptions.dart, failures.dart) đã có sẵn
// từ đầu dự án nhưng CHƯA TỪNG được ném/bắt ở đâu — 2 hàm dưới đây làm
// đúng việc đó: phân loại lỗi mất-mạng-thật để hiện 1 câu tiếng Việt rõ
// ràng, thống nhất ở mọi nơi, thay vì mỗi chỗ tự đoán.
//
// "Retry" (mục thứ 2 trong tên task): CHỦ ĐỘNG không tự động retry mọi
// request Dio ở tầng interceptor — phần lớn request thật trong app này là
// POST không idempotent (tạo booking, hủy, tạo URL thanh toán...), tự
// động gọi lại khi lỗi mất mạng có nguy cơ gây tác dụng phụ trùng lặp
// (vd tạo 2 booking). "Retry" ở đây nghĩa là: đảm bảo message đủ rõ để
// nút "Thử lại" (đã có sẵn khắp nơi từ TASK-036) cho người dùng biết CHÍNH
// XÁC nên làm gì (kiểm tra mạng) thay vì tự bấm lại mù quáng.

/// Lỗi Dio có phải "mất mạng thật" không (timeout, không kết nối được) —
/// khác với lỗi SERVER ĐÃ PHẢN HỒI nhưng trả về mã lỗi (400/500...).
bool isNetworkDioError(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    _ => false,
  };
}

const networkErrorMessage = 'Không có kết nối mạng, vui lòng kiểm tra lại';

/// Rút message hiện cho người dùng từ 1 [DioException] — mất mạng thật thì
/// luôn dùng đúng 1 câu chuẩn ở trên; còn lại thử đọc message server trả
/// về (Cloudflare Worker luôn trả `{"error": "..."}`), không có thì dùng
/// [fallback] (không bao giờ lộ `e.message` kỹ thuật ra UI).
String dioErrorMessage(DioException e, {required String fallback}) {
  if (isNetworkDioError(e)) return networkErrorMessage;
  final data = e.response?.data;
  if (data is Map) {
    final error = data['error'];
    if (error is String && error.isNotEmpty) return error;
    if (error is Map && error['message'] is String) return error['message'] as String;
  }
  return fallback;
}

/// Lỗi Firestore/Firebase có phải "mất mạng thật" không — `unavailable` là
/// mã lỗi SDK Firebase dùng khi không kết nối được backend.
bool isNetworkFirebaseError(FirebaseException e) => e.code == 'unavailable';

/// Tương tự [dioErrorMessage] nhưng cho [FirebaseException] (Firestore).
String firebaseErrorMessage(FirebaseException e, {required String fallback}) {
  if (isNetworkFirebaseError(e)) return networkErrorMessage;
  return e.message ?? fallback;
}
