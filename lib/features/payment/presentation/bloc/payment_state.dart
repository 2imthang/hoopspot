part of 'payment_cubit.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

/// Đang gọi Worker để lấy URL thanh toán.
class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Có URL rồi — hiển thị WebView cho user nhập thẻ.
class PaymentWebViewReady extends PaymentState {
  final String paymentUrl;
  final List<String> bookingIds;

  const PaymentWebViewReady({
    required this.paymentUrl,
    required this.bookingIds,
  });

  @override
  List<Object?> get props => [paymentUrl, bookingIds];
}

/// WebView đã chuyển tới `vnp_ReturnUrl` — không tin nội dung đó, đang chờ
/// IPN (nguồn thật) cập nhật `booking.status` qua Firestore real-time.
class PaymentChecking extends PaymentState {
  final List<String> bookingIds;

  const PaymentChecking(this.bookingIds);

  @override
  List<Object?> get props => [bookingIds];
}

class PaymentResultSuccess extends PaymentState {
  const PaymentResultSuccess();
}

class PaymentResultFailed extends PaymentState {
  const PaymentResultFailed();
}

/// Quá thời gian chờ mà vẫn chưa thấy IPN cập nhật — không có nghĩa là thất
/// bại, chỉ là chưa chắc chắn (VNPay/IPN có thể chậm). Booking History
/// (TASK-027) sẽ luôn phản ánh đúng trạng thái sau này.
class PaymentResultTimeout extends PaymentState {
  const PaymentResultTimeout();
}
