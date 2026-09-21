import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_spot/features/admin/presentation/widgets/reject_reason_dialog.dart';

/// TASK-038 — "form validation": dialog "Lý do từ chối" (TASK-033, màn Admin
/// duyệt Owner) bắt buộc nhập lý do trước khi cho gửi (functional-spec
/// 4.12: "không cho submit rỗng"). Widget tự chứa, không đụng Firebase/DI
/// nên pump trực tiếp được, không cần fake service nào.
void main() {
  Future<String?> pumpAndOpenDialog(WidgetTester tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showRejectReasonDialog(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('nút "Gửi từ chối" bị vô hiệu khi chưa nhập gì, bật lại khi có nội dung', (
    tester,
  ) async {
    await pumpAndOpenDialog(tester);

    final submitButtonFinder = find.widgetWithText(FilledButton, 'Gửi từ chối');
    expect(tester.widget<FilledButton>(submitButtonFinder).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Giấy phép kinh doanh không hợp lệ');
    await tester.pump();

    expect(tester.widget<FilledButton>(submitButtonFinder).onPressed, isNotNull);
  });

  testWidgets('nhập lý do rồi bấm "Gửi từ chối" trả về đúng nội dung đã nhập', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => result = await showRejectReasonDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ảnh giấy phép bị mờ');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi từ chối'));
    await tester.pumpAndSettle();

    expect(result, 'Ảnh giấy phép bị mờ');
  });

  testWidgets('bấm "Hủy" đóng dialog và trả về null, không bắt buộc phải nhập', (tester) async {
    String? result = 'chưa-đóng';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => result = await showRejectReasonDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
