import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/player_state.dart';
import 'package:i_am_chad/domain/workout.dart';

final _today = DateTime(2026, 10, 22, 10);

const _hero = HeroProfile(
  name: 'Tester',
  appearanceStyle: 0,
  appearanceColor: 0,
  experience: ExperienceLevel.returning,
  preferredCategories: {ActivityCategory.cardio},
  hasDumbbells: false,
);

WorkoutEntry _on(int daysAgo) => WorkoutEntry(
      activityId: 'walking',
      performedAt: DateTime(2026, 10, 22 - daysAgo, 18),
      durationSeconds: 600,
    );

void main() {
  late AppDatabase db;
  late GameRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GameRepository(db);
    await repo.createHero(_hero);
  });
  tearDown(() => db.close());

  Future<void> log(Iterable<int> daysAgo) async {
    for (final d in daysAgo) {
      await repo.addWorkout(_on(d));
    }
  }

  test('nothing is paid until a milestone is reached', () async {
    await log([0, 1]);
    expect(await repo.claimStreakRewards(today: _today), isEmpty);
    final hero = (await repo.watchHero().first)!;
    expect(hero.coins, 0);
    expect(hero.streakXp, 0);
  });

  test('reaching a milestone pays coins and XP once', () async {
    await log([0, 1, 2]);
    final paid = await repo.claimStreakRewards(today: _today);
    expect(paid.map((m) => m.days), [3]);

    var hero = (await repo.watchHero().first)!;
    expect(hero.coins, 15);
    expect(hero.streakXp, 20);
    expect(await repo.watchClaimedStreaks().first, {3});

    // Asking again pays nothing more.
    expect(await repo.claimStreakRewards(today: _today), isEmpty);
    hero = (await repo.watchHero().first)!;
    expect(hero.coins, 15);
    expect(hero.streakXp, 20);
  });

  test('streak XP counts toward the level like any other XP', () async {
    await log([0, 1, 2]);
    await repo.claimStreakRewards(today: _today);
    final hero = (await repo.watchHero().first)!;
    final grants = await repo.watchGrants().first;
    final activityXp = grants.fold(0, (a, g) => a + g.xp);
    final status = PlayerStatus(hero: hero, activityXp: activityXp, energyEarned: 0, equipped: const []);
    expect(status.totalXp, activityXp + hero.adventureXp + 20);
    expect(status.totalXp, greaterThan(activityXp), reason: 'streak XP is real XP');
  });

  test('several milestones are paid together when they are all due', () async {
    await log([0, 1, 2, 3, 4, 5, 6]); // 7 days: 3, 5 and 7
    final paid = await repo.claimStreakRewards(today: _today);
    expect(paid.map((m) => m.days), [3, 5, 7]);
    final hero = (await repo.watchHero().first)!;
    expect(hero.coins, 15 + 25 + 40);
    expect(hero.streakXp, 20 + 30 + 50);
  });

  test('later milestones are paid as the streak grows', () async {
    await log([2, 3, 4]);
    expect((await repo.claimStreakRewards(today: DateTime(2026, 10, 20, 12))).map((m) => m.days), [3]);
    await log([1, 0]);
    expect((await repo.claimStreakRewards(today: _today)).map((m) => m.days), [5]);
  });

  test('a paid reward is never taken back, even if workouts are later deleted', () async {
    await log([0, 1, 2]);
    await repo.claimStreakRewards(today: _today);
    for (final w in await repo.watchWorkouts().first) {
      await repo.deleteWorkout(w.id!);
    }
    final hero = (await repo.watchHero().first)!;
    expect(hero.coins, 15);
    expect(hero.streakXp, 20);
    expect(await repo.watchClaimedStreaks().first, {3});
    // And rebuilding the same streak does not pay again.
    await log([0, 1, 2]);
    expect(await repo.claimStreakRewards(today: _today), isEmpty);
  });

  test('a lapse takes nothing away and a fresh run can earn again', () async {
    await log([20, 21, 22]);
    await repo.claimStreakRewards(today: DateTime(2026, 10, 2, 12));
    expect((await repo.watchHero().first)!.coins, 15);

    // A long quiet stretch, then back: the old reward stays, the count restarts.
    var status = await repo.streakStatus(today: _today);
    expect(status.current, 0);
    expect(status.best, 3);
    await log([0]);
    status = await repo.streakStatus(today: _today);
    expect(status.current, 1);
    expect(status.startedFresh, isTrue);
    expect((await repo.watchHero().first)!.coins, 15);
  });

  test('without a hero there is nothing to pay', () async {
    final fresh = GameRepository(AppDatabase.forTesting(NativeDatabase.memory()));
    expect(await fresh.claimStreakRewards(today: _today), isEmpty);
  });

  test('rewards appear in the export and are wiped with everything else', () async {
    await log([0, 1, 2]);
    await repo.claimStreakRewards(today: _today);
    final json = await repo.exportJson();
    expect(json, contains('"streakRewards"'));
    expect(json, contains('"streakXp": 20'));

    await repo.deleteEverything();
    expect(await repo.watchClaimedStreaks().first, isEmpty);
  });

  test('v4 saves upgrade to v5 and keep their workouts and hero', () async {
    final old = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE workouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          activity_id TEXT NOT NULL,
          performed_at INTEGER NOT NULL,
          variant TEXT, sets INTEGER, reps INTEGER, duration_seconds INTEGER,
          distance_meters REAL, load_kg REAL, perceived_effort INTEGER,
          notes TEXT, camera_counted INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE heroes (
          id INTEGER NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          appearance_style INTEGER NOT NULL DEFAULT 0,
          appearance_color INTEGER NOT NULL DEFAULT 0,
          appearance_skin INTEGER NOT NULL DEFAULT 0,
          experience TEXT NOT NULL,
          preferred_categories TEXT NOT NULL DEFAULT '',
          has_dumbbells INTEGER NOT NULL DEFAULT 0,
          energy_spent INTEGER NOT NULL DEFAULT 0,
          adventure_xp INTEGER NOT NULL DEFAULT 0,
          coins INTEGER NOT NULL DEFAULT 0,
          victories INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        );
        CREATE TABLE reward_grants (
          day TEXT NOT NULL PRIMARY KEY,
          effort_minutes REAL NOT NULL,
          credited_minutes REAL NOT NULL,
          xp INTEGER NOT NULL,
          energy INTEGER NOT NULL,
          rules_version INTEGER NOT NULL
        );
        INSERT INTO workouts (activity_id, performed_at, duration_seconds)
          VALUES ('walking', 1790000000, 600);
        INSERT INTO heroes (id, name, experience, coins, created_at)
          VALUES (1, 'Veteran', 'regular', 54, 1790000000);
        CREATE TABLE app_settings (
          id INTEGER NOT NULL PRIMARY KEY,
          use_metric INTEGER NOT NULL DEFAULT 1,
          reduced_motion INTEGER NOT NULL DEFAULT 0,
          quiet_chad INTEGER NOT NULL DEFAULT 0,
          sound_on INTEGER NOT NULL DEFAULT 1,
          haptics_on INTEGER NOT NULL DEFAULT 1
        );
        PRAGMA user_version = 4;
      ''');
    }));
    addTearDown(old.close);
    final r = GameRepository(old);

    final hero = (await r.watchHero().first)!;
    expect(hero.name, 'Veteran');
    expect(hero.coins, 54);
    expect(hero.streakXp, 0);
    expect((await r.watchWorkouts().first).single.activityId, 'walking');
    expect(await r.watchClaimedStreaks().first, isEmpty);
  });
}
