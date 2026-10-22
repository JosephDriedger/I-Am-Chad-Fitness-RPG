import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/quests.dart';
import '../../domain/workout.dart';
import '../workout/log_workout_screen.dart';

class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final workouts = ref.watch(workoutsProvider).value ?? const [];
    final now = ref.watch(clockProvider)();
    final t = Theme.of(context).textTheme;

    if (player == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = workouts
        .where((w) => dayKey(w.performedAt) == dayKey(now))
        .toList();
    final quests = QuestBoard.dailySuggestions(
      level: player.hero.experience,
      day: now,
      preferred: player.hero.preferredCategories,
      hasDumbbells: player.hero.hasDumbbells,
      count: 4,
    );
    final goal = QuestBoard.weeklyGoal(
      level: player.hero.experience,
      now: now,
      entries: workouts,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Quests')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Today\'s suggestions', style: t.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Totally optional. Do one, do all, or do something else entirely.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 12),
            for (final q in quests)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: QuestTile(
                  quest: q,
                  done: q.isDoneBy(today),
                  onStart: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        LogWorkoutScreen(activity: q.activity, quest: q),
                  )),
                ),
              ),
            const SizedBox(height: 16),
            Text('Weekly goal', style: t.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatBar(
                      label: 'Days with some movement',
                      value: goal.daysActive.clamp(0, goal.target),
                      max: goal.target,
                      icon: Icons.calendar_month_outlined,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your goal is ${goal.target} days a week, any activity. '
                      'There are no streaks: a quiet day never resets anything.',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Self-directed adventures', style: t.titleMedium),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.explore_outlined),
                title: Text('Make your own quest'),
                subtitle: Text(
                  'Log anything from the Workout tab and it counts the same '
                  'as a suggestion.',
                ),
              ),
            ),
            const SafetyNote(),
          ],
        ),
      ),
    );
  }
}
