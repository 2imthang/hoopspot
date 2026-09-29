import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../booking/domain/usecases/watch_bookings_status_usecase.dart';
import '../../domain/usecases/create_payment_url_usecase.dart';

part 'payment_state.dart';

/// Bao nhiêu lâu chờ IPN cập nhật trước khi báo "chưa chắc chắn" thay vì
/// bắt user chờ vô thời hạn — xem [PaymentResultTimeout].
const _statusCheckTimeout = Duration(seconds: 30);

class PaymentCubit extends Cubit<PaymentState> {
  final CreatePaymentUrlUseCase createPaymentUrlUseCase;
  final WatchBookingsStatusUseCase watchBookingsStatusUseCase;

  StreamSubscription<List<BookingEntity>>? _statusSubscription;
  Timer? _timeoutTimer;

  PaymentCubit({
    required this.createPaymentUrlUseCase,
    required this.watchBookingsStatusUseCase,
  }) : super(const PaymentLoading());

  Future<void> start({
    required String userId,
    required List<String> bookingIds,
  }) async {
    emit(const PaymentLoading());
    final result = await createPaymentUrlUseCase(
      CreatePaymentUrlParams(userId: userId, bookingIds: bookingIds),
    );
    result.fold(
      (failure) => emit(PaymentError(failure.message)),
      (paymentUrl) => emit(
        PaymentWebViewReady(
          paymentUrl: paymentUrl.paymentUrl,
          bookingIds: bookingIds,
        ),
      ),
    );
  }

  /// Gọi ngay sau khi mở trình duyệt ngoài (Chrome) — bắt đầu theo dõi
  /// Firestore thật ngay từ lúc này (không chờ user quay lại app), vì IPN
  /// có thể tới bất cứ lúc nào phía server, độc lập với việc app có đang ở
  /// foreground hay không.
  void launchedBrowser(List<String> bookingIds) {
    emit(PaymentWaitingInBrowser(bookingIds));

    _statusSubscription?.cancel();
    _statusSubscription = watchBookingsStatusUseCase(
      bookingIds,
    ).listen(_handleBookingsUpdate);
  }

  /// Gọi khi app quay lại foreground sau khi user rời sang trình duyệt
  /// ngoài để thanh toán — đây là lúc bắt đầu đếm 30s chờ IPN, tương đương
  /// mốc "đã chuyển tới vnp_ReturnUrl" trong luồng WebView cũ.
  void onReturnedFromBrowser() {
    final current = state;
    if (current is! PaymentWaitingInBrowser) return;

    emit(PaymentChecking(current.bookingIds));

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_statusCheckTimeout, () {
      if (state is PaymentChecking) emit(const PaymentResultTimeout());
    });
  }

  /// Không mở được trình duyệt (máy không có app trình duyệt nào xử lý được
  /// link https, rất hiếm gặp).
  void browserLaunchFailed() {
    emit(
      const PaymentError(
        'Không mở được trình duyệt để thanh toán. Kiểm tra máy có cài trình duyệt (Chrome) không.',
      ),
    );
  }

  void _handleBookingsUpdate(List<BookingEntity> bookings) {
    if (bookings.isEmpty) return;
    if (state is! PaymentChecking && state is! PaymentWaitingInBrowser) return;

    final anyCancelled = bookings.any(
      (b) => b.status == BookingStatus.cancelled,
    );
    final allConfirmed = bookings.every(
      (b) => b.status == BookingStatus.confirmed,
    );

    if (anyCancelled) {
      _finish(const PaymentResultFailed());
    } else if (allConfirmed) {
      _finish(const PaymentResultSuccess());
    }
    // Còn lại vẫn `pendingPayment` — IPN chưa tới, tiếp tục chờ.
  }

  void _finish(PaymentState result) {
    _timeoutTimer?.cancel();
    emit(result);
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _timeoutTimer?.cancel();
    return super.close();
  }
}
