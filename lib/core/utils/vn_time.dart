/// `date`/`timeSlot` trên booking là chuỗi giờ VN (GMT+7) thuần (VD
/// "2026-09-20" + "18:00-20:00") — quy đổi đúng thời điểm UTC thật bằng
/// cách trừ 7 tiếng khỏi mốc UTC "naive" dựng từ các số đó. Cùng logic với
/// Worker's `refundExecution.ts`'s `parseSlotBoundary`, dùng chung ở mọi nơi
/// cần so sánh giờ chơi với "bây giờ" (Booking History, nhắc lịch, chặn xóa
/// sân đang có booking) để không lặp lại 1 phép tính dễ sai ở nhiều chỗ.
DateTime _parseSlotBoundary(String date, String timeSlot, {required bool end}) {
  final parts = date.split('-').map(int.parse).toList();
  final hourStr = (end ? timeSlot.split('-')[1] : timeSlot.split('-')[0]).split(':')[0];
  final hour = int.parse(hourStr);
  final naiveUtcMs = DateTime.utc(parts[0], parts[1], parts[2], hour).millisecondsSinceEpoch;
  return DateTime.fromMillisecondsSinceEpoch(
    naiveUtcMs - 7 * 60 * 60 * 1000,
    isUtc: true,
  );
}

DateTime parseSlotStartUtc(String date, String timeSlot) =>
    _parseSlotBoundary(date, timeSlot, end: false);

DateTime parseSlotEndUtc(String date, String timeSlot) =>
    _parseSlotBoundary(date, timeSlot, end: true);
