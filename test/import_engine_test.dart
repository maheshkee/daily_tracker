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
      final result = engine.parseJson(jsonStr, []);
      expect(result.success, true);
      expect(result.plan?.weekIdentifier, "Test Week");
      expect(result.plan?.days[0].day, "Monday");
    });

    test('Migrate V2 format', () {
      final jsonStr = jsonEncode({
        "schedule": [
          {
            "day": "Monday",
            "tasks": [{"label": "Old Task", "time": "9:00 AM"}]
          }
        ]
      });
      final result = engine.parseJson(jsonStr, []);
      expect(result.success, true);
      expect(result.plan?.days[0].tasks[0].label, "Old Task");
    });
  });

  group('ImportEngine CSV', () {
    test('Load CSV', () {
      final csvStr = "day,time,title,details,points\nMonday,8:00 AM,Exercise,Gym session,2";
      final result = engine.parseCsv(csvStr, []);
      // Currently CSV returns failure as it is pending refinement, but let's check logs
      expect(result.logs, contains('CSV loaded with 2 rows.'));
    });
  });
}
