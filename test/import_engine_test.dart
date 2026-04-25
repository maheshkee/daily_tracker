import 'package:flutter_test/flutter_test.dart';
import 'package:daily_system/services/import_engine.dart';
import 'dart:convert';

void main() {
  late ImportEngine engine;

  setUp(() {
    engine = ImportEngine();
  });

  group('ImportEngine JSON', () {
    test('Parse valid JSON', () {
      final jsonStr = jsonEncode({
        "weekIdentifier": "Test Week",
        "days": [
          {
            "day": "Monday",
            "tasks": [
              {"label": "Test Task", "time": "8:00 AM", "points": 2}
            ]
          }
        ]
      });
      final result = engine.parseJson(jsonStr);
      expect(result.success, true);
      expect(result.plan?.weekIdentifier, "Test Week");
      expect(result.plan?.days[0].day, "Monday");
    });

    test('Migrate V1 format', () {
      final jsonStr = jsonEncode({
        "schedule": [
          {
            "day": "Monday",
            "tasks": [{"label": "Old Task", "time": "9:00 AM"}]
          }
        ]
      });
      final result = engine.parseJson(jsonStr);
      expect(result.success, true);
      expect(result.plan?.days[0].tasks[0].label, "Old Task");
    });
  });

  group('ImportEngine CSV', () {
    test('Parse valid CSV with headers', () {
      final csvStr = "day,time,title,details,points\nMonday,8:00 AM,Exercise,Gym session,2";
      final result = engine.parseCsv(csvStr);
      expect(result.success, true);
      expect(result.plan?.days[0].day, "Monday");
      expect(result.plan?.days[0].tasks[0].label, "Exercise");
    });

    test('Fail on missing headers', () {
      final csvStr = "wrong,header\nMonday,8:00 AM";
      final result = engine.parseCsv(csvStr);
      expect(result.success, false);
      expect(result.error, contains('missing required headers'));
    });
  });

  group('ImportEngine TXT', () {
    test('Parse semantic TXT', () {
      final txtStr = "Monday\n8:00 AM - Morning Workout\n9:00 AM Learn Python";
      final result = engine.parseTxt(txtStr);
      expect(result.success, true);
      expect(result.plan?.days[0].day, "Monday");
      expect(result.plan?.days[0].tasks[0].label, "Morning Workout");
      expect(result.plan?.days[0].tasks[1].label, "Learn Python");
    });
  });
}
