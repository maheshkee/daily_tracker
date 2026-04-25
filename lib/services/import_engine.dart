import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex;
import '../models/schedule_model.dart';

class ImportResult {
  final WeekPlan? plan;
  final String? error;
  final List<String> logs;
  final bool success;

  ImportResult.success(this.plan, this.logs) : error = null, success = true;
  ImportResult.failure(this.error, this.logs) : plan = null, success = false;
}

class _XlsxIsolateParams {
  final Uint8List bytes;
  final List<String> logs;
  _XlsxIsolateParams(this.bytes, this.logs);
}

class ImportEngine {
  static const String canonicalJsonTemplate = '''
{
  "weekIdentifier": "Week 1",
  "days": [
    {
      "day": "Monday",
      "tasks": [
        {"label": "Wake Up", "time": "6:00 AM", "task": null, "points": 1, "isCompleted": false},
        {"label": "Morning Study", "time": "6:15-7:15", "task": "Math", "points": 2, "isCompleted": false}
      ]
    }
  ]
}''';

  Future<ImportResult> parseFile(String path) async {
    final List<String> logs = [];
    try {
      final file = File(path);
      logs.add('Reading file: ${path.split('/').last}');
      
      if (!await file.exists()) {
        return ImportResult.failure('File not found.', logs);
      }

      final extension = path.split('.').last.toLowerCase();
      logs.add('Detected format: .$extension');

      switch (extension) {
        case 'json':
          return parseJson(await file.readAsString(), logs);
        case 'csv':
          return parseCsv(await file.readAsString(), logs);
        case 'xlsx':
          final bytes = await file.readAsBytes();
          logs.add('Moving to background isolate for heavy XLSX parsing...');
          return await compute(_parseXlsxIsolate, _XlsxIsolateParams(bytes, logs));
        case 'txt':
          return parseTxt(await file.readAsString(), logs);
        default:
          return ImportResult.failure('Unsupported extension: .$extension', logs);
      }
    } catch (e) {
      logs.add('Critical error: $e');
      return ImportResult.failure('System Error: $e', logs);
    }
  }

  static ImportResult _parseXlsxIsolate(_XlsxIsolateParams params) {
    // We need to re-instantiate or use static methods since we are in a new isolate
    return ImportEngine().parseXlsx(params.bytes, params.logs);
  }

  ImportResult parseJson(String content, List<String> logs) {
    try {
      final dynamic data = jsonDecode(content);
      
      if (data is! Map<String, dynamic>) {
        return ImportResult.failure('Invalid JSON: Root must be an object.', logs);
      }

      if (!data.containsKey('days')) {
        if (data.containsKey('schedule')) {
          logs.add('Legacy V2 format detected. Migrating "schedule" to "days"...');
          final List<dynamic> schedule = data['schedule'];
          final List<Map<String, dynamic>> migratedDays = schedule.map((dayData) {
            return {
              'day': dayData['day'],
              'tasks': (dayData['tasks'] as List? ?? []).map((t) {
                return {
                  'label': t['label'] ?? 'Task',
                  'time': t['time'] ?? 'TBD',
                  'task': t['task'],
                  'points': t['points'] ?? 2,
                  'isCompleted': false,
                };
              }).toList(),
            };
          }).toList();
          
          final Map<String, dynamic> migratedData = {
            'weekIdentifier': data['weekIdentifier'] ?? 'Migrated Plan',
            'days': migratedDays,
          };
          return ImportResult.success(WeekPlan.fromJson(migratedData), logs);
        } else {
          return ImportResult.failure('Missing required "days" array.', logs);
        }
      }

      logs.add('Canonical schema detected. Mapping WeekPlan...');
      return ImportResult.success(WeekPlan.fromJson(data), logs);
    } catch (e) {
      return ImportResult.failure('JSON format error: $e', logs);
    }
  }

  ImportResult parseXlsx(Uint8List bytes, List<String> logs) {
    try {
      final excel = ex.Excel.decodeBytes(bytes);
      logs.add('Sheets found: ${excel.tables.keys.join(", ")}');

      if (excel.tables.isEmpty) return ImportResult.failure('Excel is empty.', logs);

      final sheet = excel.tables.values.first;
      logs.add('Parsing sheet: "${sheet.sheetName}" with ${sheet.maxRows} rows.');

      if (sheet.maxRows <= 1) return ImportResult.failure('Sheet has no data rows.', logs);

      Map<String, List<TaskBlock>> daysMap = {};
      
      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        String? val(int col) {
          if (col >= row.length || row[col] == null) return null;
          final cellValue = row[col]!.value;
          if (cellValue == null) return null;
          return cellValue.toString().trim();
        }

        final day = val(0);
        if (day == null || day.isEmpty || day.toLowerCase() == 'day') continue;
        
        if (day.toLowerCase().contains('score') || day.toLowerCase().contains('wake on')) {
          logs.add('Reached scoring legend at row $i. Stopping.');
          break;
        }

        logs.add('Row $i: Identified $day');
        
        daysMap[day] = [
          TaskBlock(label: 'Wake Up', time: val(1) ?? '6:00 AM', points: 1),
          TaskBlock(label: 'Morning Study', time: '6:15-7:15', task: val(2), points: 2),
          TaskBlock(label: 'Job 9-5', time: '9:00 AM - 5:00 PM', task: val(3), points: 0),
          TaskBlock(label: 'Gym', time: val(4) ?? '6:00 PM', points: 2),
          TaskBlock(label: 'Night Study', time: '8:15-9:00', task: val(6), points: 2),
          TaskBlock(label: 'Sleep', time: val(7) ?? '11:00 PM', points: 1),
        ];
      }

      if (daysMap.isEmpty) return ImportResult.failure('No valid weekday rows found.', logs);

      return ImportResult.success(
        WeekPlan(weekIdentifier: 'Excel Import', days: daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)).toList()),
        logs
      );
    } catch (e) {
      return ImportResult.failure('Excel parsing failed: $e', logs);
    }
  }

  ImportResult parseCsv(String content, List<String> logs) {
    try {
      final List<List<dynamic>> rows = csv.decode(content);
      if (rows.isEmpty) return ImportResult.failure('CSV is empty.', logs);
      logs.add('CSV loaded with ${rows.length} rows.');
      return ImportResult.failure('CSV mapping pending refinement. Use JSON or XLSX for now.', logs);
    } catch (e) {
      return ImportResult.failure('CSV error: $e', logs);
    }
  }

  ImportResult parseTxt(String content, List<String> logs) {
    logs.add('Semantic text parsing is best-effort.');
    return ImportResult.failure('TXT format not yet hardened.', logs);
  }
}
