import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_spot/core/di/injection_container.dart';
import 'package:hoop_spot/core/error/failures.dart';
import 'package:hoop_spot/core/utils/currency_formatter.dart';
import 'package:hoop_spot/features/booking/domain/entities/booking_entity.dart';
import 'package:hoop_spot/features/booking/domain/repositories/booking_repository.dart';
import 'package:hoop_spot/features/booking/domain/usecases/create_booking_usecase.dart';
import 'package:hoop_spot/features/booking/domain/usecases/get_booked_slots_usecase.dart';
import 'package:hoop_spot/features/booking/presentation/bloc/booking_slots_cubit.dart';
import 'package:hoop_spot/features/booking/presentation/pages/booking_slots_page.dart';
import 'package:hoop_spot/features/court/domain/entities/court_entity.dart';
import 'package:hoop_spot/features/court/domain/entities/day_schedule.dart';

/// TASK-038 — "booking flow": chọn ca ở [BookingSlotsPage] (TASK-018) cập
/// nhật tổng tiền/nút "Đặt sân" đúng, và slot đã có người đặt thì không
/// chọn được — đúng phần lõi của luồng đặt sân trước khi vào thanh toán.
///
/// [BookingSlotsPage] dựng Cubit qua `sl<BookingSlotsCubit>(param1: court)`
/// (GetIt) chứ không nhận Cubit qua constructor, nên test này đăng ký 1
/// factory giả vào `sl` thật (dùng [_FakeBookingRepository], không đụng
/// Firebase) thay vì gọi `initDependencies()` đầy đủ. Test CHỈ dừng ở bước
/// chọn/bỏ chọn ca — không bấm "Đặt sân" tới lúc thành công, vì lúc đó
/// trang điều hướng sẽ đọc `FirebaseAuth.instance.currentUser` (không có
/// Firebase thật trong môi trường test).
void main() {
  late CourtEntity court;

  /// Đăng ký 1 factory giả cho `BookingSlotsCubit` vào `sl` thật — gọi lại
  /// ở đầu MỖI test (không dùng chung qua `setUp`) để test thứ 3 có thể
  /// đăng ký fake repo với `bookedSlots` khác mà không đụng `unregister`.
  void registerFakeCubit({List<String> bookedSlots = const []}) {
    if (sl.isRegistered<BookingSlotsCubit>()) sl.unregister<BookingSlotsCubit>();
    sl.registerFactoryParam<BookingSlotsCubit, CourtEntity, void>(
      (court, _) => BookingSlotsCubit(
        court: court,
        getBookedSlotsUseCase: GetBookedSlotsUseCase(
          _FakeBookingRepository(bookedSlots: bookedSlots),
        ),
        createBookingUseCase: CreateBookingUseCase(_FakeBookingRepository()),
      ),
    );
  }

  setUp(() {
    court = CourtEntity(
      id: 'court-1',
      ownerId: 'owner-1',
      name: 'Sân Test',
      address: '123 Test',
      latitude: 10.0,
      longitude: 106.0,
      imageUrls: const [],
      pricePerSlot: 200000,
      amenities: const [],
      isOutdoor: false,
      isHidden: false,
      weeklySchedule: {for (final day in Weekday.values) day: DaySchedule.defaultOpen},
      createdAt: DateTime(2026, 1, 1),
    );
    registerFakeCubit();
  });

  tearDown(() => sl.reset());

  /// Ca hôm nay có thể đã "quá giờ" tùy lúc chạy test — chuyển sang ngày
  /// mai (luôn còn nguyên slot, xem `BookingSlotsCubit.isPastSlot`) để mọi
  /// slot đều chắc chắn chọn được, không phụ thuộc giờ chạy test.
  Future<void> selectTomorrow(WidgetTester tester) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(find.text('${tomorrow.day}'));
    await tester.pumpAndSettle();
  }

  testWidgets('chọn 1 ca cập nhật đúng tổng tiền', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BookingSlotsPage(court: court)));
    await tester.pumpAndSettle();
    await selectTomorrow(tester);

    expect(find.text('Tổng (0 ca)'), findsOneWidget);

    await tester.tap(find.text('06:00-08:00'));
    await tester.pump();

    expect(find.text('Tổng (1 ca)'), findsOneWidget);
    expect(find.text(formatVnd(court.pricePerSlot)), findsOneWidget);
  });

  testWidgets('chọn thêm 1 ca nữa thì tổng tiền nhân đôi, bỏ chọn thì trừ lại', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BookingSlotsPage(court: court)));
    await tester.pumpAndSettle();
    await selectTomorrow(tester);

    await tester.tap(find.text('06:00-08:00'));
    await tester.pump();
    await tester.tap(find.text('08:00-10:00'));
    await tester.pump();

    expect(find.text('Tổng (2 ca)'), findsOneWidget);
    expect(find.text(formatVnd(court.pricePerSlot * 2)), findsOneWidget);

    // Bỏ chọn lại 1 ca — đúng hành vi toggle.
    await tester.tap(find.text('06:00-08:00'));
    await tester.pump();

    expect(find.text('Tổng (1 ca)'), findsOneWidget);
    expect(find.text(formatVnd(court.pricePerSlot)), findsOneWidget);
  });

  testWidgets('ca đã có người đặt thì không chọn được', (tester) async {
    registerFakeCubit(bookedSlots: const ['08:00-10:00']);

    await tester.pumpWidget(MaterialApp(home: BookingSlotsPage(court: court)));
    await tester.pumpAndSettle();
    await selectTomorrow(tester);

    await tester.tap(find.text('08:00-10:00'));
    await tester.pump();

    // Slot bị đánh dấu đã đặt -> tap không có tác dụng, tổng tiền vẫn 0.
    expect(find.text('Tổng (0 ca)'), findsOneWidget);
  });
}

class _FakeBookingRepository implements BookingRepository {
  final List<String> bookedSlots;

  _FakeBookingRepository({this.bookedSlots = const []});

  @override
  Future<Either<Failure, List<String>>> getBookedSlots({
    required String courtId,
    required String date,
  }) async {
    return Right(bookedSlots);
  }

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    required String courtId,
    required String ownerId,
    required String date,
    required String timeSlot,
    required int pricePerSlot,
  }) async {
    return Right(
      BookingEntity(
        id: 'fake-booking',
        userId: 'u1',
        userName: 'Test User',
        courtId: courtId,
        ownerId: ownerId,
        date: date,
        timeSlot: timeSlot,
        pricePerSlot: pricePerSlot,
        status: BookingStatus.pendingPayment,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Stream<List<BookingEntity>> watchBookingsStatus(List<String> bookingIds) =>
      const Stream.empty();

  @override
  Stream<List<BookingEntity>> watchMyBookings(String userId) => const Stream.empty();

  @override
  Future<Either<Failure, void>> cancelBooking({
    required String userId,
    required String bookingId,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<BookingEntity>>> getOwnerCourtBookings(String courtId) async =>
      throw UnimplementedError();

  @override
  Stream<List<BookingEntity>> watchOwnerBookings(String ownerId) => const Stream.empty();

  @override
  Future<Either<Failure, void>> rainCancelBooking({
    required String ownerId,
    required String bookingId,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<BookingEntity>>> getAllTransactions() async =>
      throw UnimplementedError();
}
