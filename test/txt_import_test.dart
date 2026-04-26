import 'package:flutter_test/flutter_test.dart';
import 'package:daily_system/services/import_engine.dart';

void main() {
  late ImportEngine engine;

  setUp(() {
    engine = ImportEngine();
  });

  group('ImportEngine TXT Parsing', () {
    test('Standard Format', () {
      final content = '''
Monday: Wake Up | 6:00 AM | Morning routine | 1
Monday: Study | 7:00 AM | Flutter | 2
Tuesday: Gym | 6:00 PM | Leg Day | 2
''';
      final result = engine.parseTxt(content, []);
      expect(result.success, true);
      expect(result.plan?.days.length, 2);
      expect(result.plan?.days.firstWhere((d) => d.day == "Monday").tasks.length, 2);
      expect(result.plan?.days[0].tasks[0].label, "Wake Up");
    });

    test('Malformed Lines & Extra Whitespace', () {
      final content = '''
   Monday :   Space Task   | 8:00 AM | Detail | 3   
Invalid Line No Colon
Wednesday:  | 9:00 AM | Empty Label | 1
''';
      final result = engine.parseTxt(content, []);
      expect(result.success, true);
      expect(result.plan?.days.length, 2); // Monday and Wednesday
      final monday = result.plan?.days.firstWhere((d) => d.day == "Monday");
      expect(monday?.tasks[0].label, "Space Task");
    });

    test('Fallback Defaults', () {
      final content = "Sunday: Minimal Task";
      final result = engine.parseTxt(content, []);
      expect(result.success, true);
      final task = result.plan?.days[0].tasks[0];
      expect(task?.label, "Minimal Task");
      expect(task?.time, "TBD");
      expect(task?.points, 0);
    });

    test('Empty Content', () {
      final result = engine.parseTxt("", []);
      expect(result.success, false);
      expect(result.error, contains('No valid tasks found'));
    });
  });
}
