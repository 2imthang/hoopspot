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

  /// Nominatim — dịch vụ geocoding miễn phí của chính OpenStreetMap, cùng
  /// nhà cung cấp bản đồ ở trên, không cần API key/thẻ. Dùng khi Owner bấm
  /// "Tìm vị trí" ở màn Thêm/Sửa sân để đổi địa chỉ chữ thành tọa độ (xem
  /// [GeocodingService]). Chỉ gọi khi bấm nút, không gọi theo từng ký tự gõ
  /// — chính sách dùng miễn phí của Nominatim giới hạn ~1 request/giây.
  static const String nominatimSearchUrl = 'https://nominatim.openstreetmap.org/search';

  /// Dịch tọa độ GPS thật của máy → tên quận/thành phố ngắn gọn để hiển thị
  /// ở "Vị trí hiện tại" (Home/Search) — xem [GeocodingService.reverse].
  static const String nominatimReverseUrl = 'https://nominatim.openstreetmap.org/reverse';
}
