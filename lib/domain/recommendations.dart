/// Daily exercise recommendations: a few things to try today that go with the
/// quests on the board, and exercises the player has not logged before. See
/// docs/CONTENT_GUIDELINES.md (Daily quests) before changing the wording.
///
/// These are ideas, never tasks:
///  * Entirely optional, and they sit beside the quests without replacing them.
///  * They change with the day, and stay the same through the day, even after
///    something is logged, so the list never shuffles under someone's thumb.
///  * They only suggest what fits: nothing needing equipment the player may not
///    have, and nothing too demanding for someone just starting.
///  * They never say what someone has not done, never count or compare, and
///    never change a reward. Logging one pays exactly what any entry pays.
library;

import 'activity.dart';
import 'hero.dart';
import 'quests.dart';
import 'workout.dart';

enum RecommendationKind {
  /// Goes well with one of today's quests, from a different part of fitness, so
  /// a day feels balanced (strength with a stretch, a walk with core work).
  pairsWith,

  /// Something the player has not logged before.
  newToYou,

  /// Something they enjoyed before and have not done for a while.
  anotherGo,
}

class Recommendation {
  const Recommendation({required this.activity, required this.kind, required this.plan, this.partner});

  final ActivityType activity;
  final RecommendationKind kind;

  /// A gentle starting amount, which also pre-fills the log screen.
  final QuestSuggestion plan;

  /// For [RecommendationKind.pairsWith]: the quest it goes with.
  final QuestSuggestion? partner;

  /// Why it is on the list, in a few kind words.
  String get reason => switch (kind) {
        RecommendationKind.pairsWith => 'Goes well with ${partner!.title}',
        RecommendationKind.newToYou => 'Something new to try',
        RecommendationKind.anotherGo => 'An old favourite, if you fancy it',
      };

  bool isDoneBy(Iterable<WorkoutEntry> todays) => plan.isDoneBy(todays);
}

class Recommendations {
  const Recommendations._();

  /// How many to show.
  static const defaultCount = 3;

  /// A different kind of exercise to go beside each kind, for a balanced day.
  static const pairs = <ActivityCategory, List<ActivityCategory>>{
    ActivityCategory.bodyweight: [ActivityCategory.core, ActivityCategory.mobility],
    ActivityCategory.core: [ActivityCategory.bodyweight, ActivityCategory.mobility],
    ActivityCategory.cardio: [ActivityCategory.mobility, ActivityCategory.core],
    ActivityCategory.resistance: [ActivityCategory.mobility, ActivityCategory.core],
    ActivityCategory.mobility: [ActivityCategory.cardio, ActivityCategory.bodyweight],
    ActivityCategory.sports: [ActivityCategory.mobility, ActivityCategory.core],
  };

  /// Held back from someone who is just starting.
  static const demandingForBeginners = {
    'jump_squat', 'burpee', 'mountain_climber', 'pike_push_up', 'hollow_hold', 'running', 'hiking', 'martial_arts',
  };

  /// Held back unless someone is already active.
  static const demandingForReturning = {'burpee', 'jump_squat'};

  /// A mark has to be this old before it is offered again as "an old favourite".
  static const anotherGoAfterDays = 14;

  /// What can be done with what most homes have, plus dumbbells if the player has them.
  static bool fits(ActivityType a, {required ExperienceLevel level, required bool hasDumbbells}) {
    final equipmentOk = a.equipment.atHome || (a.equipment == Equipment.dumbbells && hasDumbbells);
    if (!equipmentOk) return false;
    return switch (level) {
      ExperienceLevel.starting => !demandingForBeginners.contains(a.id),
      ExperienceLevel.returning => !demandingForReturning.contains(a.id),
      ExperienceLevel.regular => true,
    };
  }

