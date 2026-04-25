import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex;
import '../models/schedule_model.dart';

class ImportResult {
  final WeekPlan? plan;
  final String? error;
  final bool success;

  ImportResult.success(this.plan) : error = null, success = true;
  ImportResult.failure(this.error) : plan = null, success = false;
}

class ImportEngine {
  Future<ImportResult> parseFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return ImportResult.failure('File does not exist: $path');
      }

      final extension = path.split('.').last.toLowerCase();
      
      switch (extension) {
        case 'json':
          return parseJson(await file.readAsString());
        case 'csv':
          return parseCsv(await file.readAsString());
        case 'xlsx':
          return parseXlsx(await file.readAsBytes());
        case 'txt':
          return parseTxt(await file.readAsString());
        default:
          return ImportResult.failure('Unsupported format: .$extension. Only JSON, CSV, XLSX, and TXT are supported.');
      }
    } catch (e) {
      return ImportResult.failure('Unexpected error reading file: $e');
    }
  }

  ImportResult parseJson(String content) {
    try {
      final data = jsonDecode(content);
      if (data is! Map<String, dynamic>) {
        return ImportResult.failure('Invalid JSON: Root must be an object.');
      }

      if (!data.containsKey('days')) {
        if (data.containsKey('schedule')) {
          final migratedDays = (data['schedule'] as List).map((dayData) {
            return {
              'day': dayData['day'],
              'tasks': (dayData['tasks'] ?? []).map((t) => {
                'label': t['label'],
                'time': t['time'],
                'task': t['task'],
                'points': t['points'] ?? 0,
                'isCompleted': t['isCompleted'] ?? false,
              }).toList(),
            };
          }).toList();
          data['days'] = migratedDays;
        } else {
          return ImportResult.failure('Invalid JSON: Missing "days" array.');
        }
      }

      return ImportResult.success(WeekPlan.fromJson(data));
    } catch (e) {
      return ImportResult.failure('JSON Parse Error: $e');
    }
  }

  ImportResult parseCsv(String content) {
    try {
      final List<List<dynamic>> rows = csv.decode(content);
      if (rows.isEmpty) return ImportResult.failure('CSV is empty');

      Map<String, List<TaskBlock>> daysMap = {};
      int dayCol = -1, timeCol = -1, titleCol = -1, detailsCol = -1, pointsCol = -1;
      
      final header = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();
      dayCol = header.indexOf('day');
      timeCol = header.indexOf('time');
      titleCol = header.indexOf('title');
      detailsCol = header.indexOf('details');
      pointsCol = header.indexOf('points');

      if (dayCol == -1 || timeCol == -1 || titleCol == -1) {
        return ImportResult.failure('CSV missing required headers. Expected: day, time, title, [details, points]');
      }

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length <= dayCol) continue;
        final dayName = row[dayCol].toString().trim();
        if (dayName.isEmpty) continue;
        daysMap[dayName] ??= [];
        daysMap[dayName]!.add(TaskBlock(
          label: row[titleCol].toString().trim(),
          time: row[timeCol].toString().trim(),
          task: (detailsCol != -1 && detailsCol < row.length) ? row[detailsCol].toString().trim() : null,
          points: (pointsCol != -1 && pointsCol < row.length) ? int.tryParse(row[pointsCol].toString()) ?? 0 : 0,
        ));
      }

      if (daysMap.isEmpty) return ImportResult.failure('No valid schedule rows found in CSV.');
      return ImportResult.success(WeekPlan(
        weekIdentifier: 'Imported CSV',
        days: daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)).toList(),
      ));
    } catch (e) {
      return ImportResult.failure('CSV Processing Error: $e');
    }
  }

  ImportResult parseXlsx(Uint8List bytes) {
    try {
      final excel = ex.Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) return ImportResult.failure('Excel file has no sheets.');
      Map<String, List<TaskBlock>> daysMap = {};
      final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      bool foundSheets = false;

      for (var tableName in excel.tables.keys) {
        if (weekdays.contains(tableName.toLowerCase())) {
          foundSheets = true;
          final sheet = excel.tables[tableName]!;
          final dayName = tableName[0].toUpperCase() + tableName.substring(1).toLowerCase();
          daysMap[dayName] = _parseSheetToTasks(sheet);
        }
      }

      if (!foundSheets) {
        final sheet = excel.tables.values.first;
        int dayCol = -1;
        if (sheet.maxRows > 0) {
          final firstRow = sheet.rows[0];
          for (var i = 0; i < firstRow.length; i++) {
            if (firstRow[i]?.value.toString().toLowerCase().trim() == 'day') {
              dayCol = i;
              break;
            }
          }
        }

        if (dayCol != -1) {
          for (var i = 1; i < sheet.maxRows; i++) {
            final row = sheet.rows[i];
            if (row.isEmpty || row[dayCol] == null) continue;
            final dayName = row[dayCol]!.value.toString().trim();
            if (dayName.isEmpty || dayName.toLowerCase() == 'day') continue;
            daysMap[dayName] ??= [];
            daysMap[dayName]!.add(TaskBlock(
              label: row.length > 2 ? (row[2]?.value.toString() ?? 'Activity') : 'Activity',
              time: row.length > 1 ? (row[1]?.value.toString() ?? '') : '',
              task: row.length > 3 ? row[3]?.value.toString() : null,
              points: 2,
            ));
          }
        } else {
          return ImportResult.failure('Unsupported Excel layout. Expected weekday sheets or a "Day" column in the first sheet.');
        }
      }

      if (daysMap.isEmpty) return ImportResult.failure('Could not identify any schedule data in Excel.');
      return ImportResult.success(WeekPlan(
        weekIdentifier: 'Imported Excel',
        days: daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)).toList(),
      ));
    } catch (e) {
      return ImportResult.failure('Excel Parse Error: $e');
    }
  }

  List<TaskBlock> _parseSheetToTasks(ex.Sheet sheet) {
    List<TaskBlock> tasks = [];
    for (var i = 1; i < sheet.maxRows; i++) {
      final row = sheet.rows[i];
      if (row.length < 2) continue;
      final time = row[0]?.value.toString() ?? '';
      final title = row[1]?.value.toString() ?? '';
      if (time.isEmpty && title.isEmpty) continue;
      tasks.add(TaskBlock(label: title, time: time, task: row.length > 2 ? row[2]?.value.toString() : null, points: 2));
    }
    return tasks;
  }

  ImportResult parseTxt(String content) {
    try {
      final List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      Map<String, List<TaskBlock>> daysMap = {};
      String? currentDay;
      final lines = content.split(RegExp(r'[\n\r]+'));
      final timeRegex = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?|\d{1,2}\s*(?:AM|PM|am|pm))');

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;
        bool foundDay = false;
        for (var day in weekdays) {
          if (line.toLowerCase().contains(day.toLowerCase())) {
            currentDay = day;
            daysMap[currentDay] ??= [];
            foundDay = true;
            break;
          }
        }
        if (foundDay) continue;

        if (currentDay != null) {
          final timeMatch = timeRegex.firstMatch(line);
          if (timeMatch != null) {
            final time = timeMatch.group(0)!;
            final text = line.replaceAll(time, '').trim().replaceAll(RegExp(r'^[-:]\s*'), '');
            daysMap[currentDay]!.add(TaskBlock(label: text.isEmpty ? 'Activity' : text, time: time, points: 1));
          } else {
            daysMap[currentDay]!.add(TaskBlock(label: line, time: 'TBD', points: 0));
          }
        }
      }
      if (daysMap.isEmpty) return ImportResult.failure('No weekday or time patterns found in TXT file.');
      return ImportResult.success(WeekPlan(
        weekIdentifier: 'Imported TXT',
        days: daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)).toList(),
      ));
    } catch (e) {
      return ImportResult.failure('TXT Processing Error: $e');
    }
  }
}
