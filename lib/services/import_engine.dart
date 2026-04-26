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
    return ImportEngine().parseXlsx(params.bytes, params.logs);
  }

  ImportResult parseJson(String content, List<String> logs) {
    try {
      final dynamic data = jsonDecode(content);
      if (data is! Map<String, dynamic>) {
        return ImportResult.failure('Invalid JSON: Root must be a JSON object.', logs);
      }

      Map<String, dynamic>? finalData;

      // 1. Detect Schema
      if (data.containsKey('days')) {
        logs.add('JSON: Canonical schema detected ("days" array).');
        finalData = data;
      } else if (data.containsKey('schedule')) {
        logs.add('JSON: Legacy V2 format detected ("schedule" array).');
        finalData = {
          'weekIdentifier': data['weekIdentifier'] ?? 'Migrated Plan',
          'days': data['schedule'],
        };
      } else if (data.containsKey('tasks') && data['tasks'] is List) {
        logs.add('JSON: Flat task list format detected ("tasks" array).');
        final List<dynamic> flatTasks = data['tasks'];
        final Map<String, List<dynamic>> grouped = {};

        for (var t in flatTasks) {
          if (t is Map<String, dynamic>) {
            final day = t['day']?.toString() ?? 'Monday';
            grouped.putIfAbsent(day, () => []).add(t);
          }
        }

        finalData = {
          'weekIdentifier': data['weekIdentifier'] ?? 'Imported Plan',
          'days': grouped.entries.map((e) => {'day': e.key, 'tasks': e.value}).toList(),
        };
      }

      if (finalData == null) {
        return ImportResult.failure(
          'Unknown JSON schema. Must contain "days", "schedule", or a flat "tasks" array.',
          logs
        );
      }

      // 2. Validate & Normalize
      try {
        final List<dynamic> days = finalData['days'] as List? ?? [];
        if (days.isEmpty) return ImportResult.failure('JSON: No days found in schedule.', logs);

        final List<Map<String, dynamic>> normalizedDays = [];

        for (var dayData in days) {
          if (dayData is! Map<String, dynamic>) continue;
          final String dayName = dayData['day']?.toString() ?? 'Unknown Day';
          final List<dynamic> tasks = dayData['tasks'] as List? ?? [];
          
          final List<Map<String, dynamic>> normalizedTasks = [];
          for (var t in tasks) {
            if (t is! Map<String, dynamic>) continue;
            
            // Required minimum check & Auto-generation
            normalizedTasks.add({
              'label': t['label']?.toString() ?? 'Unlabeled Task',
              'time': t['time']?.toString() ?? 'TBD',
              'task': t['task']?.toString(), // optional detail
              'points': int.tryParse(t['points']?.toString() ?? '2') ?? 2,
              'isCompleted': t['isCompleted'] == true,
            });
          }
          
          normalizedDays.add({
            'day': dayName,
            'tasks': normalizedTasks,
          });
        }

        final WeekPlan plan = WeekPlan.fromJson({
          'weekIdentifier': finalData['weekIdentifier'] ?? 'Imported Plan',
          'days': normalizedDays,
        });

        logs.add('JSON Parsing successful: ${plan.days.length} days mapped.');
        return ImportResult.success(plan, logs);
      } catch (e) {
        return ImportResult.failure('JSON Validation Error: $e', logs);
      }
    } catch (e) {
      return ImportResult.failure('JSON Format Error: $e', logs);
    }
  }

  ImportResult parseXlsx(Uint8List bytes, List<String> logs) {
    try {
      final excel = ex.Excel.decodeBytes(bytes);
      logs.add('XLSX: Sheets found: ${excel.tables.keys.join(", ")}');

      if (excel.tables.isEmpty) return ImportResult.failure('Excel is empty.', logs);

      final Map<String, List<DayPlan>> allSheetsPlans = {};
      final List<DayPlan> allDayPlans = [];

      for (var table in excel.tables.values) {
        logs.add('--- Processing Sheet: "${table.sheetName}" ---');
        if (table.maxRows <= 1) {
          logs.add('Sheet "${table.sheetName}" is empty or has only one row. Skipping.');
          continue;
        }

        // 1. Column Auto-Detection (Header Search)
        int dayCol = -1, labelCol = -1, timeCol = -1, taskCol = -1, pointsCol = -1;
        int headerRowIndex = -1;

        for (int i = 0; i < table.maxRows && i < 5; i++) {
          final row = table.rows[i];
          for (int j = 0; j < row.length; j++) {
            final val = row[j]?.value?.toString().toLowerCase() ?? '';
            if (val.contains('day')) dayCol = j;
            if (val.contains('label') || val.contains('activity') || val.contains('title')) labelCol = j;
            if (val.contains('time') || val.contains('schedule')) timeCol = j;
            if (val.contains('task') || val.contains('description') || val.contains('detail')) taskCol = j;
            if (val.contains('point') || val.contains('score')) pointsCol = j;
          }
          if (dayCol != -1 && (labelCol != -1 || timeCol != -1)) {
            headerRowIndex = i;
            logs.add('Header detected at row $i: Day=$dayCol, Label=$labelCol, Time=$timeCol, Task=$taskCol, Points=$pointsCol');
            break;
          }
        }

        // Fallback to hardcoded defaults if no header found
        if (headerRowIndex == -1) {
          logs.add('Warning: No clear header found. Using legacy template mapping.');
          dayCol = 0; timeCol = 1; labelCol = 2; taskCol = 3; pointsCol = 4;
          headerRowIndex = 0;
        }

        final Map<String, List<TaskBlock>> daysMap = {};

        // 2. Iterate Rows
        for (var i = headerRowIndex + 1; i < table.maxRows; i++) {
          if (i >= table.rows.length) break;
          final row = table.rows[i];
          if (row == null || row.isEmpty) continue;

          // Helper for cell extraction with merged cell support & format detection
          String? getVal(int col) {
            if (col < 0 || col >= row.length) return null;
            var cell = row[col];
            
            // Handle Merged Cells (Excel package helper)
            if (cell == null || cell.value == null) {
              // Check if this coordinate is part of a merged range
              for (var range in table.spannedItems) {
                if (i >= range.firstRow && i <= range.lastRow && 
                    col >= range.firstCol && col <= range.lastCol) {
                  cell = table.rows[range.firstRow][range.firstCol];
                  break;
                }
              }
            }

            final cellValue = cell?.value;
            if (cellValue == null) return null;

            // Format Detection (Date/Time Serial Numbers)
            if (cellValue is double || cellValue is int) {
              // Crude check for Excel date serials (e.g. 44000+)
              double num = double.parse(cellValue.toString());
              if (num > 30000 && num < 60000 && (col == timeCol)) {
                // If it's in a time column and looks like a date serial
                // Note: Simple conversion, wouldn't handle complex formats without intl
                logs.add('Detected numeric date serial at [$i, $col]: $num');
              }
            }

            return cellValue.toString().trim().isEmpty ? null : cellValue.toString().trim();
          }

          final dayName = getVal(dayCol);
          if (dayName == null || dayName.toLowerCase() == 'day') continue;

          // Improved Summary Section Detection
          final lowerDay = dayName.toLowerCase();
          if (lowerDay.contains('total') || lowerDay.contains('score') || 
              lowerDay.contains('notes') || lowerDay.contains('summary') ||
              lowerDay.contains('week') || lowerDay.length > 20) {
            logs.add('Reached summary/notes at row $i ("$dayName"). Stopping sheet.');
            break;
          }

          // Build Task
          final task = TaskBlock(
            label: getVal(labelCol) ?? 'Activity',
            time: getVal(timeCol) ?? 'TBD',
            task: getVal(taskCol),
            points: int.tryParse(getVal(pointsCol) ?? '2') ?? 2,
          );

          daysMap.putIfAbsent(dayName, () => []).add(task);
        }

        if (daysMap.isNotEmpty) {
          allDayPlans.addAll(daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)));
          logs.add('Sheet "${table.sheetName}": Mapped ${daysMap.length} days.');
        }
      }

      if (allDayPlans.isEmpty) return ImportResult.failure('No valid weekday data found in any sheet.', logs);

      return ImportResult.success(
        WeekPlan(
          weekIdentifier: 'Excel Master Import', 
          days: allDayPlans
        ),
        logs
      );
    } catch (e, stackTrace) {
      logs.add('Critical Excel Error: $e');
      logs.add('Stack trace: $stackTrace');
      return ImportResult.failure('Excel parsing failed: $e', logs);
    }
  }

  ImportResult parseCsv(String content, List<String> logs) {
    try {
      logs.add('CSV: Analyzing content structure...');
      
      // 1. Detect Delimiter (Comma vs Semicolon)
      final firstLine = content.split('\n').first;
      final commaCount = firstLine.split(',').length;
      final semiCount = firstLine.split(';').length;
      final delimiter = semiCount > commaCount ? ';' : ',';
      logs.add('CSV: Detected delimiter: "$delimiter"');

      // 2. Decode CSV
      final List<List<dynamic>> rows = CsvToListConverter(
        fieldDelimiter: delimiter,
        shouldParseNumbers: true,
      ).convert(content);

      if (rows.isEmpty) return ImportResult.failure('CSV is empty.', logs);
      logs.add('CSV: Loaded ${rows.length} rows.');

      // 3. Column Auto-Detection (Header Search)
      int dayCol = -1, labelCol = -1, timeCol = -1, taskCol = -1, pointsCol = -1;
      int headerRowIndex = -1;

      for (int i = 0; i < rows.length && i < 5; i++) {
        final row = rows[i];
        for (int j = 0; j < row.length; j++) {
          final val = row[j]?.toString().toLowerCase() ?? '';
          if (val.contains('day')) dayCol = j;
          if (val.contains('label') || val.contains('activity') || val.contains('title')) labelCol = j;
          if (val.contains('time') || val.contains('schedule')) timeCol = j;
          if (val.contains('task') || val.contains('description') || val.contains('detail')) taskCol = j;
          if (val.contains('point') || val.contains('score')) pointsCol = j;
        }
        if (dayCol != -1 && (labelCol != -1 || timeCol != -1)) {
          headerRowIndex = i;
          logs.add('CSV: Header found at row $i: Day=$dayCol, Label=$labelCol, Time=$timeCol');
          break;
        }
      }

      if (headerRowIndex == -1) {
        logs.add('CSV: Warning: No header found. Using default mapping [Day, Time, Label, Task, Points].');
        dayCol = 0; timeCol = 1; labelCol = 2; taskCol = 3; pointsCol = 4;
        headerRowIndex = -1; // Parse from row 0
      }

      final Map<String, List<TaskBlock>> daysMap = {};

      // 4. Parse Data Rows
      for (int i = headerRowIndex + 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        String? val(int col) {
          if (col < 0 || col >= row.length) return null;
          final v = row[col]?.toString().trim();
          return (v == null || v.isEmpty) ? null : v;
        }

        final dayName = val(dayCol);
        if (dayName == null || dayName.toLowerCase() == 'day') {
          continue;
        }

        // Summary detection
        final lowerDay = dayName.toLowerCase();
        if (lowerDay.contains('total') || lowerDay.contains('score') || 
            lowerDay.contains('notes') || lowerDay.contains('summary') ||
            lowerDay.length > 20) {
          logs.add('CSV: Reached summary section at row $i. Stopping.');
          break;
        }

        final task = TaskBlock(
          label: val(labelCol) ?? 'Activity',
          time: val(timeCol) ?? 'TBD',
          task: val(taskCol),
          points: int.tryParse(val(pointsCol) ?? '2') ?? 2,
        );

        daysMap.putIfAbsent(dayName, () => []).add(task);
      }

      if (daysMap.isEmpty) return ImportResult.failure('CSV: No valid weekday rows identified.', logs);

      final weekPlan = WeekPlan(
        weekIdentifier: 'CSV Import',
        days: daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)).toList(),
      );

      logs.add('CSV: Successfully parsed ${daysMap.length} days.');
      return ImportResult.success(weekPlan, logs);
    } catch (e) {
      logs.add('CSV Parsing Error: $e');
      return ImportResult.failure('CSV parse failed: $e', logs);
    }
  }

  ImportResult parseTxt(String content, List<String> logs) {
    try {
      logs.add('Starting TXT parsing...');
      final lines = content.split('\n');
      final Map<String, List<TaskBlock>> daysMap = {};

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || !line.contains(':')) continue;

        try {
          final parts = line.split(':');
          final day = parts[0].trim();
          final taskData = parts[1].trim();

          if (taskData.isEmpty) continue;

          final taskParts = taskData.split('|');
          final label = taskParts.isNotEmpty ? taskParts[0].trim() : 'Task';
          final time = taskParts.length > 1 ? taskParts[1].trim() : 'TBD';
          final taskDesc = taskParts.length > 2 ? taskParts[2].trim() : null;
          final points = taskParts.length > 3 ? int.tryParse(taskParts[3].trim()) ?? 0 : 0;

          final task = TaskBlock(
            label: label,
            time: time,
            task: taskDesc,
            points: points,
          );

          daysMap.putIfAbsent(day, () => []).add(task);
          logs.add('Parsed task for $day: $label ($time)');
        } catch (e) {
          logs.add('Skipping malformed line: $line');
        }
      }

      if (daysMap.isEmpty) {
        return ImportResult.failure('No valid tasks found in TXT file.', logs);
      }

      final weekPlan = WeekPlan(
        weekIdentifier: 'TXT Import',
        days: daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)).toList(),
      );

      logs.add('Successfully parsed TXT plan with ${daysMap.length} days.');
      return ImportResult.success(weekPlan, logs);
    } catch (e) {
      logs.add('TXT Parsing Error: $e');
      return ImportResult.failure('Failed to parse TXT: $e', logs);
    }
  }
}
