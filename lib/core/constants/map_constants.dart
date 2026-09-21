/// TASK-039 — URL bản đồ, gom lại theo quy ước "không hard-code URL". Trước
/// đây URL tile OpenStreetMap bị lặp y hệt ở Court Detail lẫn Court Form
/// (2 nơi cần map preview khác nhau).
class MapConstants {
  const MapConstants._();

  /// TASK-017 — flutter_map + OpenStreetMap thay Google Maps SDK (không cần
  /// billing account/thẻ tín dụng), xem CLAUDE.md.
  static const String osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Mở app Google Maps thật để chỉ đường — chỉ là 1 link, không qua SDK
  /// nên không cần API Key/thẻ (xem CLAUDE.md).
  static String directionsUrl({required double latitude, required double longitude}) =>
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
}
