import 'package:flutter/material.dart';

/// Màu mang ý nghĩa nghiệp vụ (không phải màu chủ đạo trong `ColorScheme`
/// của [AppTheme]) — dùng lặp lại ở nhiều badge/icon trạng thái. Gom vào
/// đây theo đúng quy ước "không hard-code color" đã ghi ở `AppTheme`, tránh
/// mỗi màn tự chọn `Colors.xxx` rời rạc dễ lệch nhau (TASK-039). Giữ
/// nguyên giá trị Material màu gốc (chỉ đổi cách gọi tên) để không đổi
/// giao diện đã test qua các task trước — Dark Mode polish là TASK-040.
class AppColors {
  const AppColors._();

  /// Trạng thái thành công/đang hoạt động: booking đã xác nhận, giao dịch
  /// thành công, sân đang mở cửa, duyệt Owner thành công...
  static const MaterialColor success = Colors.green;

  /// Trạng thái đang chờ/cảnh báo: booking chờ thanh toán, Owner chờ
  /// duyệt, hộp cảnh báo hủy do mưa, thanh toán chưa có kết quả...
  static const MaterialColor warning = Colors.amber;

  /// Trạng thái mang tính thông tin: booking đã hoàn tiền.
  static const MaterialColor info = Colors.blue;

  /// Sao đánh giá (rating stars).
  static const MaterialColor ratingStar = Colors.orange;
}
