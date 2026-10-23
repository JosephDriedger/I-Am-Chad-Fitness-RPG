import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/quests.dart';
import '../../domain/rewards.dart';
import '../../domain/workout.dart';
import '../workout/log_workout_screen.dart';
import '../workout/workout_screen.dart';

/// The quest board: pinned quest cards with reward previews and a weekly
/// goal shown as seven day tokens.
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final workouts = ref.watch(workoutsProvider).value ?? const [];
    final now = ref.watch(clockProvider)();
    final rules = ref.watch(repositoryProvider).rules;

    if (player == null) {
      return const GameScaffold(title: 'Quests', child: Center(child: CircularProgressIndicator()));
    }

    final today = workouts.where((w) => dayKey(w.performedAt) == dayKey(now)).toList();
    final quests = QuestBoard.dailySuggestions(
      level: player.hero.experience,
      day: now,
      preferred: player.hero.preferredCategories,
      hasDumbbells: player.hero.hasDumbbells,
      count: 4,
    );
    final goal = QuestBoard.weeklyGoal(level: player.hero.experience, now: now, entries: workouts);
    final active = QuestBoard.activeWeekdays(now: now, entries: workouts);

    return GameScaffold(
      title: 'Quests',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          _Board(
            children: [
              for (var i = 0; i < quests.length; i++)
                _QuestCard(
                  quest: quests[i],
                  tilt: (i.isEven ? -1 : 1) * 0.012,
                  done: quests[i].isDoneBy(today),
                  reward: () {
                    final q = quests[i];
                    final entry = WorkoutEntry(
                      activityId: q.activityId,
                      performedAt: now,
                      sets: q.sets,
                      reps: q.reps,
                      durationSeconds: q.durationSeconds,
                    );
                    return rules.rewardForDay([entry]);
                  }(),
                  onStart: () => Navigator.of(context).push(
                    gameRoute(LogWorkoutScreen(activity: quests[i].activity, quest: quests[i])),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Totally optional. Do one, do all, or do something else entirely.',
              style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          GamePanel(
            title: 'Weekly Goal',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WeekTokens(active: active, today: now.weekday, goal: goal),
                const SizedBox(height: 12),
                Text(
                  goal.met
                      ? 'Goal reached! Anything extra is a bonus, and rest days are well earned.'
                      : 'Move on ${goal.target} days this week, with any activity. '
                          'There are no streaks: a quiet day never resets anything.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GamePanel(
            title: 'Self-Directed Adventures',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Make Your Own Quest: log anything from Train and it counts the same as a suggestion.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                GameButton(
                  label: 'Open the Training Yard',
                  icon: Icons.fitness_center,
                  kind: GameButtonKind.secondary,
                  onPressed: () => Navigator.of(context).push(
                    gameRoute(const GameScaffold(title: 'Train', child: WorkoutScreen())),
                  ),
                ),
              ],
            ),
          ),
          const SafetyNote(),
        ],
      ),
    );
  }
}

/// A wooden board the quest cards are pinned to.
class _Board extends StatelessWidget {
  const _Board({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.woodLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GameColors.woodDark, width: 5),
        boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 4))],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9A6A3E), Color(0xFF7A4F2B)],
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  const _QuestCard({
    required this.quest,
    required this.tilt,
    required this.done,
    required this.reward,
    required this.onStart,
  });

  final QuestSuggestion quest;
  final double tilt;
  final bool done;
  final DayReward reward;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final still = MediaQuery.of(context).disableAnimations;
    return Transform.rotate(
      angle: still ? 0 : tilt,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            decoration: BoxDecoration(
              color: done ? const Color(0xFFE6DCC0) : const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(2, 4), blurRadius: 2)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(quest.title, style: gameTitle(21))),
                    Icon(
                      done ? Icons.check_circle : Icons.flag_rounded,
                      color: done ? GameColors.green : GameColors.goldDark,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  done ? 'Done today. Nice work!' : quest.description,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: GameColors.inkSoft),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GameChip(text: '+${reward.xp} XP', icon: Icons.star_rounded),
                    const SizedBox(width: 8),
                    GameChip(text: '+${reward.energy} Energy', icon: Icons.bolt_rounded, color: GameColors.teal),
                    const Spacer(),
                    if (!done)
                      GameButton(
                        label: 'Start',
                        icon: Icons.play_arrow_rounded,
                        expanded: false,
                        small: true,
                        onPressed: onStart,
                      ),
                  ],
                ),
              ],
            ),
          ),
          // The pin.
          const Positioned(
            top: -6,
            left: 0,
            right: 0,
            child: Center(child: _Pin()),
          ),
          if (done)
            Positioned(
              right: 14,
              bottom: 16,
              child: Transform.rotate(
                angle: -0.22,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: GameColors.green, width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('DONE', style: gameTitle(24, color: GameColors.green)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: GameColors.red,
          shape: BoxShape.circle,
          border: Border.all(color: GameColors.redDark, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(1, 2))],
        ),
      );
}

class _WeekTokens extends StatelessWidget {
  const _WeekTokens({required this.active, required this.today, required this.goal});

  final Set<int> active;
  final int today;
  final WeeklyGoal goal;

  @override
  Widget build(BuildContext context) {
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Semantics(
      label: 'Active days this week: ${goal.daysActive} of ${goal.target}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var d = 1; d <= 7; d++)
              Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active.contains(d) ? GameColors.gold : GameColors.woodDark,
                      border: Border.all(
                        color: d == today ? GameColors.cream : GameColors.wood,
                        width: d == today ? 3 : 2,
                      ),
                    ),
                    child: active.contains(d)
                        ? const Icon(Icons.star_rounded, color: GameColors.goldDark, size: 24)
                        : null,
                  ),
                  const SizedBox(height: 3),
                  Text(letters[d - 1],
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: d == today ? GameColors.ink : GameColors.inkSoft,
                      )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

