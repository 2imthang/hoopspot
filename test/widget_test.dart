import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_spot/app.dart';

void main() {
  testWidgets('HoopSpotApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const HoopSpotApp());

    expect(find.text('HoopSpot — project structure ready'), findsOneWidget);
  });
}
