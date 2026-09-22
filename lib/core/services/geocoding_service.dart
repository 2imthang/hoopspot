import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../constants/map_constants.dart';
import '../error/failures.dart';
import '../error/network_error_mapper.dart';

typedef GeocodedPoint = ({double latitude, double longitude});

/// Dịch địa chỉ chữ (Owner gõ tay) thành tọa độ, để tự đặt marker trên bản
/// đồ ở màn Thêm/Sửa sân — trước đây ô địa chỉ và bản đồ hoàn toàn tách rời
/// (Owner phải tự chạm đúng điểm), gây bất tiện khi test thật với sân ở xa
/// vị trí mặc định của bản đồ.
abstract class GeocodingService {
  Future<Either<Failure, GeocodedPoint>> search(String address);

  /// Chiều ngược lại — tọa độ GPS thật của máy → nhãn ngắn "Quận/Huyện,
  /// Thành phố" để hiển thị ở "Vị trí hiện tại" (Home/Search).
  Future<Either<Failure, String>> reverse({
    required double latitude,
    required double longitude,
  });
}

class NominatimGeocodingService implements GeocodingService {
  final Dio dio;

  const NominatimGeocodingService(this.dio);

  @override
  Future<Either<Failure, GeocodedPoint>> search(String address) async {
    try {
      final response = await dio.get<List<dynamic>>(
        MapConstants.nominatimSearchUrl,
        queryParameters: {'q': address, 'format': 'json', 'limit': 1},
        // Nominatim yêu cầu User-Agent nhận diện đúng app gọi, không dùng
        // mặc định của client HTTP — theo chính sách sử dụng miễn phí.
        options: Options(headers: {'User-Agent': 'HoopSpotApp/1.0'}),
      );
      final results = response.data ?? const [];
      if (results.isEmpty) {
        return const Left(
          ServerFailure('Không tìm thấy vị trí này, thử nhập địa chỉ chi tiết hơn'),
        );
      }
      final first = results.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat'] as String? ?? '');
      final lon = double.tryParse(first['lon'] as String? ?? '');
      if (lat == null || lon == null) {
        return const Left(
          ServerFailure('Không tìm thấy vị trí này, thử nhập địa chỉ chi tiết hơn'),
        );
      }
      return Right((latitude: lat, longitude: lon));
    } on DioException catch (e) {
      final message = dioErrorMessage(e, fallback: 'Không tìm được vị trí, thử lại sau');
      if (isNetworkDioError(e)) return Left(NetworkFailure(message));
      return Left(ServerFailure(message));
    }
  }

  @override
  Future<Either<Failure, String>> reverse({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        MapConstants.nominatimReverseUrl,
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'json',
          'addressdetails': 1,
          'zoom': 14, // mức quận/huyện — không cần chi tiết tới số nhà
        },
        options: Options(headers: {'User-Agent': 'HoopSpotApp/1.0'}),
      );
      final address = response.data?['address'] as Map<String, dynamic>?;
      if (address == null) {
        return const Left(ServerFailure('Không xác định được vị trí hiện tại'));
      }
      final district = address['city_district'] as String? ??
          address['county'] as String? ??
          address['suburb'] as String?;
      final city = address['city'] as String? ??
          address['state'] as String? ??
          address['town'] as String?;
      final label = [district, city].whereType<String>().join(', ');
      if (label.isEmpty) {
        return const Left(ServerFailure('Không xác định được vị trí hiện tại'));
      }
      return Right(label);
    } on DioException catch (e) {
      final message = dioErrorMessage(e, fallback: 'Không xác định được vị trí hiện tại');
      if (isNetworkDioError(e)) return Left(NetworkFailure(message));
      return Left(ServerFailure(message));
    }
  }
}
