import 'package:flutter_test/flutter_test.dart';
import 'package:daily_system/services/import_engine.dart';
import 'dart:io';

void main() {
  testWidgets('Manual Excel Import Test', (WidgetTester tester) async {
    final engine = ImportEngine();
    
    // Check if file exists
    final file = File('Week1_Life_System_Planner.xlsx');
    if (!file.existsSync()) {
      print('File not found at: \${file.absolute.path}');
      return;
    }
    
    final result = await engine.parseFile('Week1_Life_System_Planner.xlsx');
    
    print('--- IMPORT RESULT ---');
    print('Success: ${result.success}');
    if (result.error != null) {
      print('Error: ${result.error}');
    }
    
    print('\n--- LOGS ---');
    for (var log in result.logs) {
      print(log);
    }
    
    if (result.success && result.plan != null) {
      print('\n--- PLAN DETAILS ---');
      print('Identifier: ${result.plan!.weekIdentifier}');
      for (var day in result.plan!.days) {
        print('\nDay: ${day.day}');
        for (var task in day.tasks) {
          print('  - ${task.time}: ${task.label} (${task.task ?? "No desc"}) [Pts: ${task.points}]');
        }
      }
    }
  });
}
