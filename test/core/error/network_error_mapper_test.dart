import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_spot/core/error/network_error_mapper.dart';

/// TASK-041 — đây là logic quyết định người dùng thấy câu tiếng Việt rõ
/// ràng ("Không có kết nối mạng...") hay chuỗi kỹ thuật của Dio/Firebase
/// khi mất mạng thật — sai phân loại 1 dòng là message sai cho hàng chục
/// chỗ gọi cùng lúc (dùng chung ở mọi datasource), nên test kỹ từng
/// DioExceptionType/FirebaseException code thay vì tin bằng mắt.
void main() {
  final requestOptions = RequestOptions(path: '/test');

  DioException dioError(DioExceptionType type, {Response? response}) {
    return DioException(requestOptions: requestOptions, type: type, response: response);
  }

  group('isNetworkDioError / dioErrorMessage', () {
    test('connectionError/timeout các loại đều tính là mất mạng', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        final e = dioError(type);
        expect(isNetworkDioError(e), isTrue, reason: 'type=$type');
        expect(dioErrorMessage(e, fallback: 'fallback'), networkErrorMessage);
      }
    });

    test('badResponse không phải mất mạng, đọc đúng message server trả về dạng chuỗi', () {
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 400,
        data: {'error': 'Thiếu trường bắt buộc'},
      );
      final e = dioError(DioExceptionType.badResponse, response: response);

      expect(isNetworkDioError(e), isFalse);
      expect(dioErrorMessage(e, fallback: 'fallback'), 'Thiếu trường bắt buộc');
    });

    test('badResponse đọc đúng message server trả về dạng {error: {message: ...}} (Cloudinary)', () {
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 400,
        data: {
          'error': {'message': 'File quá lớn'},
        },
      );
      final e = dioError(DioExceptionType.badResponse, response: response);

      expect(dioErrorMessage(e, fallback: 'fallback'), 'File quá lớn');
    });

    test('badResponse không có message server dùng -> dùng fallback', () {
      final response = Response(requestOptions: requestOptions, statusCode: 500, data: null);
      final e = dioError(DioExceptionType.badResponse, response: response);

      expect(dioErrorMessage(e, fallback: 'fallback'), 'fallback');
    });
  });

  group('isNetworkFirebaseError / firebaseErrorMessage', () {
    test('code=unavailable tính là mất mạng, dùng câu chuẩn', () {
      final e = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable', message: 'x');
      expect(isNetworkFirebaseError(e), isTrue);
      expect(firebaseErrorMessage(e, fallback: 'fallback'), networkErrorMessage);
    });

    test('code khác (vd permission-denied) không phải mất mạng, dùng message gốc', () {
      final e = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions',
      );
      expect(isNetworkFirebaseError(e), isFalse);
      expect(firebaseErrorMessage(e, fallback: 'fallback'), 'Missing or insufficient permissions');
    });
  });
}
