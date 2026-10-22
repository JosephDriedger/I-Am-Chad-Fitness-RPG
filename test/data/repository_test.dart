import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/player_state.dart';
import 'package:i_am_chad/domain/rewards.dart';
import 'package:i_am_chad/domain/workout.dart';

WorkoutEntry _walk(DateTime at, int minutes) => WorkoutEntry(
      activityId: 'walking',
      performedAt: at,
      durationSeconds: minutes * 60,
    );

const _hero = HeroProfile(
  name: 'Tester',
  appearanceStyle: 1,
  appearanceColor: 2,
  experience: ExperienceLevel.returning,
  preferredCategories: {ActivityCategory.cardio, ActivityCategory.mobility},
  hasDumbbells: true,
);

void main() {
  late AppDatabase db;
  late GameRepository repo;
  final today = DateTime(2026, 10, 22, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GameRepository(db);
  });
  tearDown(() => db.close());

  test('workouts persist and come back newest first', () async {
    await repo.addWorkout(_walk(today, 10));
    await repo.addWorkout(_walk(today.add(const Duration(hours: 5)), 20));
    final list = await repo.watchWorkouts().first;
    expect(list.length, 2);
    expect(list.first.durationSeconds, 20 * 60);
  });

  test('adding a workout derives a reward for that day only', () async {
    await repo.addWorkout(_walk(today, 10));
    final grants = await repo.watchGrants().first;
    expect(grants.length, 1);
    expect(grants.single.day, '2026-10-22');
    expect(grants.single.xp, 40);
    expect(grants.single.rulesVersion, RewardRules.v1.version);
  });

  test('daily cap holds across many entries', () async {
    for (var i = 0; i < 10; i++) {
      await repo.addWorkout(_walk(today.add(Duration(minutes: i)), 30));
    }
    final g = (await repo.watchGrants().first).single;
    expect(g.xp, RewardRules.v1.maxDailyXp);
    expect(g.energy, RewardRules.v1.maxDailyEnergy);
  });

  test('editing recomputes the reward; the record itself stays the truth',
      () async {
    final id = await repo.addWorkout(_walk(today, 10));
    await repo.updateWorkout(_walk(today, 20).copyWith(id: id));
    final g = (await repo.watchGrants().first).single;
    expect(g.xp, 80);
    expect((await repo.watchWorkouts().first).single.durationSeconds, 1200);
  });

  test('moving a workout to another day fixes both days', () async {
    final id = await repo.addWorkout(_walk(today, 10));
    final tomorrow = today.add(const Duration(days: 1));
    await repo.updateWorkout(_walk(tomorrow, 10).copyWith(id: id));
    final days = (await repo.watchGrants().first).map((g) => g.day).toList();
    expect(days, ['2026-10-23']);
  });

  test('deleting the last workout of a day removes that day\'s reward',
      () async {
    final id = await repo.addWorkout(_walk(today, 10));
    await repo.deleteWorkout(id);
    expect(await repo.watchGrants().first, isEmpty);
    expect(await repo.watchWorkouts().first, isEmpty);
  });

  test('rebalancing never rewrites days the player did not touch', () async {
    await repo.addWorkout(_walk(today, 10));
    // A later app version ships new rules.
    final v2 = GameRepository(db, rules: const RewardRules(version: 2, xpPerCreditedMinute: 9));
    await v2.addWorkout(_walk(today.add(const Duration(days: 3)), 10));
    final grants = {for (final g in await v2.watchGrants().first) g.day: g};
    expect(grants['2026-10-22']!.xp, 40);
    expect(grants['2026-10-22']!.rulesVersion, 1);
    expect(grants['2026-10-25']!.xp, 90);
    expect(grants['2026-10-25']!.rulesVersion, 2);
  });

  test('hero round-trips and energy math is derived, never negative', () async {
    await repo.createHero(_hero);
    final h = (await repo.watchHero().first)!;
    expect(h.name, 'Tester');
    expect(h.preferredCategories, _hero.preferredCategories);
    expect(h.hasDumbbells, isTrue);

    await repo.addWorkout(_walk(today, 10)); // 2 energy
    await repo.spendEnergy(2);
    final grants = await repo.watchGrants().first;
    var status = PlayerStatus(
      hero: (await repo.watchHero().first)!,
      activityXp: grants.fold(0, (a, g) => a + g.xp),
      energyEarned: grants.fold(0, (a, g) => a + g.energy),
      equipped: const [],
    );
    expect(status.energy, 0);

    // Deleting the workout afterwards must not produce negative energy.
    final id = (await repo.watchWorkouts().first).single.id!;
    await repo.deleteWorkout(id);
    status = PlayerStatus(
      hero: (await repo.watchHero().first)!,
      activityXp: 0,
      energyEarned: 0,
      equipped: const [],
    );
    expect(status.energy, 0);
  });

  test('expedition results are stored; duplicate loot becomes coins', () async {
    await repo.createHero(_hero);
    final first = await repo.recordExpedition(
      seed: 1,
      victory: true,
      battlesWon: 3,
      xp: 60,
      coins: 30,
      lootItemId: 'iron_blade',
    );
    final second = await repo.recordExpedition(
      seed: 2,
      victory: true,
      battlesWon: 3,
      xp: 60,
      coins: 30,
      lootItemId: 'iron_blade',
    );
    expect(first, isTrue);
    expect(second, isFalse);
    final h = (await repo.watchHero().first)!;
    expect(h.adventureXp, 120);
    expect(h.coins, 70);
    expect(h.victories, 2);
    expect((await repo.watchItems().first).length, 1);
  });

  test('a defeat keeps earned rewards but gives no loot', () async {
    await repo.createHero(_hero);
    final isNew = await repo.recordExpedition(
      seed: 3,
      victory: false,
      battlesWon: 1,
      xp: 15,
      coins: 5,
      lootItemId: 'iron_blade',
    );
    expect(isNew, isFalse);
    expect(await repo.watchItems().first, isEmpty);
    final h = (await repo.watchHero().first)!;
    expect(h.adventureXp, 15);
    expect(h.victories, 0);
  });

  test('only one item per slot can be equipped', () async {
    await repo.createHero(_hero);
    for (final id in ['wooden_sword', 'iron_blade']) {
      await repo.recordExpedition(
        seed: 0,
        victory: true,
        battlesWon: 3,
        xp: 0,
        coins: 0,
        lootItemId: id,
      );
    }
    await repo.setEquipped('wooden_sword', true);
    await repo.setEquipped('iron_blade', true);
    final items = {for (final i in await repo.watchItems().first) i.itemId: i};
    expect(items['wooden_sword']!.equipped, isFalse);
    expect(items['iron_blade']!.equipped, isTrue);
  });

  test('settings default sensibly and persist', () async {
    expect((await repo.watchSettings().first).useMetric, isTrue);
    await repo.saveSettings(const AppPrefs(useMetric: false, reducedMotion: true));
    final p = await repo.watchSettings().first;
    expect(p.useMetric, isFalse);
    expect(p.reducedMotion, isTrue);
  });

  test('export contains workouts as valid JSON; delete wipes everything',
      () async {
    await repo.createHero(_hero);
    await repo.addWorkout(_walk(today, 10));
    final json = jsonDecode(await repo.exportJson()) as Map<String, dynamic>;
    expect((json['workouts'] as List).length, 1);
    expect(json['hero']['name'], 'Tester');

    await repo.deleteEverything();
    expect(await repo.watchWorkouts().first, isEmpty);
    expect(await repo.watchHero().first, isNull);
    expect(await repo.watchGrants().first, isEmpty);
  });
}
