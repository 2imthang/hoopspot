import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_spot/core/utils/vn_time.dart';

/// TASK-037 — đây là phép quy đổi giờ dùng chung cho mọi chỗ cần biết
/// "buổi chơi đã kết thúc chưa" (điều kiện hoàn tiền ≥6 tiếng, chặn hủy,
/// nhắc lịch, chặn xóa sân...). Sai 1 giờ ở đây là sai điều kiện hoàn tiền
/// thật, nên test kỹ cả trường hợp thường lẫn trường hợp lệch ngày.
void main() {
  group('parseSlotStartUtc / parseSlotEndUtc', () {
    test('quy đổi đúng 1 ca buổi tối, không lệch ngày', () {
      // 18:00-20:00 giờ VN (UTC+7) = 11:00-13:00 UTC cùng ngày.
      final start = parseSlotStartUtc('2026-09-20', '18:00-20:00');
      final end = parseSlotEndUtc('2026-09-20', '18:00-20:00');

      expect(start, DateTime.utc(2026, 9, 20, 11, 0));
      expect(end, DateTime.utc(2026, 9, 20, 13, 0));
      expect(end.difference(start), const Duration(hours: 2));
    });

    test('ca sớm đầu ngày (00:00-02:00 giờ VN) lùi về ngày UTC hôm trước', () {
      // Đây là trường hợp dễ sai nhất: trừ 7 tiếng khỏi 00:00/02:00 VN thì
      // lùi sang NGÀY UTC TRƯỚC ĐÓ, không còn cùng ngày dương lịch với
      // `date` (chuỗi giờ VN) nữa.
      final start = parseSlotStartUtc('2026-09-20', '00:00-02:00');
      final end = parseSlotEndUtc('2026-09-20', '00:00-02:00');

      expect(start, DateTime.utc(2026, 9, 19, 17, 0));
      expect(end, DateTime.utc(2026, 9, 19, 19, 0));
      expect(end.difference(start), const Duration(hours: 2));
    });
  });
}
