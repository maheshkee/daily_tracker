import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';

class PlanService {
  static const String _planKey = 'user_week_plan';

  /// Load plan from SharedPreferences or fallback to default asset
  /// Includes error handling for all failure paths
  Future<WeekPlan> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlan = prefs.getString(_planKey);

    if (savedPlan != null) {
      try {
        return WeekPlan.fromJson(jsonDecode(savedPlan));
      } catch (e) {
        print('Error parsing saved plan: $e');
        // Continue to load default plan
      }
    }

    // Try to load default plan from assets
    try {
      final String response = await rootBundle.loadString('assets/default_plan.json');
      final data = jsonDecode(response);
      return WeekPlan.fromJson(data);
    } catch (e) {
      print('Error loading default plan from assets: $e');
      // Fallback to hardcoded plan - this ensures the app never crashes
      return _getFallbackPlan();
    }
  }

  /// Save plan to SharedPreferences
  Future<void> savePlan(WeekPlan plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_planKey, jsonEncode(plan.toJson()));
    } catch (e) {
      print('Error saving plan: $e');
      // Don't throw - let the app continue with unsaved changes
    }
  }

  /// Reset plan to default by removing saved preference
  Future<void> resetPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_planKey);
    } catch (e) {
      print('Error resetting plan: $e');
    }
  }

  /// Fallback plan - hardcoded minimal valid structure
  /// Used only if assets fail to load and no saved plan exists
  WeekPlan _getFallbackPlan() {
    return WeekPlan(
      weekIdentifier: 'Default Plan',
      days: [
        DayPlan(day: 'Monday', tasks: [
          TaskBlock(label: 'Wake Up', time: '6:00 AM', points: 1),
          TaskBlock(label: 'Study', time: '6:15-7:15', task: 'Backend Learning', points: 2),
          TaskBlock(label: 'Job', time: '9:00 AM - 5:00 PM', points: 0),
          TaskBlock(label: 'Gym', time: '6:00 PM', points: 2),
          TaskBlock(label: 'Night Study', time: '8:15-9:00', task: 'LLM Research', points: 2),
          TaskBlock(label: 'Sleep', time: '11:00 PM', points: 1),
        ]),
        DayPlan(day: 'Tuesday', tasks: [
          TaskBlock(label: 'Wake Up', time: '6:00 AM', points: 1),
          TaskBlock(label: 'Study', time: '6:15-7:15', task: 'Python Basics', points: 2),
          TaskBlock(label: 'Job', time: '9:00 AM - 5:00 PM', points: 0),
          TaskBlock(label: 'Gym', time: '6:00 PM', points: 2),
          TaskBlock(label: 'Night Study', time: '8:15-9:00', task: 'FastAPI Deep Dive', points: 2),
          TaskBlock(label: 'Sleep', time: '11:00 PM', points: 1),
        ]),
        DayPlan(day: 'Wednesday', tasks: [
          TaskBlock(label: 'Wake Up', time: '6:00 AM', points: 1),
          TaskBlock(label: 'Study', time: '6:15-7:15', task: 'Database Design', points: 2),
          TaskBlock(label: 'Job', time: '9:00 AM - 5:00 PM', points: 0),
          TaskBlock(label: 'Gym', time: '6:00 PM', points: 2),
          TaskBlock(label: 'Night Study', time: '8:15-9:00', task: 'Docker & Deployment', points: 2),
          TaskBlock(label: 'Sleep', time: '11:00 PM', points: 1),
        ]),
        DayPlan(day: 'Thursday', tasks: [
          TaskBlock(label: 'Wake Up', time: '6:00 AM', points: 1),
          TaskBlock(label: 'Study', time: '6:15-7:15', task: 'API Design Patterns', points: 2),
          TaskBlock(label: 'Job', time: '9:00 AM - 5:00 PM', points: 0),
          TaskBlock(label: 'Gym', time: '6:00 PM', points: 2),
          TaskBlock(label: 'Night Study', time: '8:15-9:00', task: 'TinyML Experiments', points: 2),
          TaskBlock(label: 'Sleep', time: '11:00 PM', points: 1),
        ]),
        DayPlan(day: 'Friday', tasks: [
          TaskBlock(label: 'Wake Up', time: '6:00 AM', points: 1),
          TaskBlock(label: 'Study', time: '6:15-7:15', task: 'Security & Auth', points: 2),
          TaskBlock(label: 'Job', time: '9:00 AM - 5:00 PM', points: 0),
          TaskBlock(label: 'Gym', time: '6:00 PM', points: 2),
          TaskBlock(label: 'Night Study', time: '8:15-9:00', task: 'Project Building', points: 2),
          TaskBlock(label: 'Sleep', time: '11:00 PM', points: 1),
        ]),
        DayPlan(day: 'Saturday', tasks: [
          TaskBlock(label: 'Wake Up', time: '6:00 AM', points: 1),
          TaskBlock(label: 'Study', time: '6:15-7:15', task: 'System Design', points: 2),
          TaskBlock(label: 'Job', time: '9:00 AM - 5:00 PM', points: 0),
          TaskBlock(label: 'Gym', time: '6:00 PM', points: 2),
          TaskBlock(label: 'Night Study', time: '8:15-9:00', task: 'Code Review & Refactor', points: 2),
          TaskBlock(label: 'Sleep', time: '11:00 PM', points: 1),
        ]),
        DayPlan(day: 'Sunday', tasks: [
          TaskBlock(label: 'Wake Up', time: '6:00 AM', points: 1),
          TaskBlock(label: 'Study', time: '6:15-7:15', task: 'Weekly Review', points: 2),
          TaskBlock(label: 'Job', time: '9:00 AM - 5:00 PM', points: 0),
          TaskBlock(label: 'Gym', time: '6:00 PM', points: 2),
          TaskBlock(label: 'Night Study', time: '8:15-9:00', task: 'Plan Next Week', points: 2),
          TaskBlock(label: 'Sleep', time: '11:00 PM', points: 1),
        ]),
      ],
    );
  }
}
