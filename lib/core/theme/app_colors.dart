import 'package:flutter/material.dart';

/// Màu mang ý nghĩa nghiệp vụ (không phải màu chủ đạo trong `ColorScheme`
/// của [AppTheme]) — dùng lặp lại ở nhiều badge/icon trạng thái. Gom vào
/// đây theo đúng quy ước "không hard-code color" ở AppTheme, tránh mỗi màn
/// tự chọn `Colors.xxx` rời rạc dễ lệch nhau (TASK-039).
///
/// TASK-040 — bản TASK-039 dùng nguyên `MaterialColor` (1 shade cố định
/// cho mọi theme) nên khi bật Dark Mode, chữ "Chờ xác nhận" (amber 500)
/// nhìn mờ/kém tương phản hẳn so với "Đã xác nhận" (xanh) — test thật trên
/// emulator mới thấy rõ, không đoán được chỉ nhìn code. Cách M3 xử lý cho
/// `colorScheme.error`/`errorContainer` là tự đổi độ sáng theo
/// `Brightness`; 4 màu nghiệp vụ này không có sẵn role trong `ColorScheme`
/// nên tự làm tương tự bằng tay: `xxxFg()` chọn shade đậm ở light mode,
/// shade nhạt hơn ở dark mode để luôn đủ tương phản trên nền thẻ.
class AppColors {
  const AppColors._();

  /// Bản màu "phẳng" (không đổi theo theme) — chỉ dùng khi độ tương phản
  /// không phụ thuộc theme, vd nền solid của 1 `FilledButton` (chữ trắng
  /// đặt lên trên vẫn đủ tương phản ở cả 2 theme).
  static const MaterialColor success = Colors.green;
  static const MaterialColor warning = Colors.amber;
  static const MaterialColor info = Colors.blue;
  static const MaterialColor ratingStar = Colors.orange;

  /// Trạng thái thành công/đang hoạt động, dùng làm màu chữ/icon (badge,
  /// icon trạng thái...) — tự đổi shade theo Dark Mode.
  static Color successFg(BuildContext context) => _fg(context, success);

  /// Trạng thái đang chờ/cảnh báo, dùng làm màu chữ/icon.
  static Color warningFg(BuildContext context) => _fg(context, warning);

  /// Trạng thái mang tính thông tin, dùng làm màu chữ/icon.
  static Color infoFg(BuildContext context) => _fg(context, info);

  /// Sao đánh giá, dùng làm màu icon.
  static Color ratingStarFg(BuildContext context) => _fg(context, ratingStar);

  static Color _fg(BuildContext context, MaterialColor base) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? base.shade300 : base.shade800;
  }
}
