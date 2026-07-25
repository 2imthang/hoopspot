/// Centralized API configuration — never hard-code base URLs or endpoint
/// paths inside feature code.
class ApiConstants {
  const ApiConstants._();

  /// 10.0.2.2 is the Android emulator's alias for the host machine's
  /// localhost. Point this at the deployed backend URL for release builds.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