  /// Up to [count] recommendations for [day].
  ///
  /// [quests] are the quests on today's board. [history] is the whole journal:
  /// what counts as "new" is judged from before today, so a list does not change
  /// once something on it has been logged.
  static List<Recommendation> forDay({
    required ExperienceLevel level,
    required DateTime day,
    required Set<ActivityCategory> preferred,
    required bool hasDumbbells,
    required List<QuestSuggestion> quests,
    required Iterable<WorkoutEntry> history,
    int count = defaultCount,
  }) {
    final today = startOfDay(day);
    final lastDone = <String, DateTime>{};
    for (final e in history) {
      if (!e.performedAt.toLocal().isBefore(today)) continue;
      final held = lastDone[e.activityId];
      if (held == null || e.performedAt.isAfter(held)) lastDone[e.activityId] = e.performedAt;
    }
    final questIds = {for (final q in quests) q.activityId};
    final eligible = [
      for (final a in ActivityCatalog.all)
        if (fits(a, level: level, hasDumbbells: hasDumbbells) && !questIds.contains(a.id)) a,
    ];
    final unseen = [for (final a in eligible) if (!lastDone.containsKey(a.id)) a];

    // Whole calendar days, counted in UTC so a clock change cannot shift it.
    final d = day.toLocal();
    final offset = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2024)).inDays;

    final out = <Recommendation>[];
    final chosen = <String>{};

    Recommendation make(ActivityType a, RecommendationKind kind, {QuestSuggestion? partner}) {
      chosen.add(a.id);
      return Recommendation(activity: a, kind: kind, plan: planFor(a, level), partner: partner);
    }

    // One that goes with a quest, a different quest each day.
    if (quests.isNotEmpty && count > 0) {
      for (var k = 0; k < quests.length; k++) {
        final quest = quests[(offset + k) % quests.length];
        final categories = pairs[quest.activity.category] ?? const <ActivityCategory>[];
        var candidates = [for (final a in eligible) if (categories.contains(a.category)) a];
        // Something new is the nicest partner, when there is any.
        final fresh = [for (final a in candidates) if (!lastDone.containsKey(a.id)) a];
        if (fresh.isNotEmpty) candidates = fresh;
        if (candidates.isEmpty) continue;
        out.add(make(candidates[(offset + k) % candidates.length], RecommendationKind.pairsWith, partner: quest));
        break;
      }
    }

    // Then things they have not done before, the kinds they like first, and not two of a kind in a row.
    final fresh = [for (final a in unseen) if (!chosen.contains(a.id)) a];
    List<ActivityType> rotate(List<ActivityType> l) =>
        l.isEmpty ? l : [...l.skip(offset % l.length), ...l.take(offset % l.length)];
    final ordered = [
      ...rotate([for (final a in fresh) if (preferred.contains(a.category)) a]),
      ...rotate([for (final a in fresh) if (!preferred.contains(a.category)) a]),
    ];
    final usedCategories = {for (final r in out) r.activity.category};
    for (final a in ordered) {
      if (out.length >= count) break;
      // The first pass keeps to kinds not already on the list.
      if (usedCategories.contains(a.category)) continue;
      out.add(make(a, RecommendationKind.newToYou));
      usedCategories.add(a.category);
    }
    for (final a in ordered) {
      if (out.length >= count) break;
      if (!chosen.contains(a.id)) out.add(make(a, RecommendationKind.newToYou));
    }

    // If there is not enough that is new, an old favourite that has had a rest.
    if (out.length < count) {
      final cutoff = today.subtract(const Duration(days: anotherGoAfterDays));
      final rested = [
        for (final a in eligible)
          if (!chosen.contains(a.id) && lastDone[a.id] != null && !lastDone[a.id]!.isAfter(cutoff)) a,
      ]..sort((a, b) => lastDone[a.id]!.compareTo(lastDone[b.id]!));
      for (final a in rested) {
        if (out.length >= count) break;
        out.add(make(a, RecommendationKind.anotherGo));
      }
    }
    return out;
  }

  /// A gentle amount to start with, and the words for it. The easiest version is
  /// suggested to anyone who is not already active.
  static QuestSuggestion planFor(ActivityType a, ExperienceLevel level) {
    final variant = a.variants.isNotEmpty && level != ExperienceLevel.regular ? a.variants.first : null;
    final tail = variant == null ? '' : ' ($variant)';
    int? sets, reps, seconds;
    String how;
    if (a.metrics.contains(Metric.sets) && a.metrics.contains(Metric.reps)) {
      sets = 2;
      reps = a.category == ActivityCategory.core ? 10 : 8;
      how = '2 sets of $reps$tail';
    } else if (a.metrics.contains(Metric.sets) && a.metrics.contains(Metric.duration)) {
      sets = 2;
      seconds = 20;
      how = '2 holds of 20 seconds$tail';
    } else if (a.usesDuration) {
      final minutes = switch (a.category) {
        ActivityCategory.mobility => 3,
        ActivityCategory.sports => 10,
        ActivityCategory.cardio => a.metrics.contains(Metric.distance) ? 10 : 5,
        _ => 5,
      };
      seconds = minutes * 60;
      how = '$minutes minutes$tail';
    } else {
      how = 'A little, at your own pace$tail';
    }
    return QuestSuggestion(
      id: 'rec_${a.id}',
      title: a.name,
      description: how,
      activityId: a.id,
      sets: sets,
      reps: reps,
      durationSeconds: seconds,
      variant: variant,
    );
  }
}
