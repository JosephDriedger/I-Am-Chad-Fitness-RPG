/// Looks that change how the hero and the guild hall are drawn, and nothing
/// else. There is no stat, bonus or reward on any type here, on purpose.
///
/// Each look is unlocked in one of three ways: it is free to everyone, it is
/// earned by playing (a level, a story chapter, a streak), or it comes with the
/// optional Patron Pack (see patronage.dart). Earned looks are never harder to
/// reach than the exercise the game already asks for, and the patron looks are
/// extra choices, not better ones.
library;

import 'patronage.dart';
import 'story.dart';

enum UnlockKind { free, level, chapter, victories, streak, workouts, patron }

/// How a cosmetic becomes available.
class Unlock {
  const Unlock._(this.kind, [this.n = 0]);

  static const free = Unlock._(UnlockKind.free);
  static const patron = Unlock._(UnlockKind.patron);
  static const firstWorkout = Unlock._(UnlockKind.workouts, 1);
  const Unlock.level(int n) : this._(UnlockKind.level, n);
  const Unlock.chapter(int n) : this._(UnlockKind.chapter, n);
  const Unlock.victories(int n) : this._(UnlockKind.victories, n);
  const Unlock.streak(int days) : this._(UnlockKind.streak, days);

  final UnlockKind kind;
  final int n;

  bool get isPatron => kind == UnlockKind.patron;
  bool get isEarned => kind != UnlockKind.free && kind != UnlockKind.patron;

  bool isMet(CosmeticContext c) => switch (kind) {
        UnlockKind.free => true,
        UnlockKind.patron => c.patron,
        UnlockKind.level => c.level >= n,
        UnlockKind.chapter => c.chaptersRead.contains(n),
        UnlockKind.victories => c.victories >= n,
        UnlockKind.streak => c.claimedStreakDays.any((d) => d >= n),
        UnlockKind.workouts => c.workouts >= n,
      };

  /// The season whose last chapter is [chapter], if it is one.
  static StorySeason? _finishedSeason(int chapter) {
    for (final s in Story.seasons) {
      if (Story.inSeason(s.number).last.number == chapter) return s;
    }
    return null;
  }

  /// Says how to get it, calmly and without pressure.
  String get hint => switch (kind) {
        UnlockKind.free => 'Free',
        UnlockKind.patron => 'Patron Pack',
        UnlockKind.level => 'Earned at Level $n',
        UnlockKind.chapter => _finishedSeason(n) != null
            ? 'Earned by finishing the ${_finishedSeason(n)!.name} story'
            : 'Earned by reading chapter $n',
        UnlockKind.victories => n == 1 ? 'Earned by winning an expedition' : 'Earned by winning $n expeditions',
        UnlockKind.streak => 'Earned at a $n-day streak',
        UnlockKind.workouts => 'Earned by logging your first workout',
      };
}

/// What the player has done and owns, as far as cosmetics care.
class CosmeticContext {
  const CosmeticContext({
    this.level = 1,
    this.chaptersRead = const {},
    this.victories = 0,
    this.claimedStreakDays = const {},
    this.workouts = 0,
    this.patron = false,
  });

  final int level;
  final Set<int> chaptersRead;
  final int victories;

  /// Streak milestones already claimed (a claimed milestone is never taken back).
  final Set<int> claimedStreakDays;
  final int workouts;

  /// Owns the Patron Pack.
  final bool patron;
}

/// A cape. `color` null means the cape follows the hero's tunic colour, as it
/// always has.
class Cape {
  const Cape(this.id, this.name, this.unlock, {this.color, this.trim, this.stars = false});

  /// Stored in the save. Never rename.
  final String id;
  final String name;
  final Unlock unlock;
  final int? color;
  final int? trim;
  final bool stars;
}

class HairDye {
  const HairDye(this.id, this.name, this.unlock, this.color);

  /// Stored in the save. Never rename.
  final String id;
  final String name;
  final Unlock unlock;
  final int color;
}

