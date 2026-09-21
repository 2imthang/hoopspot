import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_spot/features/booking/domain/entities/booking_entity.dart';
import 'package:hoop_spot/features/booking/presentation/bloc/owner_bookings_cubit.dart';

/// TASK-037 — [OwnerBookingsItem.canRainCancel] là cổng chặn trước khi
/// Owner được phép gọi Worker `/rain-cancel` để tự động hoàn 100% tiền
/// (functional-spec 4.5.B: chỉ áp dụng cho sân `isOutdoor`, booking đang
/// `confirmed`, và buổi chơi CHƯA kết thúc) — sai cổng này là cho hoàn
/// tiền sai điều kiện, nên test đủ cả 3 điều kiện tách riêng.
void main() {
  BookingEntity booking({
    required BookingStatus status,
    required String date,
    required String timeSlot,
  }) {
    return BookingEntity(
      id: 'b1',
      userId: 'u1',
      userName: 'Test User',
      courtId: 'c1',
      ownerId: 'o1',
      date: date,
      timeSlot: timeSlot,
      pricePerSlot: 200000,
      status: status,
      expiresAt: null,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  // Cố tình chọn 1 ngày rất xa trong tương lai / quá khứ để test không
  // phụ thuộc vào lúc chạy test (tránh flaky nếu ai chạy đúng lúc gần mốc).
  const futureDate = '2099-01-01';
  const pastDate = '2000-01-01';
  const slot = '18:00-20:00';

  group('OwnerBookingsItem.canRainCancel', () {
    test('true khi confirmed + sân ngoài trời + buổi chơi chưa kết thúc', () {
      final item = OwnerBookingsItem(
        booking: booking(status: BookingStatus.confirmed, date: futureDate, timeSlot: slot),
        courtName: 'Sân A',
        courtIsOutdoor: true,
      );
      expect(item.canRainCancel, isTrue);
    });

    test('false khi sân trong nhà, dù đang confirmed và chưa kết thúc', () {
      final item = OwnerBookingsItem(
        booking: booking(status: BookingStatus.confirmed, date: futureDate, timeSlot: slot),
        courtName: 'Sân A',
        courtIsOutdoor: false,
      );
      expect(item.canRainCancel, isFalse);
    });

    test('false khi booking chưa confirmed (vd pendingPayment), dù sân ngoài trời', () {
      final item = OwnerBookingsItem(
        booking: booking(status: BookingStatus.pendingPayment, date: futureDate, timeSlot: slot),
        courtName: 'Sân A',
        courtIsOutdoor: true,
      );
      expect(item.canRainCancel, isFalse);
    });

    test('false khi buổi chơi đã kết thúc, dù confirmed + sân ngoài trời', () {
      final item = OwnerBookingsItem(
        booking: booking(status: BookingStatus.confirmed, date: pastDate, timeSlot: slot),
        courtName: 'Sân A',
        courtIsOutdoor: true,
      );
      expect(item.canRainCancel, isFalse);
    });
  });
}
