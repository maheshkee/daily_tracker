import '../models/schedule_model.dart';

final List<DaySchedule> weeklySchedule = [
  DaySchedule(
    day: 'Monday',
    tasks: [
      ScheduleTask(label: 'Wake Up', time: '6:00 AM', points: 1),
      ScheduleTask(label: 'Morning Study', time: '6:15-7:15', task: 'Math(fractions/decimals)+Python basics', points: 2),
      ScheduleTask(label: 'Job 9-5', time: '9:00 AM - 5:00 PM', points: 0),
      ScheduleTask(label: 'Gym', time: '6:00-7:00 PM', points: 2),
      ScheduleTask(label: 'Night Study', time: '8:15-9:00', task: 'Microcontroller basics', points: 2),
      ScheduleTask(label: 'Sleep', time: '10:30-11:00 PM', points: 1),
    ],
  ),
  DaySchedule(
    day: 'Tuesday',
    tasks: [
      ScheduleTask(label: 'Wake Up', time: '6:00 AM', points: 1),
      ScheduleTask(label: 'Morning Study', time: '6:15-7:15', task: 'Backend intro + Python input()', points: 2),
      ScheduleTask(label: 'Job 9-5', time: '9:00 AM - 5:00 PM', points: 0),
      ScheduleTask(label: 'Gym', time: '6:00-7:00 PM', points: 2),
      ScheduleTask(label: 'Night Study', time: '8:15-9:00', task: 'Inputs/Outputs, sensors', points: 2),
      ScheduleTask(label: 'Sleep', time: '10:30-11:00 PM', points: 1),
    ],
  ),
  DaySchedule(
    day: 'Wednesday',
    tasks: [
      ScheduleTask(label: 'Wake Up', time: '6:00 AM', points: 1),
      ScheduleTask(label: 'Morning Study', time: '6:15-7:15', task: 'Math(percentages)+if/else', points: 2),
      ScheduleTask(label: 'Job 9-5', time: '9:00 AM - 5:00 PM', points: 0),
      ScheduleTask(label: 'Gym', time: '6:00-7:00 PM', points: 2),
      ScheduleTask(label: 'Night Study', time: '8:15-9:00', task: 'Digital vs Analog', points: 2),
      ScheduleTask(label: 'Sleep', time: '10:30-11:00 PM', points: 1),
    ],
  ),
  DaySchedule(
    day: 'Thursday',
    tasks: [
      ScheduleTask(label: 'Wake Up', time: '6:00 AM', points: 1),
      ScheduleTask(label: 'Morning Study', time: '6:15-7:15', task: 'HTTP basics + operators', points: 2),
      ScheduleTask(label: 'Job 9-5', time: '9:00 AM - 5:00 PM', points: 0),
      ScheduleTask(label: 'Gym', time: '6:00-7:00 PM', points: 2),
      ScheduleTask(label: 'Night Study', time: '8:15-9:00', task: 'Sensor types', points: 2),
      ScheduleTask(label: 'Sleep', time: '10:30-11:00 PM', points: 1),
    ],
  ),
  DaySchedule(
    day: 'Friday',
    tasks: [
      ScheduleTask(label: 'Wake Up', time: '6:00 AM', points: 1),
      ScheduleTask(label: 'Morning Study', time: '6:15-7:15', task: 'Algebra + loops', points: 2),
      ScheduleTask(label: 'Job 9-5', time: '9:00 AM - 5:00 PM', points: 0),
      ScheduleTask(label: 'Gym', time: '6:00-7:00 PM', points: 2),
      ScheduleTask(label: 'Night Study', time: '8:15-9:00', task: 'Arduino debugging', points: 2),
      ScheduleTask(label: 'Sleep', time: '10:30-11:00 PM', points: 1),
    ],
  ),
  DaySchedule(
    day: 'Saturday',
    tasks: [
      ScheduleTask(label: 'Wake Up', time: '6:00 AM', points: 1),
      ScheduleTask(label: 'Morning Study', time: '6:15-7:15', task: 'API/JSON + functions', points: 2),
      ScheduleTask(label: 'Job 9-5', time: '9:00 AM - 5:00 PM', points: 0),
      ScheduleTask(label: 'Gym', time: '6:00-7:00 PM', points: 2),
      ScheduleTask(label: 'Night Study', time: '8:15-9:00', task: 'BLE basics', points: 2),
      ScheduleTask(label: 'Sleep', time: '10:30-11:00 PM', points: 1),
    ],
  ),
  DaySchedule(
    day: 'Sunday',
    tasks: [
      ScheduleTask(label: 'Wake Up', time: '6:00 AM', points: 1),
      ScheduleTask(label: 'Morning Study', time: '6:15-7:15', task: 'Review + mini project', points: 2),
      ScheduleTask(label: 'Job 9-5', time: '9:00 AM - 5:00 PM', points: 0),
      ScheduleTask(label: 'Gym', time: '6:00-7:00 PM', points: 2),
      ScheduleTask(label: 'Night Study', time: '8:15-9:00', task: 'Reflect + Plan Week2', points: 2),
      ScheduleTask(label: 'Sleep', time: '10:30-11:00 PM', points: 1),
    ],
  ),
];
