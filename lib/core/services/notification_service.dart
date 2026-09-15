import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// TASK-030 — nhắc lịch trước giờ chơi qua local notification
/// (functional-spec 4.9). Bọc [FlutterLocalNotificationsPlugin] thành 1
/// service duy nhất, không phải Bloc/Cubit vì không có UI state riêng —
/// chỉ có tác dụng phụ (side effect) lên hệ thống thông báo.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'booking_reminders';
  static const _channelName = 'Nhắc lịch đặt sân';
  static const _channelDescription = 'Thông báo nhắc trước giờ chơi';

  /// GMT+7 cố định — HoopSpot chỉ phục vụ thị trường VN, không cần dò múi
  /// giờ thiết bị (tránh phải thêm package `flutter_timezone`).
  static const _vnTimeZone = 'Asia/Ho_Chi_Minh';

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_vnTimeZone));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);

    // Edge case (functional-spec 4.9): user tắt quyền thông báo → app vẫn
    // hoạt động bình thường, không chặn luồng chính — không `await`/throw
    // nếu bị từ chối, chỉ đơn giản là notification sẽ không hiện.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// 2 ID cố định suy ra từ `bookingId` (không phải random) — để hủy đúng
  /// thông báo của đúng booking sau này mà không cần lưu trạng thái riêng.
  (int, int) _idsFor(String bookingId) {
    final base = bookingId.hashCode & 0x3fffffff; // giữ dương, tránh tràn int32
    return (base, base + 1);
  }

  /// Lên lịch 2 thông báo nhắc — 1 tiếng và 15 phút trước [playStartUtc].
  /// Bỏ qua mốc nào đã qua (VD user mở app đặt sân sát giờ chơi).
  Future<void> scheduleBookingReminders({
    required String bookingId,
    required String courtName,
    required DateTime playStartUtc,
  }) async {
    if (!_initialized) await init();
    final (idOneHour, idFifteenMin) = _idsFor(bookingId);
    await _scheduleIfFuture(
      id: idOneHour,
      title: 'Nhắc lịch chơi bóng rổ',
      body: 'Sân $courtName trong 1 giờ nữa',
      triggerUtc: playStartUtc.subtract(const Duration(hours: 1)),
    );
    await _scheduleIfFuture(
      id: idFifteenMin,
      title: 'Nhắc lịch chơi bóng rổ',
      body: 'Sân $courtName trong 15 phút nữa',
      triggerUtc: playStartUtc.subtract(const Duration(minutes: 15)),
    );
  }

  Future<void> _scheduleIfFuture({
    required int id,
    required String title,
    required String body,
    required DateTime triggerUtc,
  }) async {
    if (triggerUtc.isBefore(DateTime.now().toUtc())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(triggerUtc, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // Không cần quyền "Báo thức & lời nhắc" đặc biệt (SCHEDULE_EXACT_ALARM)
      // — sai lệch vài phút chấp nhận được cho 1 lời nhắc, đổi lại UX xin
      // quyền đơn giản hơn nhiều.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Hủy 2 thông báo nhắc của 1 booking — gọi khi user hủy booking
  /// (functional-spec 4.9: "hủy lịch thông báo tương ứng nếu user hủy
  /// booking"). An toàn gọi kể cả khi chưa từng lên lịch (no-op).
  Future<void> cancelBookingReminders(String bookingId) async {
    if (!_initialized) await init();
    final (idOneHour, idFifteenMin) = _idsFor(bookingId);
    await _plugin.cancel(id: idOneHour);
    await _plugin.cancel(id: idFifteenMin);
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    if (!_initialized) await init();
    return _plugin.pendingNotificationRequests();
  }

  Future<Set<int>> pendingNotificationIds() async {
    final pending = await pendingNotifications();
    return pending.map((p) => p.id).toSet();
  }

  bool hasScheduledReminder(String bookingId, Set<int> pendingIds) {
    final (idOneHour, idFifteenMin) = _idsFor(bookingId);
    return pendingIds.contains(idOneHour) || pendingIds.contains(idFifteenMin);
  }
}
