import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/comment_filter.dart';
import '../../domain/usecases/create_review_usecase.dart';

/// TASK-029 — khớp mockup `docs/screens/white review.png`. Chỉ mở được từ
/// Booking History, cho đúng 1 booking `confirmed` đã qua giờ chơi và chưa
/// được đánh giá (xem `BookingHistoryCubit`/`_BookingCard`).
class WriteReviewPage extends StatefulWidget {
  final String bookingId;
  final String courtId;
  final String courtName;
  final String date;
  final String timeSlot;

  const WriteReviewPage({
    super.key,
    required this.bookingId,
    required this.courtId,
    required this.courtName,
    required this.date,
    required this.timeSlot,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _errorMessage = 'Vui lòng chọn số sao đánh giá');
      return;
    }
    final comment = _commentController.text.trim();
    if (containsBlacklistedWord(comment)) {
      setState(() => _errorMessage = 'Nhận xét chứa từ ngữ không phù hợp, vui lòng chỉnh lại');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final result = await sl<CreateReviewUseCase>()(
      CreateReviewParams(
        bookingId: widget.bookingId,
        courtId: widget.courtId,
        rating: _rating,
        comment: comment,
      ),
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _submitting = false;
        _errorMessage = failure.message;
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  String _formatDate(String yyyyMMdd) {
    final parts = yyyyMMdd.split('-');
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá sân')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sân ${widget.courtName}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.timeSlot}, ${_formatDate(widget.date)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Bạn đánh giá sân này bao nhiêu sao?',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      iconSize: 36,
                      onPressed: () => setState(() {
                        _rating = star;
                        _errorMessage = null;
                      }),
                      icon: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Nhận xét của bạn', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLength: 500,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Chia sẻ trải nghiệm của bạn về sân, chất lượng mặt sân, thái độ chủ sân...',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gửi đánh giá'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
