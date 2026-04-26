import 'package:flutter_test/flutter_test.dart';
import 'package:daily_system/services/import_engine.dart';

void main() {
  late ImportEngine engine;

  setUp(() {
    engine = ImportEngine();
  });

  group('ImportEngine CSV Parsing', () {
    test('Comma Delimited with Headers', () {
      final content = '''
Day,Time,Label,Task,Points
Monday,6:00 AM,Wake Up,Routine,1
Tuesday,7:00 AM,Work,Coding,0
''';
      final result = engine.parseCsv(content, []);
      expect(result.success, true);
      expect(result.plan?.days.length, 2);
      expect(result.plan?.days[0].day, "Monday");
      expect(result.plan?.days[0].tasks[0].label, "Wake Up");
    });

    test('Semicolon Delimited', () {
      final content = '''
Day;Time;Label;Task;Points
Monday;8:00 AM;Study;Dart;2
''';
      final result = engine.parseCsv(content, []);
      expect(result.success, true);
      expect(result.plan?.days[0].tasks[0].label, "Study");
    });

    test('Quoted Fields', () {
      final content = '''
"Day","Time","Label","Task","Points"
"Monday","6:00 PM","Gym","Leg Day, heavy",2
''';
      final result = engine.parseCsv(content, []);
      expect(result.success, true);
      expect(result.plan?.days[0].tasks[0].task, "Leg Day, heavy");
    });

    test('No Header (Fallback)', () {
      final content = "Monday,9:00 AM,Fallback Task,Desc,5";
      final result = engine.parseCsv(content, []);
      expect(result.success, true);
      expect(result.plan?.days[0].tasks[0].label, "Fallback Task");
    });

    test('Summary Row Detection', () {
      final content = '''
Day,Time,Label,Task,Points
Monday,8:00 AM,Task 1,Desc,1
Total Score,10,,,
''';
      final result = engine.parseCsv(content, []);
      expect(result.success, true);
      expect(result.plan?.days.length, 1);
      expect(result.plan?.days[0].tasks.length, 1);
    });
  });
}
