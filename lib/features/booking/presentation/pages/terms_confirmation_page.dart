import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../court/domain/entities/court_entity.dart';
import '../../../payment/presentation/pages/payment_page.dart';

/// TASK-024 — chặn giữa lúc giữ slot xong (TASK-018) và màn Thanh toán
/// (TASK-023): user phải đọc chính sách hủy/hoàn tiền + thời gian giữ slot,
/// tích "đồng ý" mới bấm được "Tiếp tục thanh toán" (functional-spec 4.5).
class TermsConfirmationPage extends StatefulWidget {
  final CourtEntity court;
  final DateTime date;
  final List<String> timeSlots;
  final List<String> bookingIds;
  final String userId;

  const TermsConfirmationPage({
    super.key,
    required this.court,
    required this.date,
    required this.timeSlots,
    required this.bookingIds,
    required this.userId,
  });

  @override
  State<TermsConfirmationPage> createState() => _TermsConfirmationPageState();
}

class _TermsConfirmationPageState extends State<TermsConfirmationPage> {
  bool _agreed = false;

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          userId: widget.userId,
          bookingIds: widget.bookingIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.court.pricePerSlot * widget.timeSlots.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận điều khoản')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _BookingSummaryCard(
                    court: widget.court,
                    date: widget.date,
                    timeSlots: widget.timeSlots,
                    totalAmount: totalAmount,
                  ),
                  const SizedBox(height: 16),
                  _PolicyCard(isOutdoor: widget.court.isOutdoor),
                ],
              ),
            ),
            _BottomAgreeBar(
              agreed: _agreed,
              onChanged: (value) => setState(() => _agreed = value ?? false),
              onContinue: _agreed ? _continue : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  final CourtEntity court;
  final DateTime date;
  final List<String> timeSlots;
  final int totalAmount;

  const _BookingSummaryCard({
    required this.court,
    required this.date,
    required this.timeSlots,
    required this.totalAmount,
  });

  String get _formattedDate =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sân ${court.name}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Ngày', value: _formattedDate),
          _SummaryRow(label: 'Giờ', value: timeSlots.join(', ')),
          _SummaryRow(
            label: 'Tổng tiền',
            value: formatVnd(totalAmount),
            valueColor: theme.colorScheme.primary,
            valueBold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: valueBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final bool isOutdoor;

  const _PolicyCard({required this.isOutdoor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bullets = [
      'Hủy trước giờ chơi ≥ 6 tiếng: hoàn 100% tiền đã thanh toán.',
      'Hủy trong vòng 6 tiếng trước giờ chơi: không hoàn tiền.',
      if (isOutdoor)
        'Nếu chủ sân báo hủy do mưa (sân ngoài trời): hoàn tiền tự động 100%, không phụ thuộc thời điểm.',
      'Slot đặt được giữ trong 10 phút — quá thời gian này chưa thanh toán sẽ tự động hủy.',
      'Vui lòng có mặt đúng giờ, trễ quá 15 phút sân có thể bị hủy.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chính sách',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: theme.textTheme.bodyMedium),
                  Expanded(
                    child: Text(bullet, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomAgreeBar extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onContinue;

  const _BottomAgreeBar({
    required this.agreed,
    required this.onChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => onChanged(!agreed),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Checkbox(value: agreed, onChanged: onChanged),
                    Expanded(
                      child: Text(
                        'Tôi đã đọc và đồng ý với điều khoản đặt sân, chính sách hủy & hoàn tiền.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                child: const Text('Tiếp tục thanh toán'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
