import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/payment_cubit.dart';

/// TASK-023 — mở trang thanh toán VNPay bằng trình duyệt ngoài (Chrome) +
/// theo dõi trạng thái booking qua Firestore real-time (thay cho polling
/// định kỳ, đơn giản hơn mà vẫn đúng yêu cầu "không phụ thuộc hoàn toàn vào
/// deep link" của functional-spec).
///
/// Trước đây dùng WebView nhúng (webview_flutter), nhưng phát hiện một số
/// máy thật có "Android System WebView" không bắt tay SSL được với
/// sandbox.vnpayment.vn (net_error -202, ERR_CERT_AUTHORITY_INVALID) dù
/// Chrome thật trên cùng máy load domain đó bình thường — nên đổi sang mở
/// thẳng bằng trình duyệt ngoài để tránh phụ thuộc vào WebView riêng của
/// từng máy/hãng.
class PaymentPage extends StatelessWidget {
  final String userId;
  final List<String> bookingIds;

  const PaymentPage({
    super.key,
    required this.userId,
    required this.bookingIds,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<PaymentCubit>()..start(userId: userId, bookingIds: bookingIds),
      child: const _PaymentView(),
    );
  }
}

class _PaymentView extends StatefulWidget {
  const _PaymentView();

  @override
  State<_PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<_PaymentView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User quay lại app sau khi thanh toán trên trình duyệt ngoài — nếu
    // đúng lúc đang chờ (PaymentWaitingInBrowser) thì bắt đầu đếm time-out
    // chờ IPN; nếu không phải thì cubit tự bỏ qua, gọi vô hại.
    if (state == AppLifecycleState.resumed) {
      context.read<PaymentCubit>().onReturnedFromBrowser();
    }
  }

  Future<void> _openBrowser(PaymentWebViewReady state) async {
    final cubit = context.read<PaymentCubit>();
    try {
      final launched = await launchUrl(
        Uri.parse(state.paymentUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        cubit.browserLaunchFailed();
        return;
      }
      cubit.launchedBrowser(state.bookingIds);
    } catch (_) {
      cubit.browserLaunchFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: SafeArea(
        child: BlocConsumer<PaymentCubit, PaymentState>(
          listener: (context, state) {
            if (state is PaymentWebViewReady) _openBrowser(state);
          },
          builder: (context, state) {
            if (state is PaymentLoading || state is PaymentWebViewReady) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PaymentError) {
              return _MessageView(
                icon: Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                title: 'Không tạo được URL thanh toán',
                message: state.message,
                showBackButton: true,
              );
            }
            if (state is PaymentWaitingInBrowser) {
              return const _MessageView(
                icon: Icons.open_in_new,
                color: null,
                title: 'Đang chờ thanh toán',
                message:
                    'Hoàn tất thanh toán trên trình duyệt vừa mở, sau đó quay lại app này.',
                showLoading: true,
              );
            }
            if (state is PaymentChecking) {
              return const _MessageView(
                icon: null,
                color: null,
                title: 'Đang xác nhận thanh toán…',
                message: 'Vui lòng đợi trong giây lát, đừng đóng app.',
                showLoading: true,
              );
            }
            if (state is PaymentResultSuccess) {
              return _MessageView(
                icon: Icons.check_circle,
                color: AppColors.successFg(context),
                title: 'Thanh toán thành công',
                message: 'Sân của bạn đã được xác nhận đặt.',
                showBackButton: true,
              );
            }
            if (state is PaymentResultFailed) {
              return _MessageView(
                icon: Icons.cancel,
                color: Theme.of(context).colorScheme.error,
                title: 'Thanh toán thất bại',
                message: 'Giao dịch không thành công, khung giờ đã được nhả lại.',
                showBackButton: true,
              );
            }
            // PaymentResultTimeout
            return _MessageView(
              icon: Icons.hourglass_top,
              color: AppColors.warningFg(context),
              title: 'Chưa có kết quả',
              message:
                  'Chưa nhận được xác nhận từ VNPay. Kiểm tra lại trạng thái đặt sân trong ít phút nữa.',
              showBackButton: true,
            );
          },
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData? icon;
  final Color? color;
  final String title;
  final String message;
  final bool showBackButton;
  final bool showLoading;

  const _MessageView({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.showBackButton = false,
    this.showLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLoading)
              const CircularProgressIndicator()
            else if (icon != null)
              Icon(icon, size: 64, color: color),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (showBackButton) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Về trang chủ'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