/// A pennant on the hall's bunting. Earned by playing, never sold, and
/// never taken away.
class Pennant {
  const Pennant(this.id, this.name, this.unlock, this.color);

  final String id;
  final String name;
  final Unlock unlock;
  final int color;
}

/// What a trophy on the Journal shelf looks like.
enum TrophyShape { lantern, chime, cup, star, shield, sun, table, crown, flame }

/// A trophy on the Journal shelf, for the bigger milestones. Earned by playing,
/// never sold, and never taken away.
class Trophy {
  const Trophy(this.id, this.name, this.unlock, this.shape);

  final String id;
  final String name;
  final Unlock unlock;
  final TrophyShape shape;
}

/// Things the Patron Pack adds to the guild hall.
class PatronDecor {
  const PatronDecor._();

  static const rosette = 'rosette';
  static const lights = 'lights';
  static const lantern = 'lantern';
  static const all = <String>{rosette, lights, lantern};
}

class Cosmetics {
  const Cosmetics._();

  static const classicCapeId = 'classic';
  static const naturalDyeId = '';

  static const capes = <Cape>[
    Cape(classicCapeId, 'Classic Cape', Unlock.free),
    Cape('dawn', 'Dawn Mantle', Unlock.chapter(7), color: 0xFFF2A65A, trim: 0xFFFFE9B0),
    Cape('lantern', 'Lantern Mantle', Unlock.chapter(15), color: 0xFF1F7A8C, trim: 0xFFFFC857),
    Cape('chime', 'Chime Mantle', Unlock.chapter(23), color: 0xFF6A7FBF, trim: 0xFFE6EEF8),
    Cape('table', 'Table Mantle', Unlock.chapter(31), color: 0xFF8E3B46, trim: 0xFFFFF3D6),
    Cape('hearth', 'Hearth Mantle', Unlock.chapter(39), color: 0xFF9A3412, trim: 0xFFFFB74D),
    Cape('crimson', 'Crimson Mantle', Unlock.patron, color: 0xFFB3202F, trim: 0xFFF2C94C),
    Cape('starlit', 'Starlit Mantle', Unlock.patron, color: 0xFF1F2F66, trim: 0xFFB9C7FF, stars: true),
    Cape('aurora', 'Aurora Mantle', Unlock.patron, color: 0xFF1F8F86, trim: 0xFFC9A6FF),
  ];

  static const dyes = <HairDye>[
    HairDye('sunrise', 'Sunrise', Unlock.level(5), 0xFFE8703A),
    HairDye('moonlit', 'Moonlit', Unlock.level(10), 0xFFC9D3E3),
    HairDye('ember', 'Ember', Unlock.level(20), 0xFFD84B2A),
    HairDye('glacier', 'Glacier', Unlock.level(30), 0xFF8FD3F4),
    HairDye('sunstone', 'Sunstone', Unlock.level(40), 0xFFFFB627),
    HairDye('comet', 'Comet', Unlock.level(50), 0xFF9FB4FF),
    HairDye('cinder', 'Cinder', Unlock.level(66), 0xFFFF7043),
    HairDye('mint', 'Mint', Unlock.patron, 0xFF5FD3A5),
    HairDye('sky', 'Sky', Unlock.patron, 0xFF4FA8E8),
    HairDye('rose', 'Rose', Unlock.patron, 0xFFE26A9B),
    HairDye('lavender', 'Lavender', Unlock.patron, 0xFF9E7BE0),
  ];

