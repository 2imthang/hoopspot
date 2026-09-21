import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../court/domain/entities/court_entity.dart';
import '../../../court/domain/usecases/get_court_by_id_usecase.dart';
import '../../domain/usecases/get_all_transactions_usecase.dart';

part 'transactions_state.dart';

/// TASK-035 — "Giao dịch" (chỉ Admin), khớp mockup `docs/screens/
/// transactions list.png`. Người dùng đã chọn dựng màn này từ `bookings`
/// (không phải collection `payments` thật) — mỗi booking đã rời
/// `pendingPayment` là 1 "giao dịch", vì `payments` chỉ lưu theo lượt
/// thanh toán (có thể gộp nhiều booking, không có tên khách/sân, không
/// track trạng thái hoàn tiền), còn mockup + nhu cầu "tìm theo mã
/// booking/user để hỗ trợ khiếu nại" thực chất là thao tác trên booking.
class TransactionsCubit extends Cubit<TransactionsState> {
  final GetAllTransactionsUseCase getAllTransactionsUseCase;
  final GetCourtByIdUseCase getCourtByIdUseCase;

  final Map<String, CourtEntity> _courts = {};
  List<BookingEntity> _allBookings = const [];
  TransactionFilter _filter = TransactionFilter.all;
  String _query = '';

  TransactionsCubit({
    required this.getAllTransactionsUseCase,
    required this.getCourtByIdUseCase,
  }) : super(const TransactionsLoading());

  Future<void> load() async {
    emit(const TransactionsLoading());
    final result = await getAllTransactionsUseCase(const NoParams());
    await result.fold(
      (failure) async => emit(TransactionsError(failure.message)),
      (bookings) async {
        _allBookings = bookings;

        final missingCourtIds = bookings
            .map((b) => b.courtId)
            .toSet()
            .difference(_courts.keys.toSet());
        for (final courtId in missingCourtIds) {
          final courtResult = await getCourtByIdUseCase(GetCourtByIdParams(courtId));
          courtResult.fold((_) {}, (court) => _courts[courtId] = court);
        }

        _emit();
      },
    );
  }

  void setFilter(TransactionFilter filter) {
    _filter = filter;
    _emit();
  }

  void setQuery(String query) {
    _query = query;
    _emit();
  }

  void _emit() {
    final query = _query.trim().toLowerCase();
    final items = _allBookings
        .map(
          (booking) => TransactionItem(
            booking: booking,
            courtName: _courts[booking.courtId]?.name ?? 'Sân bóng rổ',
            status: _deriveStatus(booking),
          ),
        )
        .where(_matchesFilter)
        .where(
          (item) =>
              query.isEmpty ||
              item.booking.id.toLowerCase().contains(query) ||
              item.booking.userName.toLowerCase().contains(query),
        )
        .toList();
    emit(TransactionsLoaded(items: items, filter: _filter, query: _query));
  }

  bool _matchesFilter(TransactionItem item) {
    switch (_filter) {
      case TransactionFilter.all:
        return true;
      case TransactionFilter.success:
        return item.status == TransactionStatus.success;
      case TransactionFilter.refunded:
        return item.status == TransactionStatus.refunded;
    }
  }

  /// `payments` không track hoàn tiền (nằm trên `bookings`) nên suy trạng
  /// thái "giao dịch" từ `status`/`refundStatus` của booking:
  /// - `confirmed`/`completed` → thành công.
  /// - `cancelled` + `refundStatus == 'refunded'` → đã hoàn tiền.
  /// - `cancelled` + không có `refundStatus`/`cancelReason` nào cả → đây là
  ///   nhánh IPN báo thanh toán thất bại (`vnpay-ipn.ts` chỉ ghi
  ///   `{status: 'cancelled'}` trơn khi `isSuccess == false`, không kèm 2
  ///   field kia) → thất bại thật sự, tiền chưa từng vào.
  /// - `cancelled` với `refundStatus` khác (`not_eligible`/`refund_pending`)
  ///   → tiền ĐÃ được thu thành công lúc thanh toán, chỉ là hủy sau đó
  ///   không được hoàn (hoặc hoàn lỗi) — vẫn tính là giao dịch thành công,
  ///   đúng 3 trạng thái mockup có (không thêm trạng thái thứ 4).
  TransactionStatus _deriveStatus(BookingEntity booking) {
    if (booking.status != BookingStatus.cancelled) return TransactionStatus.success;
    if (booking.refundStatus == 'refunded') return TransactionStatus.refunded;
    if (booking.refundStatus == null && booking.cancelReason == null) {
      return TransactionStatus.failed;
    }
    return TransactionStatus.success;
  }
}
