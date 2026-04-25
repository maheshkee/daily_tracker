import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_system/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Daily System smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const DailySystemApp());
    
    // Wait for the async initialization to complete
    await tester.pumpAndSettle();

    // Verify that the app title is present.
    expect(find.text('Daily System'), findsOneWidget);
    
    // Verify that "TODAY TASKS" header is present.
    expect(find.text('TODAY TASKS'), findsOneWidget);
  });
}
