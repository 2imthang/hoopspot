import 'package:flutter/material.dart';

/// Khớp mockup `docs/screens/dialog reject.png`. Trả về lý do (String) nếu
/// Admin bấm "Gửi từ chối", null nếu bấm Hủy/đóng ngoài dialog. Nút "Gửi từ
/// chối" chỉ bật khi có nội dung — bắt buộc nhập lý do theo spec 4.12.
Future<String?> showRejectReasonDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _RejectReasonDialog(),
  );
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lý do từ chối'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bắt buộc nhập lý do để Chủ sân biết cách khắc phục.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nhập lý do từ chối...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _hasText
              ? () => Navigator.of(context).pop(_controller.text.trim())
              : null,
          child: const Text('Gửi từ chối'),
        ),
      ],
    );
  }
}
