import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/chad.dart';
import '../../domain/player_state.dart';
import '../../domain/quests.dart';
import '../../domain/workout.dart';
import '../settings/settings_screen.dart';
import '../workout/log_workout_screen.dart';
import 'quests_screen.dart';

class GuildScreen extends ConsumerWidget {
  const GuildScreen({
    super.key,
    required this.onOpenWorkout,
    required this.onOpenAdventure,
  });

  final VoidCallback onOpenWorkout;
  final VoidCallback onOpenAdventure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final workouts = ref.watch(workoutsProvider).value ?? const [];
    final prefs = ref.watch(prefsProvider);
    final now = ref.watch(clockProvider)();
    if (player == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final todayKey = dayKey(now);
    final today = workouts.where((w) => dayKey(w.performedAt) == todayKey).toList();
    final goal = QuestBoard.weeklyGoal(
      level: player.hero.experience,
      now: now,
      entries: workouts,
    );
    final quests = QuestBoard.dailySuggestions(
      level: player.hero.experience,
      day: now,
      preferred: player.hero.preferredCategories,
      hasDumbbells: player.hero.hasDumbbells,
    );
    final next = quests.where((q) => !q.isDoneBy(today)).firstOrNull;

    final ctx = workouts.isEmpty
        ? ChadContext.welcome
        : today.isNotEmpty
            ? ChadContext.afterWorkout
            : goal.met
                ? ChadContext.restDay
                : ChadContext.idle;
    final seed = now.difference(DateTime(now.year)).inDays;

    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: Text('The Guild', style: t.headlineSmall)),
            IconButton(
              tooltip: 'Quests',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuestsScreen())),
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!(prefs.quietChad && workouts.isNotEmpty))
          ChadBubble(text: ChadDialogue.line(ctx, seed: seed)),
        const SizedBox(height: 16),
        _HeroCard(player: player),
        const SizedBox(height: 16),
        Text('Next up', style: t.titleMedium),
        const SizedBox(height: 8),
        if (next != null)
          QuestTile(
            quest: next,
            done: false,
            onStart: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LogWorkoutScreen(activity: next.activity, quest: next),
            )),
          )
        else
          const Card(
            child: ListTile(
              leading: Icon(Icons.celebration_outlined),
              title: Text('Today\'s suggestions are all done'),
              subtitle: Text('Wonderful. Rest, play, or go on an adventure.'),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpenWorkout,
                icon: const Icon(Icons.edit_note),
                label: const Text('Log your own'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpenAdventure,
                icon: const Icon(Icons.explore),
                label: const Text('Adventure'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _WeeklyGoalCard(goal: goal),
        const SafetyNote(),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.player});

  final PlayerStatus player;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final h = player.hero;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                HeroAvatar(
                    style: h.appearanceStyle, color: h.appearanceColor, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name, style: t.titleLarge),
                      Text('Level ${player.level}', style: t.titleSmall),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          StatChip(
                            icon: Icons.bolt,
                            text: '${player.energy} energy',
                            tip: 'Adventure energy: ${player.energy}',
                          ),
                          StatChip(
                            icon: Icons.monetization_on_outlined,
                            text: '${h.coins}',
                            tip: '${h.coins} coins',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatBar(
              label: 'XP to next level',
              value: player.totalXp - player.levelStartXp,
              max: player.levelSizeXp,
              icon: Icons.star_outline,
            ),
          ],
        ),
      ),
    );
  }

}

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({required this.goal});

  final WeeklyGoal goal;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This week', style: t.titleMedium),
            const SizedBox(height: 8),
            StatBar(
              label: 'Active days',
              value: goal.daysActive.clamp(0, goal.target),
              max: goal.target,
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 8),
            Text(
              goal.met
                  ? 'Weekly goal reached. Anything extra is a bonus, and rest '
                      'days are well earned.'
                  : 'A flexible goal. Rest days are part of training, and a '
                      'missed day never costs you anything.',
              style: t.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
