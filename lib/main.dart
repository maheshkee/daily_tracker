import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const DailySystemApp());
}

class DailySystemApp extends StatelessWidget {
  const DailySystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const DailySystemHome(),
    );
  }
}

class DailySystemHome extends StatefulWidget {
  const DailySystemHome({super.key});

  @override
  State<DailySystemHome> createState() => _DailySystemHomeState();
}

class _DailySystemHomeState extends State<DailySystemHome> {
  late final String _morningTask;
  final int _streakCount = 12; // Placeholder for streak logic

  final List<TaskItem> _tasks = [];

  @override
  void initState() {
    super.initState();
    _morningTask = _getMorningTask();
    _initializeTasks();
  }

  String _getMorningTask() {
    final weekday = DateTime.now().weekday;
    switch (weekday) {
      case DateTime.monday:
      case DateTime.wednesday:
      case DateTime.friday:
        return 'Math + Programming';
      case DateTime.tuesday:
      case DateTime.thursday:
      case DateTime.saturday:
        return 'Backend Concepts';
      case DateTime.sunday:
        return 'Weekly Review';
      default:
        return 'Study Session';
    }
  }

  void _initializeTasks() {
    _tasks.addAll([
      TaskItem(title: 'Morning: $_morningTask'),
      TaskItem(title: 'Night Revision'),
      TaskItem(title: 'Workout'),
      TaskItem(title: 'Walk'),
      TaskItem(title: 'Water Goal'),
    ]);
  }

  int get _completedCount => _tasks.where((t) => t.isDone).length;
  double get _progress => _tasks.isEmpty ? 0 : _completedCount / _tasks.length;

  @override
  Widget build(BuildContext context) {
    final String currentDay = DateFormat('EEEE').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildTopCard(currentDay),
              const SizedBox(height: 40),
              _buildProgressSection(),
              const SizedBox(height: 32),
              Text(
                'TODAY TASKS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white38,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _tasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return _buildTaskTile(task, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(String currentDay) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily System',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_streakCount',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentDay,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completion',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$_completedCount / ${_tasks.length}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskTile(TaskItem task, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          task.isDone = !task.isDone;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: task.isDone ? Colors.white.withValues(alpha: 0.02) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: task.isDone ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isDone ? Colors.greenAccent : Colors.white24,
                  width: 2,
                ),
                color: task.isDone ? Colors.greenAccent : Colors.transparent,
              ),
              child: task.isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: task.isDone ? Colors.white38 : Colors.white,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskItem {
  final String title;
  bool isDone;

  TaskItem({required this.title, this.isDone = false});
}
