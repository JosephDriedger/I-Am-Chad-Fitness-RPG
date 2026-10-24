/// Player character data and level progression.
library;

import 'dart:math' as math;

import 'activity.dart';

enum ExperienceLevel {
  starting('Just Starting', 'New to exercise. Keep it gentle.'),
  returning('Getting Back Into It', 'Some experience, easing back in.'),
  regular('Already Active', 'Exercise is part of my week.');

  const ExperienceLevel(this.label, this.blurb);
  final String label;
  final String blurb;

  /// Flexible weekly goal (days with any movement). Streaks are separate (see streaks.dart).
  int get weeklyDaysGoal => switch (this) {
        ExperienceLevel.starting => 2,
        ExperienceLevel.returning => 3,
        ExperienceLevel.regular => 4,
      };
}

class HeroProfile {
  const HeroProfile({
    required this.name,
    required this.appearanceStyle,
    required this.appearanceColor,
    this.appearanceSkin = 0,
    required this.experience,
    required this.preferredCategories,
    required this.hasDumbbells,
    this.energySpent = 0,
    this.adventureXp = 0,
    this.coins = 0,
    this.victories = 0,
    this.streakXp = 0,
    this.potionStock = 0,
    this.cape = 'classic',
    this.hairDye = '',
  });

  final String name;
  final int appearanceStyle;
  final int appearanceColor;
  final int appearanceSkin;
  final ExperienceLevel experience;
  final Set<ActivityCategory> preferredCategories;
  final bool hasDumbbells;
  final int energySpent;

  /// XP earned from adventures (activity XP is derived from workouts).
  final int adventureXp;
  final int coins;
  final int victories;

  /// XP paid out for streak milestones.
  final int streakXp;

  /// Healing potions in the pouch, bought from the shop.
  final int potionStock;

  /// Chosen cape and hair dye (ids from cosmetics.dart). Looks only.
  final String cape;
  final String hairDye;

  HeroProfile copyWith({
    String? name,
    int? appearanceStyle,
    int? appearanceColor,
    int? appearanceSkin,
    ExperienceLevel? experience,
    Set<ActivityCategory>? preferredCategories,
    bool? hasDumbbells,
    int? energySpent,
    int? adventureXp,
    int? coins,
    int? victories,
    int? streakXp,
    int? potionStock,
    String? cape,
    String? hairDye,
  }) =>
      HeroProfile(
        name: name ?? this.name,
        appearanceStyle: appearanceStyle ?? this.appearanceStyle,
        appearanceColor: appearanceColor ?? this.appearanceColor,
        appearanceSkin: appearanceSkin ?? this.appearanceSkin,
        experience: experience ?? this.experience,
        preferredCategories: preferredCategories ?? this.preferredCategories,
        hasDumbbells: hasDumbbells ?? this.hasDumbbells,
        energySpent: energySpent ?? this.energySpent,
        adventureXp: adventureXp ?? this.adventureXp,
        coins: coins ?? this.coins,
        victories: victories ?? this.victories,
        streakXp: streakXp ?? this.streakXp,
        potionStock: potionStock ?? this.potionStock,
        cape: cape ?? this.cape,
        hairDye: hairDye ?? this.hairDye,
      );
}

/// Level curve: cumulative XP needed to reach level `n` is `60 * (n-1)^1.6`.
class Progression {
  const Progression._();

  static const int maxLevel = 99;

  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return (60 * math.pow(level - 1, 1.6)).round();
  }

  static int levelForXp(int totalXp) {
    var level = 1;
    while (level < maxLevel && totalXp >= xpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// 0.0-1.0 progress through the current level.
  static double levelProgress(int totalXp) {
    final level = levelForXp(totalXp);
    if (level >= maxLevel) return 1;
    final lo = xpForLevel(level);
    final hi = xpForLevel(level + 1);
    return (totalXp - lo) / (hi - lo);
  }

  /// Soft-capped stat growth: gains slow down as the level rises, which
  /// prevents runaway power. The marginal gain per level is ~56% of the
  /// starting rate at level 10 and ~25% at level 30.
  static double softLevel(int level) => level * 30 / (level + 30);

  static int maxHp(int level) => (40 + 6 * softLevel(level)).round();
  static int attack(int level) => (8 + 1.6 * softLevel(level)).round();
  static int defense(int level) => (4 + 0.9 * softLevel(level)).round();
}
