import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex;
import 'package:docx_to_text/docx_to_text.dart';
import '../models/schedule_model.dart';

class ImportEngine {
  Future<WeekPlan> parseFile(String path) async {
    final file = File(path);
    final extension = path.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'json':
        return _parseJson(await file.readAsString());
      case 'csv':
        return _parseCsv(await file.readAsString());
      case 'xlsx':
        return _parseXlsx(await file.readAsBytes());
      case 'txt':
        return _parseSemanticText(await file.readAsString(), 'TXT');
      case 'docx':
        return _parseDocx(file);
      case 'pdf':
        throw Exception('PDF import is temporarily disabled for stability.');
      default:
        throw Exception('Unsupported file format: $extension');
    }
  }

  WeekPlan _parseJson(String content) {
    try {
      final data = jsonDecode(content);
      return WeekPlan.fromJson(data);
    } catch (e) {
      throw Exception('Invalid JSON structure: $e');
    }
  }

  WeekPlan _parseCsv(String content) {
    try {
      final List<List<dynamic>> rows = csv.decode(content);
      if (rows.isEmpty) throw Exception('CSV is empty');
      Map<String, List<TaskBlock>> daysMap = {};
      int startIdx = (rows[0][0].toString().toLowerCase() == 'day') ? 1 : 0;
      
      for (var i = startIdx; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 2) continue;
        final dayName = row[0].toString().trim();
        if (dayName.isEmpty) continue;
        if (row.length >= 7) {
          daysMap[dayName] = [
            TaskBlock(label: 'Wake Up', time: row[1].toString(), points: 1),
            TaskBlock(label: 'Morning Study', time: '6:15-7:15', task: row[2].toString(), points: 2),
            TaskBlock(label: 'Job', time: '9:00-5:00', task: row[3].toString(), points: 0),
            TaskBlock(label: 'Gym', time: row[4].toString(), points: 2),
            TaskBlock(label: 'Night Study', time: '8:15-9:00', task: row[5].toString(), points: 2),
            TaskBlock(label: 'Sleep', time: row[6].toString(), points: 1),
          ];
        }
      }
      return WeekPlan(weekIdentifier: 'Imported CSV', days: daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)).toList());
    } catch (e) {
      throw Exception('CSV Parsing Error: $e');
    }
  }

  WeekPlan _parseXlsx(Uint8List bytes) {
    try {
      var excel = ex.Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) throw Exception('No sheets found');
      var sheet = excel.tables.values.first;
      Map<String, List<TaskBlock>> daysMap = {};
      
      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;
        String? getVal(int col) => (col < row.length && row[col] != null) ? row[col]!.value.toString().trim() : null;
        final dayName = getVal(0);
        if (dayName == null || dayName.isEmpty || dayName.toLowerCase() == 'day') continue;
        if (dayName.toLowerCase().contains('score')) continue;

        daysMap[dayName] = [
          TaskBlock(label: 'Wake Up', time: getVal(1) ?? '6:00 AM', points: 1),
          TaskBlock(label: 'Morning Study', time: '6:15-7:15', task: getVal(2) ?? '', points: 2),
          TaskBlock(label: 'Job', time: '9:00-5:00', task: getVal(3) ?? 'Yes', points: 0),
          TaskBlock(label: 'Gym', time: getVal(4) ?? '6:00 PM', points: 2),
          TaskBlock(label: 'Night Study', time: '8:15-9:00', task: getVal(6) ?? '', points: 2),
          TaskBlock(label: 'Sleep', time: getVal(7) ?? '11:00 PM', points: 1),
        ];
      }
      return WeekPlan(weekIdentifier: 'Imported XLSX', days: daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)).toList());
    } catch (e) {
      throw Exception('XLSX Parsing Error: $e');
    }
  }

  Future<WeekPlan> _parseDocx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final text = docxToText(bytes);
      return _parseSemanticText(text, 'DOCX');
    } catch (e) {
      throw Exception('DOCX Extraction Error: $e');
    }
  }

  WeekPlan _parseSemanticText(String text, String source) {
    final List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    Map<String, List<TaskBlock>> daysMap = {};
    String? currentDay;

    final lines = text.split(RegExp(r'[\n\r]+'));
    
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Detect Day
      for (var day in weekdays) {
        if (line.toLowerCase().contains(day.toLowerCase())) {
          currentDay = day;
          daysMap[currentDay] ??= [];
          break;
        }
      }

      if (currentDay == null) continue;

      // Semantic extraction logic for tasks within a day
      // Regex for time patterns (e.g., 6:00 AM, 18:00, 6pm)
      final timeRegex = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?|\d{1,2}\s*(?:AM|PM|am|pm))');
      final match = timeRegex.firstMatch(line);

      if (match != null) {
        final timeStr = match.group(0)!;
        String label = 'Activity';
        String? detail;

        // Keyword detection
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('wake') || lowerLine.contains('up')) {
          label = 'Wake Up';
        } else if (lowerLine.contains('study') || lowerLine.contains('learn')) {
          label = lowerLine.contains('morning') ? 'Morning Study' : 'Night Study';
          detail = line.replaceAll(timeStr, '').trim();
        } else if (lowerLine.contains('gym') || lowerLine.contains('workout')) {
          label = 'Gym';
        } else if (lowerLine.contains('sleep') || lowerLine.contains('bed')) {
          label = 'Sleep';
        } else if (lowerLine.contains('job') || lowerLine.contains('work')) {
          label = 'Job';
        }

        daysMap[currentDay]!.add(TaskBlock(
          label: label,
          time: timeStr,
          task: detail,
          points: (label == 'Activity') ? 0 : 2,
        ));
      }
    }

    if (daysMap.isEmpty) throw Exception('No schedule patterns found in $source');

    return WeekPlan(
      weekIdentifier: 'Semantic $source Import',
      days: daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)).toList(),
    );
  }
}
