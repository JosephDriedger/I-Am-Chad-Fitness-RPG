/// Small value types describing the player's saved game state.
library;

import 'hero.dart';
import 'items.dart';

/// Derived reward for one local day (see RewardRules).
class DayGrant {
  const DayGrant({
    required this.day,
    required this.effortMinutes,
    required this.creditedMinutes,
    required this.xp,
    required this.energy,
    required this.rulesVersion,
  });

  final String day;
  final double effortMinutes;
  final double creditedMinutes;
  final int xp;
  final int energy;
  final int rulesVersion;
}

class OwnedItem {
  const OwnedItem({
    required this.itemId,
    required this.acquiredAt,
    required this.equipped,
  });

  final String itemId;
  final DateTime acquiredAt;
  final bool equipped;

  EquipmentItem? get item => ItemCatalog.byId(itemId);
}

class AppPrefs {
  const AppPrefs({
    this.useMetric = true,
    this.reducedMotion = false,
    this.quietChad = false,
    this.soundOn = true,
    this.hapticsOn = true,
  });

  final bool useMetric;
  final bool reducedMotion;

  /// Fewer unprompted Chad lines, for experienced users.
  final bool quietChad;
  final bool soundOn;
  final bool hapticsOn;

  AppPrefs copyWith({
    bool? useMetric,
    bool? reducedMotion,
    bool? quietChad,
    bool? soundOn,
    bool? hapticsOn,
  }) =>
      AppPrefs(
        useMetric: useMetric ?? this.useMetric,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        quietChad: quietChad ?? this.quietChad,
        soundOn: soundOn ?? this.soundOn,
        hapticsOn: hapticsOn ?? this.hapticsOn,
      );
}

/// Everything the UI needs about the hero, combined from stored data and
/// derived rewards.
class PlayerStatus {
  const PlayerStatus({
    required this.hero,
    required this.activityXp,
    required this.energyEarned,
    required this.equipped,
  });

  final HeroProfile hero;
  final int activityXp;
  final int energyEarned;
  final List<EquipmentItem> equipped;

  int get totalXp => activityXp + hero.adventureXp + hero.streakXp;
  int get level => Progression.levelForXp(totalXp);
  double get levelProgress => Progression.levelProgress(totalXp);
  int get levelStartXp => Progression.xpForLevel(level);
  int get levelSizeXp => Progression.xpForLevel(level + 1) - levelStartXp;
  int get xpToNext => Progression.xpForLevel(level + 1) - totalXp;

  /// Never negative, even if a workout is deleted after its energy was spent.
  int get energy {
    final e = energyEarned - hero.energySpent;
    return e < 0 ? 0 : e;
  }

  int get maxHp =>
      Progression.maxHp(level) + equipped.fold(0, (a, i) => a + i.hp);
  int get attack =>
      Progression.attack(level) + equipped.fold(0, (a, i) => a + i.attack);
  int get defense =>
      Progression.defense(level) + equipped.fold(0, (a, i) => a + i.defense);
}
