class ScheduleTask {
  final String label;
  final String time;
  final String? task;
  final int points;
  final bool isCompleted;

  ScheduleTask({
    required this.label,
    required this.time,
    this.task,
    required this.points,
    this.isCompleted = false,
  });

  ScheduleTask copyWith({bool? isCompleted}) {
    return ScheduleTask(
      label: label,
      time: time,
      task: task,
      points: points,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class DaySchedule {
  final String day;
  final List<ScheduleTask> tasks;

  DaySchedule({
    required this.day,
    required this.tasks,
  });

  int get totalPoints => tasks.where((t) => t.isCompleted).fold(0, (sum, t) => sum + t.points);
  int get maxPoints => tasks.fold(0, (sum, t) => sum + t.points);
}
