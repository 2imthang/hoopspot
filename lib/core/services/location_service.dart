import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../error/failures.dart';
import 'geocoding_service.dart';

typedef DeviceLocation = ({double latitude, double longitude, String label});

/// Đọc GPS thật của thiết bị + dịch ngược thành nhãn ngắn (quận/thành phố)
/// cho "Vị trí hiện tại" ở Home/Search — trước đây là text cố định "Quận 1,
/// TP.HCM", không đọc vị trí thật của máy.
abstract class LocationService {
  Future<Either<Failure, DeviceLocation>> getCurrentLocation();
}

class DeviceLocationService implements LocationService {
  final GeocodingService geocodingService;

  const DeviceLocationService(this.geocodingService);

  @override
  Future<Either<Failure, DeviceLocation>> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const Left(ServerFailure('Vui lòng bật định vị (GPS) trên thiết bị'));
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const Left(ServerFailure('Chưa cấp quyền vị trí cho HoopSpot'));
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    final reverseResult = await geocodingService.reverse(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    return reverseResult.map(
      (label) => (latitude: position.latitude, longitude: position.longitude, label: label),
    );
  }
}
