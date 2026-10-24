import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feedback.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/quests.dart';
import '../../domain/recap.dart';
import '../../domain/rewards.dart';
import '../../domain/workout.dart';
import '../../game/core.dart' show Haptic;
import '../story/chronicle_screen.dart';
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
    final goal = QuestBoard.weeklyGoal(
      level: player.hero.experience,
      now: now,
      entries: workouts,
      target: player.hero.weeklyGoalTarget,
    );
    final active = QuestBoard.activeWeekdays(now: now, entries: workouts);
    final recap = WeeklyRecap.lastWeek(now: now, entries: workouts, goalDays: player.hero.weeklyGoalTarget, rules: rules);

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
          const _StreakPanel(),
          const SizedBox(height: 16),
          const ChroniclePanel(),
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
                          'A quiet day never takes anything away.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                _GoalPicker(
                  chosen: player.hero.weeklyGoalDays,
                  suggested: player.hero.experience.weeklyDaysGoal,
                  onChanged: (days) {
                    ref.read(feedbackProvider).haptic(Haptic.select);
                    ref.read(repositoryProvider).setWeeklyGoalDays(days);
                  },
                ),
              ],
            ),
          ),
          if (recap != null) ...[
            _RecapPanel(recap: recap, seed: recap.start.difference(DateTime(2024)).inDays ~/ 7),
            const SizedBox(height: 16),
          ],
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

/// Lets the player pick how many days a week to aim for. The goal never costs
/// anything to miss, so there is no wrong answer; it can be changed any time.
class _GoalPicker extends StatelessWidget {
  const _GoalPicker({required this.chosen, required this.suggested, required this.onChanged});

  /// The player's own choice, or 0 if they have not made one.
  final int chosen;
  final int suggested;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = chosen == 0 ? suggested : chosen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My goal, in days a week', style: TextStyle(fontWeight: FontWeight.w800, color: GameColors.inkSoft)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var d = 1; d <= 7; d++)
              ChoiceChip(
                key: Key('goal_$d'),
                label: Text('$d'),
                selected: current == d,
                tooltip: d == 1 ? '1 day a week' : '$d days a week',
                onSelected: (_) => onChanged(d == suggested ? 0 : d),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          chosen == 0
              ? 'Chad suggests $suggested for you. Pick any number that suits your week.'
              : 'Your own goal. Tap $suggested to go back to Chad\'s suggestion.',
          style: const TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          GameChip(text: '+${reward.xp} XP', icon: Icons.star_rounded),
                          GameChip(text: '+${reward.energy} Energy', icon: Icons.bolt_rounded, color: GameColors.teal),
                        ],
                      ),
                    ),
                    if (!done) ...[
                      const SizedBox(width: 8),
                      GameButton(
                        label: 'Start',
                        icon: Icons.play_arrow_rounded,
                        expanded: false,
                        small: true,
                        onPressed: onStart,
                      ),
                    ],
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
  const _WeekTokens({required this.active, required this.today, required this.goal, this.label});

  final Set<int> active;
  final int today;
  final WeeklyGoal goal;
  final String? label;

  @override
  Widget build(BuildContext context) {
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Semantics(
      label: label ?? 'Active days this week: ${goal.daysActive} of ${goal.target}',
      child: ExcludeSemantics(
        // The seven tokens share the width, so they shrink on a narrow phone
        // instead of running off the edge.
        child: LayoutBuilder(
          builder: (context, box) {
            final size = (box.maxWidth / 7 - 4).clamp(22.0, 38.0);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var d = 1; d <= 7; d++)
                  Column(
                    children: [
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active.contains(d) ? GameColors.gold : GameColors.woodDark,
                          border: Border.all(
                            color: d == today ? GameColors.cream : GameColors.wood,
                            width: d == today ? 3 : 2,
                          ),
                        ),
                        child: active.contains(d)
                            ? Icon(Icons.star_rounded, color: GameColors.goldDark, size: size * 0.62)
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
            );
          },
        ),
      ),
    );
  }
}


/// The streak: days active in a row, with rest days built in, and the next
/// reward. Never a countdown, and it never speaks of loss.
class _StreakPanel extends ConsumerWidget {
  const _StreakPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(streakProvider);
    final claimed = ref.watch(claimedStreaksProvider).value ?? const <int>{};
    if (s == null) return const SizedBox.shrink();
    final next = s.next!;
    final rest = s.allowedRestDays;
    return GamePanel(
      title: 'Streak',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 44, color: s.hasStreak ? const Color(0xFFFF7043) : GameColors.inkSoft),
              const SizedBox(width: 8),
              Semantics(
                label: s.hasStreak ? 'Streak: ${s.current} active days in a row' : 'No streak yet',
                child: ExcludeSemantics(child: Text('${s.current}', style: gameTitle(40))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.current == 1 ? 'active day in a row' : 'active days in a row',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: GameColors.ink),
                    ),
                    if (s.best > 0) ...[
                      const SizedBox(height: 4),
                      GameChip(text: 'Best ${s.best}', icon: Icons.emoji_events_rounded),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.hasStreak
                ? 'Any logged movement counts for the day.'
                : s.lapsed
                    ? 'A fresh start is a good start. Move on any day to begin a new run. Your best run stays on the wall.'
                    : 'Move on any day to start a streak.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text('Next: ${next.title}, at ${next.days} days', style: gameTitle(17)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: s.progressToNext,
              minHeight: 12,
              color: GameColors.gold,
              backgroundColor: const Color(0xFFE6D3A8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '+${next.coins} Coins and +${next.xp} XP',
            style: const TextStyle(fontWeight: FontWeight.w700, color: GameColors.inkSoft),
          ),
          const SizedBox(height: 12),
          Text(
            'Rest days are built in: up to $rest quiet ${rest == 1 ? 'day' : 'days'} in a row keep it going, '
            'so a weekend off never breaks it. Rewards come from showing up, not from doing more.',
            style: const TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600),
          ),
          if (claimed.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in (claimed.toList()..sort()))
                  GameChip(text: '$d Days', icon: Icons.check_circle_rounded, color: GameColors.cream),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A kind look back at last week. Shown only once there is a week to look back
/// on, and it only ever describes the player's own week.
class _RecapPanel extends StatelessWidget {
  const _RecapPanel({required this.recap, required this.seed});

  final WeekRecap recap;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final top = recap.mostLogged;
    return GamePanel(
      key: const Key('recap_panel'),
      title: WeeklyRecap.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(WeeklyRecap.chadLine(recap, seed: seed), style: const TextStyle(fontWeight: FontWeight.w600)),
          if (!recap.quiet) ...[
            const SizedBox(height: 12),
            _WeekTokens(
              active: recap.weekdays,
              today: 0,
              goal: WeeklyGoal(target: recap.goalDays, daysActive: recap.activeDays),
              label: 'Active days last week: ${WeeklyRecap.activeLabel(recap)}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GameChip(text: WeeklyRecap.activeLabel(recap), icon: Icons.star_rounded, color: GameColors.gold),
                GameChip(text: '${recap.effortMinutes.round()} Effort Min', icon: Icons.timer_outlined, color: GameColors.teal),
                if (top != null) GameChip(text: 'Most Logged: ${top.$1.name}', icon: Icons.favorite_rounded, color: GameColors.cream),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
