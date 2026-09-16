/// Cloudflare Worker xử lý thanh toán VNPay (TASK-019/020/021) — code nguồn
/// nằm ở `workers/hoopspot-payment-worker/`, deploy độc lập với app.
class PaymentWorkerConstants {
  const PaymentWorkerConstants._();

  /// Ghi đè bằng `--dart-define=PAYMENT_WORKER_BASE_URL=...` nếu deploy lại
  /// Worker ở URL khác.
  static const String baseUrl = String.fromEnvironment(
    'PAYMENT_WORKER_BASE_URL',
    defaultValue: 'https://hoopspot-payment-worker.000vmt911.workers.dev',
  );

  static String get createPaymentUrlEndpoint => '$baseUrl/create-payment-url';

  /// TASK-027 — user tự hủy booking đã `confirmed` (áp rule ≥6 tiếng, xem
  /// Worker `handlers/refund.ts`).
  static String get refundEndpoint => '$baseUrl/refund';

  /// TASK-032 — Owner đánh dấu hủy do mưa (sân `isOutdoor`, xem Worker
  /// `handlers/rain-cancel.ts`).
  static String get rainCancelEndpoint => '$baseUrl/rain-cancel';

  /// `vnp_ReturnUrl` — chỉ dùng để WebView nhận biết luồng VNPay đã kết
  /// thúc, không đọc/tin nội dung trang này (xem ghi chú trong Worker).
  static String get returnUrl => '$baseUrl/vnpay-return';
}
