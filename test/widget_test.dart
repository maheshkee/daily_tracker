import 'package:flutter_test/flutter_test.dart';
import 'package:daily_system/main.dart';

void main() {
  testWidgets('Daily System smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DailySystemApp());

    // Verify that the app title is present.
    expect(find.text('Daily System'), findsOneWidget);
    
    // Verify that "TODAY TASKS" header is present.
    expect(find.text('TODAY TASKS'), findsOneWidget);
  });
}
