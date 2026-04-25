class TaskBlock {
  final String label;
  final String time;
  final String? task;
  final int points;
  bool isCompleted;

  TaskBlock({
    required this.label,
    required this.time,
    this.task,
    required this.points,
    this.isCompleted = false,
  });

  factory TaskBlock.fromJson(Map<String, dynamic> json) {
    return TaskBlock(
      label: json['label'] as String? ?? 'Task',
      time: json['time'] as String? ?? 'TBD',
      task: json['task'] as String?,
      points: json['points'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'time': time,
      'task': task,
      'points': points,
      'isCompleted': isCompleted,
    };
  }

  TaskBlock copyWith({
    String? label,
    String? time,
    String? task,
    int? points,
    bool? isCompleted,
  }) {
    return TaskBlock(
      label: label ?? this.label,
      time: time ?? this.time,
      task: task ?? this.task,
      points: points ?? this.points,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class DayPlan {
  final String day;
  final List<TaskBlock> tasks;

  DayPlan({
    required this.day,
    required this.tasks,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      day: json['day'] as String? ?? 'Unknown',
      tasks: (json['tasks'] as List? ?? []).map((t) => TaskBlock.fromJson(t)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }

  int get totalPoints => tasks.where((t) => t.isCompleted).fold(0, (sum, t) => sum + t.points);
  int get maxPoints => tasks.fold(0, (sum, t) => sum + t.points);
}

class WeekPlan {
  final String weekIdentifier;
  final List<DayPlan> days;

  WeekPlan({
    required this.weekIdentifier,
    required this.days,
  });

  factory WeekPlan.fromJson(Map<String, dynamic> json) {
    return WeekPlan(
      weekIdentifier: json['weekIdentifier'] as String? ?? 'Week Plan',
      days: (json['days'] as List? ?? []).map((d) => DayPlan.fromJson(d)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekIdentifier': weekIdentifier,
      'days': days.map((d) => d.toJson()).toList(),
    };
  }
}
