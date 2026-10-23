/// Optional daily suggestions and a flexible weekly goal. Nothing here ever
/// penalises a missed day.
library;

import 'activity.dart';
import 'hero.dart';
import 'workout.dart';

class QuestSuggestion {
  const QuestSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.activityId,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.variant,
    this.needsDumbbells = false,
  });

  final String id;
  final String title;
  final String description;
  final String activityId;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final String? variant;
  final bool needsDumbbells;

  ActivityType get activity => ActivityCatalog.byId(activityId)!;

  bool isDoneBy(Iterable<WorkoutEntry> todays) =>
      todays.any((e) => e.activityId == activityId);
}

class WeeklyGoal {
  const WeeklyGoal({required this.target, required this.daysActive});

  final int target;
  final int daysActive;

  bool get met => daysActive >= target;
  double get progress => target == 0 ? 1 : (daysActive / target).clamp(0, 1);
}

class QuestBoard {
  const QuestBoard._();

  static const _starting = <QuestSuggestion>[
    QuestSuggestion(
      id: 'q_wall_pushups',
      title: 'Wall Push-Ups',
      description: 'Two gentle sets of 8. Step back as far as feels right.',
      activityId: 'push_up',
      sets: 2,
      reps: 8,
      variant: 'Wall',
    ),
    QuestSuggestion(
      id: 'q_chair_squats',
      title: 'Sit-to-Stand',
      description: 'Two sets of 8 using a sturdy chair.',
      activityId: 'squat',
      sets: 2,
      reps: 8,
      variant: 'Sit-to-Stand (Chair)',
    ),
    QuestSuggestion(
      id: 'q_walk_10',
      title: '10-Minute Stroll',
      description: 'Any pace you like. Around the block counts.',
      activityId: 'walking',
      durationSeconds: 600,
    ),
    QuestSuggestion(
      id: 'q_stretch_5',
      title: '5-Minute Stretch',
      description: 'Ease into a few comfortable stretches.',
      activityId: 'stretching',
      durationSeconds: 300,
    ),
  ];

  static const _returning = <QuestSuggestion>[
    QuestSuggestion(
      id: 'q_incline_pushups',
      title: 'Incline Push-Ups',
      description: 'Three sets of 8 with your hands on a bench or counter.',
      activityId: 'push_up',
      sets: 3,
      reps: 8,
      variant: 'Incline',
    ),
    QuestSuggestion(
      id: 'q_squats',
      title: 'Bodyweight Squats',
      description: 'Three sets of 10, nice and controlled.',
      activityId: 'squat',
      sets: 3,
      reps: 10,
      variant: 'Bodyweight',
    ),
    QuestSuggestion(
      id: 'q_walk_20',
      title: '20-Minute Walk',
      description: 'Comfortable pace, fresh air optional.',
      activityId: 'walking',
      durationSeconds: 1200,
    ),
    QuestSuggestion(
      id: 'q_plank',
      title: 'Plank Holds',
      description: 'Three holds of 20 seconds. Knees down is welcome.',
      activityId: 'plank',
      sets: 3,
      durationSeconds: 20,
    ),
    QuestSuggestion(
      id: 'q_db_row',
      title: 'Dumbbell Rows',
      description: 'Two sets of 10 each side with a light weight.',
      activityId: 'dumbbell_row',
      sets: 2,
      reps: 10,
      needsDumbbells: true,
    ),
  ];

  static const _regular = <QuestSuggestion>[
    QuestSuggestion(
      id: 'q_jog_20',
      title: '20-Minute Jog',
      description: 'Steady effort. Walk breaks are fair game.',
      activityId: 'running',
      durationSeconds: 1200,
    ),
    QuestSuggestion(
      id: 'q_pushups',
      title: 'Push-Up Ladder',
      description: 'Four sets of 10, or your best version of that.',
      activityId: 'push_up',
      sets: 4,
      reps: 10,
    ),
    QuestSuggestion(
      id: 'q_db_press',
      title: 'Shoulder Presses',
      description: 'Three sets of 10 at a weight you can control.',
      activityId: 'dumbbell_press',
      sets: 3,
      reps: 10,
      needsDumbbells: true,
    ),
    QuestSuggestion(
      id: 'q_squats_reg',
      title: 'Squat Set',
      description: 'Four sets of 12 with good depth.',
      activityId: 'squat',
      sets: 4,
      reps: 12,
    ),
    QuestSuggestion(
      id: 'q_cooldown',
      title: 'Cool-Down Stretch',
      description: 'Ten minutes of easy mobility to finish the week well.',
      activityId: 'stretching',
      durationSeconds: 600,
    ),
  ];

  /// Three suggestions for the given day, stable through the day and varied
  /// across days. Equipment-dependent quests are skipped without dumbbells,
  /// and preferred categories are listed first.
  static List<QuestSuggestion> dailySuggestions({
    required ExperienceLevel level,
    required DateTime day,
    required Set<ActivityCategory> preferred,
    required bool hasDumbbells,
    int count = 3,
  }) {
    final pool = switch (level) {
      ExperienceLevel.starting => _starting,
      ExperienceLevel.returning => _returning,
      ExperienceLevel.regular => _regular,
    }
        .where((q) => hasDumbbells || !q.needsDumbbells)
        .toList();

    final offset = startOfDay(day).difference(DateTime(2024)).inDays;
    final rotated = [
      for (var i = 0; i < pool.length; i++) pool[(i + offset) % pool.length],
    ];
    rotated.sort((a, b) {
      final pa = preferred.contains(a.activity.category) ? 0 : 1;
      final pb = preferred.contains(b.activity.category) ? 0 : 1;
      return pa.compareTo(pb); // stable: keeps the daily rotation within groups
    });
    return rotated.take(count).toList();
  }

  /// Days with any logged movement in the Monday-Sunday week containing [now].
  static WeeklyGoal weeklyGoal({
    required ExperienceLevel level,
    required DateTime now,
    required Iterable<WorkoutEntry> entries,
  }) {
    final today = startOfDay(now);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    final days = <String>{
      for (final e in entries)
        if (!e.performedAt.isBefore(monday) && e.performedAt.isBefore(nextMonday))
          dayKey(e.performedAt),
    };
    return WeeklyGoal(target: level.weeklyDaysGoal, daysActive: days.length);
  }
}
