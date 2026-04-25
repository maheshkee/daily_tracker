import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex;
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
      
      // Expected header: Day, Wake, Morning Study, Job, Gym, Night Study, Sleep
      // Logic: Group rows by Day
      Map<String, List<TaskBlock>> daysMap = {};
      
      // Basic heuristic: check if first row is header
      int startIdx = (rows[0][0].toString().toLowerCase() == 'day') ? 1 : 0;
      
      for (var i = startIdx; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 2) continue;
        
        final dayName = row[0].toString().trim();
        if (dayName.isEmpty) continue;

        if (!daysMap.containsKey(dayName)) {
          daysMap[dayName] = [];
        }

        // Add standard tasks if this is a new day entry
        // For simplicity, we assume one row per day with multiple columns or multiple rows
        // For this V1 CSV, let's assume one row per day with specific column mapping
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

      final dayPlans = daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)).toList();
      return WeekPlan(weekIdentifier: 'Imported CSV', days: dayPlans);
    } catch (e) {
      throw Exception('CSV Parsing Error: $e');
    }
  }

  WeekPlan _parseXlsx(Uint8List bytes) {
    try {
      var excel = ex.Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        throw Exception('No sheets found in Excel file.');
      }
      
      var sheet = excel.tables.values.first;
      if (sheet.maxRows <= 1) {
        throw Exception('No usable rows found in the first sheet.');
      }
      
      Map<String, List<TaskBlock>> daysMap = {};
      
      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;
        
        String? getVal(int col) {
          if (col >= row.length) return null;
          final cell = row[col];
          if (cell == null || cell.value == null) return null;
          return cell.value.toString().trim();
        }

        final dayName = getVal(0);
        if (dayName == null || dayName.isEmpty || dayName.toLowerCase() == 'day') continue;
        
        // Skip scoring/legend rows often found at bottom
        if (dayName.toLowerCase().contains('score') || dayName.toLowerCase().contains('wake on')) {
          continue;
        }

        daysMap[dayName] = [
          TaskBlock(label: 'Wake Up', time: getVal(1) ?? '6:00 AM', points: 1),
          TaskBlock(label: 'Morning Study', time: '6:15-7:15', task: getVal(2) ?? '', points: 2),
          TaskBlock(label: 'Job', time: '9:00-5:00', task: getVal(3) ?? 'Yes', points: 0),
          TaskBlock(label: 'Gym', time: getVal(4) ?? '6:00 PM', points: 2),
          TaskBlock(label: 'Night Study', time: '8:15-9:00', task: getVal(6) ?? '', points: 2),
          TaskBlock(label: 'Sleep', time: getVal(7) ?? '11:00 PM', points: 1),
        ];
      }

      if (daysMap.isEmpty) {
        throw Exception('No valid weekday data rows identified.');
      }

      final dayPlans = daysMap.entries.map((e) => DayPlan(day: e.key, tasks: e.value)).toList();
      return WeekPlan(weekIdentifier: 'Imported XLSX', days: dayPlans);
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('XLSX Parsing Error: $e');
    }
  }
}
