/// Thrown by the data layer (datasources). Repositories catch these and
/// translate them into [Failure]s before they ever reach the domain layer.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({this.message = 'Server error', this.statusCode});
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache error'});
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});
}

/// Thrown by [BookingRemoteDataSource.createBooking] when the requested
/// (courtId, date, timeSlot) is already held by another pending/confirmed
/// booking — the Firestore transaction detected this atomically, so it's
/// a real conflict, not a stale read.
class SlotUnavailableException implements Exception {
  const SlotUnavailableException();
}