  /// The bunting, in the order pennants are hung. All earned; none sold.
  static const pennants = <Pennant>[
    Pennant('first_workout', 'First Workout', Unlock.firstWorkout, 0xFF2FA89A),
    Pennant('first_victory', 'First Expedition', Unlock.victories(1), 0xFFE0A93B),
    Pennant('streak_7', 'A Heroic Week', Unlock.streak(7), 0xFFE2663A),
    Pennant('level_5', 'Level 5', Unlock.level(5), 0xFF4F7FD6),
    Pennant('ten_victories', 'Ten Expeditions', Unlock.victories(10), 0xFFB23A3A),
    Pennant('level_10', 'Level 10', Unlock.level(10), 0xFF8F5BC9),
    Pennant('streak_30', 'Month of Might', Unlock.streak(30), 0xFFD9822B),
    Pennant('story_one', 'The Dawn Bell', Unlock.chapter(7), 0xFFF0C14B),
    Pennant('level_20', 'Level 20', Unlock.level(20), 0xFF3F9E5A),
    Pennant('level_30', 'Level 30', Unlock.level(30), 0xFFC2477F),
  ];

  /// The Journal shelf's trophies, in the order they are set out. The shelf has
  /// room for twelve, in two rows of six. All earned; none sold.
  static const trophies = <Trophy>[
    Trophy('story_two', 'The Lantern Coast', Unlock.chapter(15), TrophyShape.lantern),
    Trophy('level_40', 'Level 40', Unlock.level(40), TrophyShape.cup),
    Trophy('twenty_five_victories', 'Twenty-Five Expeditions', Unlock.victories(25), TrophyShape.shield),
    Trophy('streak_90', 'Season of Strength', Unlock.streak(90), TrophyShape.sun),
    Trophy('story_three', 'The Weather Chime', Unlock.chapter(23), TrophyShape.chime),
    Trophy('level_50', 'Level 50', Unlock.level(50), TrophyShape.star),
    Trophy('story_four', 'The Long Table', Unlock.chapter(31), TrophyShape.table),
    Trophy('level_100', 'Level 100', Unlock.level(100), TrophyShape.crown),
    Trophy('story_five', 'The Banked Fire', Unlock.chapter(39), TrophyShape.flame),
  ];

  static Cape capeById(String id) => capes.firstWhere((c) => c.id == id, orElse: () => capes.first);

  static HairDye? dyeById(String id) {
    for (final d in dyes) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// The cape actually worn: the one chosen if it is unlocked, otherwise the
  /// classic cape. So losing access (say, a deleted save before a restore)
  /// never leaves a broken look.
  static Cape wornCape(String chosen, CosmeticContext c) {
    final cape = capeById(chosen);
    return cape.unlock.isMet(c) ? cape : capes.first;
  }

  /// The hair dye actually worn, or null for the hero's natural colour.
  static HairDye? wornDye(String chosen, CosmeticContext c) {
    final dye = dyeById(chosen);
    return dye != null && dye.unlock.isMet(c) ? dye : null;
  }

  static List<Pennant> earnedPennants(CosmeticContext c) => [
        for (final p in pennants)
          if (p.unlock.isMet(c)) p,
      ];

  static List<Trophy> earnedTrophies(CosmeticContext c) => [
        for (final t in trophies)
          if (t.unlock.isMet(c)) t,
      ];

  /// Hall decorations the Patron Pack adds.
  static Set<String> patronDecor(CosmeticContext c) => c.patron ? PatronDecor.all : const {};

  /// Every cosmetic the pack adds, for the Patron's Hall screen.
  static List<String> get patronPackContents => [
        for (final c in capes)
          if (c.unlock.isPatron) c.name,
        for (final d in dyes)
          if (d.unlock.isPatron) '${d.name} Hair Dye',
        'Hall String Lights',
        'Potted Lantern Tree',
        'Patron Rosette',
      ];

  /// Builds the context from play and purchases.
  static CosmeticContext contextFor({
    required int level,
    required Set<int> chaptersRead,
    required int victories,
    required Set<int> claimedStreakDays,
    required int workouts,
    required Entitlements entitlements,
  }) =>
      CosmeticContext(
        level: level,
        chaptersRead: chaptersRead,
        victories: victories,
        claimedStreakDays: claimedStreakDays,
        workouts: workouts,
        patron: entitlements.hasPatronPack,
      );
}
