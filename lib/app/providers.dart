import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/repository.dart';
import '../domain/expedition.dart';
import '../domain/hero.dart';
import '../domain/player_state.dart';
import '../domain/streaks.dart';
import '../domain/workout.dart';

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
