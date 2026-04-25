import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';

class PlanService {
  static const String _planKey = 'user_week_plan';

  Future<WeekPlan> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlan = prefs.getString(_planKey);

    if (savedPlan != null) {
      try {
        return WeekPlan.fromJson(jsonDecode(savedPlan));
      } catch (e) {
        print('Error parsing saved plan: $e');
      }
    }

    // Fallback to default asset
    final String response = await rootBundle.loadString('assets/default_plan.json');
    final data = await jsonDecode(response);
    return WeekPlan.fromJson(data);
  }

  Future<void> savePlan(WeekPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, jsonEncode(plan.toJson()));
  }
}
