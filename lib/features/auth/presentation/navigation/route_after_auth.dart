import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../favorite/presentation/bloc/favorite_cubit.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../notification/services/booking_reminder_scheduler.dart';
import '../../domain/entities/user_entity.dart';
import '../pages/account_status_page.dart';

/// Single place that decides where to land after any successful auth step
/// (login, email verified, Google profile completed): `active` users go to
/// Home, everyone else (`pending`/`rejected`/`locked`) is blocked on
/// [AccountStatusPage] until Admin approves them or unlocks the account.
void routeAfterAuth(BuildContext context, UserEntity user) {
  final isActive = user.status == UserStatus.active;
  if (isActive) {
    // Nạp danh sách yêu thích của đúng user này — Cubit dùng chung toàn
    // app (xem [FavoriteCubit]), chỉ cần gọi 1 lần ở đây mỗi khi có user
    // active mới đăng nhập.
    sl<FavoriteCubit>().setUser(user.uid);
    // Bắt đầu nghe live mọi booking của user để tự lên lịch/hủy nhắc trước
    // giờ chơi (TASK-030) — dịch vụ nền, sống suốt phiên, không gắn vào 1
    // trang cụ thể (xem [BookingReminderScheduler]).
    sl<BookingReminderScheduler>().start(user.uid);
  }
  final page = isActive ? HomePage(user: user) : AccountStatusPage(user: user);
  Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute(builder: (_) => page));
}
