import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/repository.dart';
import '../domain/cosmetics.dart';
import '../domain/difficulty.dart';
import '../domain/expedition.dart';
import '../domain/hero.dart';
import '../domain/patronage.dart';
import '../domain/player_state.dart';
import '../domain/story.dart';
import '../domain/streaks.dart';
import '../domain/workout.dart';
import '../game/look.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider =
    Provider<GameRepository>((ref) => GameRepository(ref.watch(databaseProvider)));

/// Injectable clock so screens that depend on "today" are testable.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final workoutsProvider = StreamProvider<List<WorkoutEntry>>(
    (ref) => ref.watch(repositoryProvider).watchWorkouts());

final grantsProvider = StreamProvider<List<DayGrant>>(
    (ref) => ref.watch(repositoryProvider).watchGrants());

final heroProvider = StreamProvider<HeroProfile?>(
    (ref) => ref.watch(repositoryProvider).watchHero());

final itemsProvider = StreamProvider<List<OwnedItem>>(
    (ref) => ref.watch(repositoryProvider).watchItems());

final claimedStreaksProvider = StreamProvider<Set<int>>(
    (ref) => ref.watch(repositoryProvider).watchClaimedStreaks());

/// Where the hero's streak stands today, or null until things have loaded.
final streakProvider = Provider<StreakStatus?>((ref) {
  final hero = ref.watch(heroProvider).value;
  final workouts = ref.watch(workoutsProvider).value;
  if (hero == null || workouts == null) return null;
  return StreakRules.evaluate(
    workouts: workouts,
    today: ref.watch(clockProvider)(),
    experience: hero.experience,
  );
});

final storyReadProvider = StreamProvider<Set<int>>(
    (ref) => ref.watch(repositoryProvider).watchStoryRead());

final storyChoicesProvider = StreamProvider<Map<String, int>>(
    (ref) => ref.watch(repositoryProvider).watchStoryChoices());

/// What has opened in the story and what is still unread; null until loaded.
final storyStatusProvider = Provider<StoryStatus?>((ref) {
  final player = ref.watch(playerProvider);
  final read = ref.watch(storyReadProvider).value;
  if (player == null || read == null) return null;
  return StoryStatus(level: player.level, read: read);
});

/// Whether the hall offers an unread chapter by itself. Tests switch it off.
final storyAutoOfferProvider = Provider<bool>((_) => true);

/// Whether the hall offers Chad's warm-up to someone who has not logged a workout
/// yet. Tests switch it off.
final warmUpAutoOfferProvider = Provider<bool>((_) => true);

/// What the player's saved store purchases unlock (cosmetics only).
final entitlementsProvider = StreamProvider<Entitlements>(
    (ref) => ref.watch(repositoryProvider).watchEntitlements());

/// What cosmetics care about: level, story, victories, streaks and the
/// Patron Pack. Null until everything has loaded.
final cosmeticContextProvider = Provider<CosmeticContext?>((ref) {
  final player = ref.watch(playerProvider);
  final read = ref.watch(storyReadProvider).value;
  final streaks = ref.watch(claimedStreaksProvider).value;
  final workouts = ref.watch(workoutsProvider).value;
  if (player == null || read == null || streaks == null || workouts == null) return null;
  return Cosmetics.contextFor(
    level: player.level,
    chaptersRead: read,
    victories: player.hero.victories,
    claimedStreakDays: streaks,
    workouts: workouts.length,
    entitlements: ref.watch(entitlementsProvider).value ?? const Entitlements.none(),
  );
});

/// The hero as drawn everywhere in the game: appearance, worn gear, and the
/// chosen cape and hair dye if the player has them.
final heroLookProvider = Provider<HeroLook?>((ref) {
  final player = ref.watch(playerProvider);
  if (player == null) return null;
  final ctx = ref.watch(cosmeticContextProvider);
  final h = player.hero;
  final cape = ctx == null ? null : Cosmetics.wornCape(h.cape, ctx);
  return HeroLook(
    style: h.appearanceStyle,
    color: h.appearanceColor,
    skin: h.appearanceSkin,
    equipped: {for (final i in player.equipped) i.id},
    cape: cape?.color == null ? null : cape,
    dye: ctx == null ? null : Cosmetics.wornDye(h.hairDye, ctx),
  );
});

/// Which region the player has picked on the Adventure screen, or null for the
/// toughest one that is open. A region that is not open yet is never used.
class SelectedRegionNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int tier) => state = tier;
}

final selectedRegionProvider = NotifierProvider<SelectedRegionNotifier, int?>(SelectedRegionNotifier.new);

/// The region an expedition would set out for at [heroLevel].
int regionFor(int? selected, int heroLevel) =>
    selected != null && Difficulty.isOpen(selected, heroLevel) ? selected : Difficulty.tierFor(heroLevel);

final activeExpeditionProvider = StreamProvider<ExpeditionProgress?>(
    (ref) => ref.watch(repositoryProvider).watchActiveExpedition());

final settingsProvider = StreamProvider<AppPrefs>(
    (ref) => ref.watch(repositoryProvider).watchSettings());

/// Settings with a sensible default while loading.
final prefsProvider = Provider<AppPrefs>(
    (ref) => ref.watch(settingsProvider).value ?? const AppPrefs());

/// The hero combined with derived XP/energy; null until everything has loaded
/// or before onboarding is complete.
final playerProvider = Provider<PlayerStatus?>((ref) {
  final hero = ref.watch(heroProvider).value;
  final grants = ref.watch(grantsProvider).value;
  final items = ref.watch(itemsProvider).value;
  if (hero == null || grants == null || items == null) return null;
  return PlayerStatus(
    hero: hero,
    activityXp: grants.fold(0, (a, g) => a + g.xp),
    energyEarned: grants.fold(0, (a, g) => a + g.energy),
    equipped: [
      for (final o in items)
        if (o.equipped && o.item != null) o.item!,
    ],
  );
});
