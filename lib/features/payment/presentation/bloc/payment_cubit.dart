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

  /// Gọi khi WebView phát hiện đã chuyển tới `vnp_ReturnUrl` — bắt đầu theo
  /// dõi Firestore thật thay vì tin nội dung trang return.
  void onReturnUrlReached(List<String> bookingIds) {
    emit(PaymentChecking(bookingIds));

    _statusSubscription?.cancel();
    _statusSubscription = watchBookingsStatusUseCase(
      bookingIds,
    ).listen(_handleBookingsUpdate);

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_statusCheckTimeout, () {
      if (state is PaymentChecking) emit(const PaymentResultTimeout());
    });
  }

  void _handleBookingsUpdate(List<BookingEntity> bookings) {
    if (bookings.isEmpty || state is! PaymentChecking) return;

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
