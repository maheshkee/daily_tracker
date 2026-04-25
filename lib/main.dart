import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  late String _morningTask;
  int _streakCount = 0;
  int _completedDays = 0;
  int _totalPerfectDays = 0;
  bool _isLoading = true;

  final List<TaskItem> _tasks = [];
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    _prefs = await SharedPreferences.getInstance();
    _morningTask = _getMorningTask();
    _initializeTaskObjects();
    await _loadAndSyncData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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

  void _initializeTaskObjects() {
    _tasks.clear();
    _tasks.addAll([
      TaskItem(id: 'morning', title: 'Morning: $_morningTask'),
      TaskItem(id: 'night', title: 'Night Revision'),
      TaskItem(id: 'workout', title: 'Workout'),
      TaskItem(id: 'walk', title: 'Walk'),
      TaskItem(id: 'water', title: 'Water Goal'),
    ]);
  }

  Future<void> _loadAndSyncData() async {
    final String today = _getTodayString();
    final String? lastDate = _prefs.getString('last_date');
    
    _streakCount = _prefs.getInt('streak') ?? 0;
    _completedDays = _prefs.getInt('completed_days') ?? 0;
    _totalPerfectDays = _prefs.getInt('perfect_days') ?? 0;

    if (lastDate == null) {
      // First time app opening
      await _prefs.setString('last_date', today);
    } else if (lastDate != today) {
      // New day detected
      await _handleDailyReset(lastDate, today);
    } else {
      // Same day, load task states
      for (var task in _tasks) {
        task.isDone = _prefs.getBool('task_${task.id}') ?? false;
      }
    }
  }

  Future<void> _handleDailyReset(String lastDateStr, String todayStr) async {
    final DateTime lastDate = DateTime.parse(lastDateStr);
    final DateTime today = DateTime.parse(todayStr);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    
    // Check performance of the last recorded day
    int lastCompletedCount = 0;
    for (var task in _tasks) {
      if (_prefs.getBool('task_${task.id}') ?? false) {
        lastCompletedCount++;
      }
    }

    // Streak logic
    bool wasYesterday = lastDate.year == yesterday.year && 
                        lastDate.month == yesterday.month && 
                        lastDate.day == yesterday.day;

    if (wasYesterday) {
      if (lastCompletedCount >= 4) {
        _streakCount++;
        _completedDays++;
        if (lastCompletedCount == 5) _totalPerfectDays++;
      } else {
        _streakCount = 0;
      }
    } else {
      // Missed at least one full day
      _streakCount = 0;
    }

    // Reset task states in prefs and memory
    for (var task in _tasks) {
      task.isDone = false;
      await _prefs.setBool('task_${task.id}', false);
    }

    await _prefs.setInt('streak', _streakCount);
    await _prefs.setInt('completed_days', _completedDays);
    await _prefs.setInt('perfect_days', _totalPerfectDays);
    await _prefs.setString('last_date', todayStr);
  }

  String _getTodayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _toggleTask(int index) async {
    setState(() {
      _tasks[index].isDone = !_tasks[index].isDone;
    });
    await _prefs.setBool('task_${_tasks[index].id}', _tasks[index].isDone);
  }

  int get _completedCount => _tasks.where((t) => t.isDone).length;
  double get _progress => _tasks.isEmpty ? 0 : _completedCount / _tasks.length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              _buildSectionHeader('TODAY TASKS'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _tasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildTaskTile(_tasks[index], index),
                ),
              ),
              _buildStatsFooter(),
              const SizedBox(height: 16),
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
              _buildStreakBadge(),
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

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
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
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Completion', style: Theme.of(context).textTheme.bodyMedium),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white38,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildTaskTile(TaskItem task, int index) {
    return GestureDetector(
      onTap: () => _toggleTask(index),
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
            _buildCheckbox(task.isDone),
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

  Widget _buildCheckbox(bool isDone) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone ? Colors.greenAccent : Colors.white24,
          width: 2,
        ),
        color: isDone ? Colors.greenAccent : Colors.transparent,
      ),
      child: isDone ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
    );
  }

  Widget _buildStatsFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Completed Days', '$_completedDays'),
          _buildStatItem('Perfect Days', '$_totalPerfectDays'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  bool isDone;

  TaskItem({required this.id, required this.title, this.isDone = false});
}
