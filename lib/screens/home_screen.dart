import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule_model.dart';
import '../data/schedule_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<DaySchedule> _currentWeek;
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _currentWeek = List.from(weeklySchedule);
    _selectedDayIndex = _getCurrentDayIndex();
  }

  int _getCurrentDayIndex() {
    String today = DateFormat('EEEE').format(DateTime.now());
    int index = _currentWeek.indexWhere((day) => day.day == today);
    return index != -1 ? index : 0;
  }

  void _toggleTask(int dayIndex, int taskIndex) {
    setState(() {
      final task = _currentWeek[dayIndex].tasks[taskIndex];
      _currentWeek[dayIndex].tasks[taskIndex] = task.copyWith(
        isCompleted: !task.isCompleted,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final todaySchedule = _currentWeek[_selectedDayIndex];
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(todaySchedule),
            _buildScoreSection(todaySchedule),
            Expanded(
              child: _buildTimeline(todaySchedule, _selectedDayIndex),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DaySchedule schedule) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            schedule.day.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Daily Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection(DaySchedule schedule) {
    double progress = schedule.maxPoints > 0 ? schedule.totalPoints / schedule.maxPoints : 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today Score',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                '${schedule.totalPoints}/${schedule.maxPoints}',
                style: const TextStyle(
                  color: Color(0xFFBB86FC),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.black,
            color: const Color(0xFFBB86FC),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(DaySchedule schedule, int dayIndex) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: schedule.tasks.length,
      itemBuilder: (context, index) {
        final task = schedule.tasks[index];
        return IntrinsicHeight(
          child: Row(
            children: [
              _buildTimeIndicator(task, index == schedule.tasks.length - 1),
              Expanded(
                child: _buildTaskCard(task, dayIndex, index),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeIndicator(ScheduleTask task, bool isLast) {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Text(
            task.time.split(' ')[0],
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : Colors.grey.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(ScheduleTask task, int dayIndex, int taskIndex) {
    bool hasPoints = task.points > 0;
    
    return GestureDetector(
      onTap: () => _toggleTask(dayIndex, taskIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: task.isCompleted ? const Color(0xFF2D2D2D) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isCompleted ? const Color(0xFFBB86FC).withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.label,
                    style: TextStyle(
                      color: task.isCompleted ? Colors.grey : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.task != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.task!,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    task.time,
                    style: const TextStyle(color: Color(0xFFBB86FC), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (hasPoints)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.isCompleted ? const Color(0xFFBB86FC) : Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${task.points}',
                  style: TextStyle(
                    color: task.isCompleted ? Colors.black : const Color(0xFFBB86FC),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
