import 'package:flutter_test/flutter_test.dart';
import 'package:daily_system/services/import_engine.dart';
import 'dart:convert';

void main() {
  late ImportEngine engine;

  setUp(() {
    engine = ImportEngine();
  });

  group('ImportEngine JSON Parsing', () {
    test('Canonical Schema', () {
      final jsonStr = jsonEncode({
        "weekIdentifier": "Canonical Week",
        "days": [
          {
            "day": "Monday",
            "tasks": [
              {"label": "Wake Up", "time": "6:00 AM", "points": 1}
            ]
          }
        ]
      });
      final result = engine.parseJson(jsonStr, []);
      expect(result.success, true);
      expect(result.plan?.weekIdentifier, "Canonical Week");
      expect(result.plan?.days[0].tasks[0].label, "Wake Up");
    });

    test('Legacy V2 Format (schedule key)', () {
      final jsonStr = jsonEncode({
        "weekIdentifier": "Legacy Week",
        "schedule": [
          {
            "day": "Tuesday",
            "tasks": [
              {"label": "V2 Task", "time": "9:00 AM"}
            ]
          }
        ]
      });
      final result = engine.parseJson(jsonStr, []);
      expect(result.success, true);
      expect(result.plan?.days[0].day, "Tuesday");
      expect(result.plan?.days[0].tasks[0].label, "V2 Task");
      // Should auto-fill points
      expect(result.plan?.days[0].tasks[0].points, 2);
    });

    test('Flat Task List Format', () {
      final jsonStr = jsonEncode({
        "tasks": [
          {"day": "Wednesday", "label": "Flat 1", "time": "10:00 AM"},
          {"day": "Wednesday", "label": "Flat 2", "time": "11:00 AM"},
          {"day": "Thursday", "label": "Flat 3", "time": "12:00 PM"}
        ]
      });
      final result = engine.parseJson(jsonStr, []);
      expect(result.success, true);
      expect(result.plan?.days.length, 2);
      expect(result.plan?.days.firstWhere((d) => d.day == "Wednesday").tasks.length, 2);
    });

    test('Malformed JSON', () {
      final result = engine.parseJson("{ invalid json }", []);
      expect(result.success, false);
      expect(result.error, contains('JSON Format Error'));
    });

    test('Partial Data (Auto-generation)', () {
      final jsonStr = jsonEncode({
        "days": [
          {
            "day": "Friday",
            "tasks": [
              {"label": "Only Label"} // Missing time and points
            ]
          }
        ]
      });
      final result = engine.parseJson(jsonStr, []);
      expect(result.success, true);
      expect(result.plan?.days[0].tasks[0].time, "TBD");
      expect(result.plan?.days[0].tasks[0].points, 2);
    });
  });
}
