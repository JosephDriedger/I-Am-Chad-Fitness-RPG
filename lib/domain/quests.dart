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
      todays.any((e) => e.countsForRewards && e.activityId == activityId);
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

  // The pools below are ordered so that any three neighbours mix categories,
  // because the board shows three in a row (see dailySuggestions). A test checks it.

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
    QuestSuggestion(
      id: 'q_bird_dog',
      title: 'Bird-Dogs',
      description: 'Two sets of 6, slow and steady. Reach one arm and the opposite leg.',
      activityId: 'bird_dog',
      sets: 2,
      reps: 6,
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
      id: 'q_dance_5',
      title: 'A Song and a Dance',
      description: 'Put on one song and move however it tells you to.',
      activityId: 'dancing',
      durationSeconds: 300,
    ),
    QuestSuggestion(
      id: 'q_cat_cow',
      title: 'Cat-Cow',
      description: 'A few slow rounds on hands and knees, moving with your breath.',
      activityId: 'cat_cow',
      durationSeconds: 180,
    ),
    QuestSuggestion(
      id: 'q_glute_bridge',
      title: 'Glute Bridges',
      description: 'Two sets of 8. Lie on your back with knees bent and lift your hips a little.',
      activityId: 'glute_bridge',
      sets: 2,
      reps: 8,
    ),
    QuestSuggestion(
      id: 'q_walk_5',
      title: 'Five-Minute Wander',
      description: 'Round the house, round the garden, or up and down the hall.',
      activityId: 'walking',
      durationSeconds: 300,
    ),
    QuestSuggestion(
      id: 'q_small_crunch',
      title: 'Small Crunches',
      description: 'Two sets of 8. Tiny movements are plenty.',
      activityId: 'sit_up',
      sets: 2,
      reps: 8,
      variant: 'Small Crunch',
    ),
    QuestSuggestion(
      id: 'q_hip_circles',
      title: 'Hip Circles',
      description: 'Three minutes of slow circles, one way and then the other.',
      activityId: 'hip_circles',
      durationSeconds: 180,
    ),
    QuestSuggestion(
      id: 'q_calf_raises',
      title: 'Calf Raises',
      description: 'Two sets of 10 with a hand on the wall for balance.',
      activityId: 'calf_raise',
      sets: 2,
      reps: 10,
    ),
    QuestSuggestion(
      id: 'q_march',
      title: 'Marching on the Spot',
      description: 'Two sets of 10. Slow knees, as high as feels good.',
      activityId: 'high_knees',
      sets: 2,
      reps: 10,
    ),
    QuestSuggestion(
      id: 'q_child_pose',
      title: "Child's Pose",
      description: 'Two minutes of slow breathing. A cushion is welcome.',
      activityId: 'child_pose',
      durationSeconds: 120,
    ),
    QuestSuggestion(
      id: 'q_knee_pushups',
      title: 'Knee Push-Ups',
      description: 'Two sets of 6, nice and controlled.',
      activityId: 'push_up',
      sets: 2,
      reps: 6,
      variant: 'Knee',
    ),
    QuestSuggestion(
      id: 'q_dead_bug',
      title: 'Dead Bugs',
      description: 'Two sets of 6. Move your opposite arm and leg slowly.',
      activityId: 'dead_bug',
      sets: 2,
      reps: 6,
    ),
    QuestSuggestion(
      id: 'q_light_mobility',
      title: 'Loosen Up',
      description: 'Five minutes of shoulder rolls, wrist circles and gentle twists.',
      activityId: 'light_mobility',
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
      id: 'q_sun_salutation',
      title: 'Sun Salutations',
      description: 'Seven minutes of slow flowing. Soft knees, and skip anything you like.',
      activityId: 'sun_salutation',
      durationSeconds: 420,
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
      id: 'q_dance_15',
      title: 'Dance Break',
      description: 'A few songs, no choreography, all the enthusiasm you have.',
      activityId: 'dancing',
      durationSeconds: 900,
    ),
    QuestSuggestion(
      id: 'q_bird_dog_ret',
      title: 'Bird-Dog Sets',
      description: 'Three sets of 8, steady and slow.',
      activityId: 'bird_dog',
      sets: 3,
      reps: 8,
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
    QuestSuggestion(
      id: 'q_lunges',
      title: 'Lunges',
      description: 'Three sets of 8. Hold a wall or chair if you like.',
      activityId: 'lunge',
      sets: 3,
      reps: 8,
    ),
    QuestSuggestion(
      id: 'q_shadow_boxing',
      title: 'Shadow Boxing',
      description: 'Ten minutes of light, loose punches. Nobody is watching.',
      activityId: 'shadow_boxing',
      durationSeconds: 600,
    ),
    QuestSuggestion(
      id: 'q_cat_cow_ret',
      title: 'Cat-Cow Flow',
      description: 'Five minutes of slow rounds, then a rest in child\'s pose if you like.',
      activityId: 'cat_cow',
      durationSeconds: 300,
    ),
    QuestSuggestion(
      id: 'q_step_ups',
      title: 'Step-Ups',
      description: 'Three sets of 8 on a low, sturdy step.',
      activityId: 'step_up',
      sets: 3,
      reps: 8,
    ),
    QuestSuggestion(
      id: 'q_jacks',
      title: 'Jumping Jacks',
      description: 'Three sets of 12. Step them out instead of jumping if you prefer.',
      activityId: 'jumping_jacks',
      sets: 3,
      reps: 12,
    ),
    QuestSuggestion(
      id: 'q_glute_bridge_ret',
      title: 'Glute Bridge Sets',
      description: 'Three sets of 12, pausing briefly at the top.',
      activityId: 'glute_bridge',
      sets: 3,
      reps: 12,
    ),
    QuestSuggestion(
      id: 'q_goblet_squat',
      title: 'Goblet Squats',
      description: 'Three sets of 10, holding one light dumbbell at your chest.',
      activityId: 'goblet_squat',
      sets: 3,
      reps: 10,
      needsDumbbells: true,
    ),
    QuestSuggestion(
      id: 'q_side_plank',
      title: 'Side Planks',
      description: 'Two holds of 15 seconds each side. Knees down is welcome.',
      activityId: 'side_plank',
      sets: 2,
      durationSeconds: 15,
    ),
    QuestSuggestion(
      id: 'q_walk_30',
      title: 'A Long Walk',
      description: 'Half an hour, any route. Stop for a view whenever you like.',
      activityId: 'walking',
      durationSeconds: 1800,
    ),
    QuestSuggestion(
      id: 'q_hamstring',
      title: 'Hamstring Stretch',
      description: 'Five minutes, easy and slow. Do not bounce.',
      activityId: 'hamstring_stretch',
      durationSeconds: 300,
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
      id: 'q_cooldown',
      title: 'Cool-Down Stretch',
      description: 'Ten minutes of easy mobility to finish the week well.',
      activityId: 'stretching',
      durationSeconds: 600,
    ),
    QuestSuggestion(
      id: 'q_hollow',
      title: 'Hollow Holds',
      description: 'Three holds of 20 seconds. Bend your knees to make it easier.',
      activityId: 'hollow_hold',
      sets: 3,
      durationSeconds: 20,
    ),
    QuestSuggestion(
      id: 'q_burpees',
      title: 'Burpees',
      description: 'Three sets of 8. Step instead of jumping whenever you like.',
      activityId: 'burpee',
      sets: 3,
      reps: 8,
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
      id: 'q_flow',
      title: 'Sun Salutation Flow',
      description: 'Ten minutes of slow, connected movement with your breath.',
      activityId: 'sun_salutation',
      durationSeconds: 600,
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
      id: 'q_mountain_climbers',
      title: 'Mountain Climbers',
      description: 'Three sets of 20, at a pace you can keep.',
      activityId: 'mountain_climber',
      sets: 3,
      reps: 20,
    ),
    QuestSuggestion(
      id: 'q_shadow_boxing_reg',
      title: 'Shadow Boxing Rounds',
      description: 'Fifteen minutes of footwork and punches, with a breather whenever you want one.',
      activityId: 'shadow_boxing',
      durationSeconds: 900,
    ),
    QuestSuggestion(
      id: 'q_lunges_reg',
      title: 'Lunge Set',
      description: 'Four sets of 12, steady and tall.',
      activityId: 'lunge',
      sets: 4,
      reps: 12,
    ),
    QuestSuggestion(
      id: 'q_bicycle_crunch',
      title: 'Bicycle Crunches',
      description: 'Three sets of 16, slow enough to feel each one.',
      activityId: 'bicycle_crunch',
      sets: 3,
      reps: 16,
    ),
    QuestSuggestion(
      id: 'q_goblet_reg',
      title: 'Goblet Squat Set',
      description: 'Four sets of 10 holding one dumbbell at your chest.',
      activityId: 'goblet_squat',
      sets: 4,
      reps: 10,
      needsDumbbells: true,
    ),
    QuestSuggestion(
      id: 'q_jog_30',
      title: 'A Longer Jog',
      description: 'Half an hour at a conversational pace. Walk whenever it helps.',
      activityId: 'running',
      durationSeconds: 1800,
    ),
    QuestSuggestion(
      id: 'q_pike',
      title: 'Pike Push-Ups',
      description: 'Three sets of 8. Raise your hips and press with your shoulders.',
      activityId: 'pike_push_up',
      sets: 3,
      reps: 8,
    ),
    QuestSuggestion(
      id: 'q_wall_sit_reg',
      title: 'Wall Sits',
      description: 'Three holds of 30 seconds with your back on the wall.',
      activityId: 'wall_sit',
      sets: 3,
      durationSeconds: 30,
    ),
    QuestSuggestion(
      id: 'q_db_curl',
      title: 'Bicep Curls',
      description: 'Three sets of 12 at a weight you can control.',
      activityId: 'bicep_curl',
      sets: 3,
      reps: 12,
      needsDumbbells: true,
    ),
    QuestSuggestion(
      id: 'q_dance_reg',
      title: 'Dance It Out',
      description: 'Twenty minutes of whatever music makes you move.',
      activityId: 'dancing',
      durationSeconds: 1200,
    ),
  ];

  /// Every quest that could be suggested to someone at [level], in rotation order.
  static List<QuestSuggestion> poolFor(ExperienceLevel level, {bool hasDumbbells = true}) => [
        for (final q in switch (level) {
          ExperienceLevel.starting => _starting,
          ExperienceLevel.returning => _returning,
          ExperienceLevel.regular => _regular,
        })
          if (hasDumbbells || !q.needsDumbbells) q,
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
    final pool = poolFor(level, hasDumbbells: hasDumbbells);

    // Whole calendar days, counted in UTC so a clock change cannot shift it.
    final d = day.toLocal();
    final offset = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2024)).inDays;
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

  /// Midnight starting the Monday-Sunday week containing [now], and midnight
  /// starting the next one. Built from calendar dates rather than by adding 24
  /// hours, so a clock change inside the week cannot move the edges.
  static (DateTime, DateTime) weekBounds(DateTime now) {
    final today = startOfDay(now);
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
    return (monday, nextMonday);
  }

  /// Days with any logged movement in the Monday-Sunday week containing [now].
  static WeeklyGoal weeklyGoal({
    required ExperienceLevel level,
    required DateTime now,
    required Iterable<WorkoutEntry> entries,
    int? target,
  }) {
    final (monday, nextMonday) = weekBounds(now);
    final days = <String>{
      for (final e in entries)
        if (e.countsForRewards && !e.performedAt.isBefore(monday) && e.performedAt.isBefore(nextMonday))
          dayKey(e.performedAt),
    };
    return WeeklyGoal(target: target ?? level.weeklyDaysGoal, daysActive: days.length);
  }

  /// Weekday numbers (1 = Monday ... 7 = Sunday) with any logged movement in
  /// the week containing [now]. Used to show the week as a row of tokens.
  static Set<int> activeWeekdays({
    required DateTime now,
    required Iterable<WorkoutEntry> entries,
  }) {
    final (monday, nextMonday) = weekBounds(now);
    return {
      for (final e in entries)
        if (e.countsForRewards && !e.performedAt.isBefore(monday) && e.performedAt.isBefore(nextMonday))
          e.performedAt.toLocal().weekday,
    };
  }
}
