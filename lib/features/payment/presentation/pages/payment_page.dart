import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/payment_worker_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/payment_cubit.dart';

/// TASK-023 — WebView thanh toán VNPay + theo dõi trạng thái booking qua
/// Firestore real-time (thay cho polling định kỳ, đơn giản hơn mà vẫn đúng
/// yêu cầu "không phụ thuộc hoàn toàn vào deep link" của functional-spec).
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

class _PaymentView extends StatelessWidget {
  const _PaymentView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: SafeArea(
        child: BlocBuilder<PaymentCubit, PaymentState>(
          builder: (context, state) {
            if (state is PaymentLoading) {
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
            if (state is PaymentWebViewReady) {
              return _PaymentWebView(
                paymentUrl: state.paymentUrl,
                bookingIds: state.bookingIds,
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

class _PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final List<String> bookingIds;

  const _PaymentWebView({required this.paymentUrl, required this.bookingIds});

  @override
  State<_PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<_PaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigationRequest),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (request.url.startsWith(PaymentWorkerConstants.returnUrl)) {
      context.read<PaymentCubit>().onReturnUrlReached(widget.bookingIds);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
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
