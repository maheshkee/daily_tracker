import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/plan_service.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  final PlanService _planService = PlanService();
  WeekPlan? _weekPlan;
  int _selectedDayIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final plan = await _planService.loadPlan();
    if (mounted) {
      setState(() {
        _weekPlan = plan;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_weekPlan?.weekIdentifier ?? 'Weekly Overview', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          Expanded(
            child: _buildDaySchedule(_weekPlan!.days[_selectedDayIndex]),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _weekPlan!.days.length,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (context, index) {
          bool isSelected = _selectedDayIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFBB86FC) : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekPlan!.days[index].day.substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDaySchedule(DayPlan schedule) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: schedule.tasks.length,
      itemBuilder: (context, index) {
        final task = schedule.tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                task.time.split(' ')[0],
                style: const TextStyle(color: Color(0xFFBB86FC), fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.label,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (task.task != null)
                      Text(
                        task.task!,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
