/// Keys used with [FlutterSecureStorage] — centralized so a typo can't
/// silently create a second, orphaned storage entry.
class StorageKeys {
  const StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
}
