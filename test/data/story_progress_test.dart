import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';

const _hero = HeroProfile(
  name: 'Tester',
  appearanceStyle: 0,
  appearanceColor: 0,
  experience: ExperienceLevel.returning,
  preferredCategories: {ActivityCategory.cardio},
  hasDumbbells: false,
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

  test('nothing is read and nothing is chosen at the start', () async {
    expect(await repo.watchStoryRead().first, isEmpty);
    expect(await repo.watchStoryChoices().first, isEmpty);
  });

  test('a chapter, once read, stays read, and reading it again changes nothing', () async {
    await repo.markChapterRead(0, at: DateTime(2026, 10, 22));
    await repo.markChapterRead(0, at: DateTime(2026, 10, 25));
    await repo.markChapterRead(1, at: DateTime(2026, 10, 26));
    expect(await repo.watchStoryRead().first, {0, 1});
  });

  test('a choice is remembered, and picking again on a replay replaces it', () async {
    await repo.saveStoryChoice('motivation', 1);
    await repo.saveStoryChoice('help', 0);
    expect(await repo.watchStoryChoices().first, {'motivation': 1, 'help': 0});

    await repo.saveStoryChoice('motivation', 2);
    expect((await repo.watchStoryChoices().first)['motivation'], 2);
  });

  test('the export includes the story', () async {
    await repo.markChapterRead(0, at: DateTime(2026, 10, 22));
    await repo.saveStoryChoice('motivation', 1);
    final json = await repo.exportJson();
    expect(json, contains('"story"'));
    expect(json, contains('"motivation": 1'));
  });

  test('deleting everything clears the story too', () async {
    await repo.markChapterRead(0, at: DateTime(2026, 10, 22));
    await repo.saveStoryChoice('help', 1);
    await repo.deleteEverything();
    expect(await repo.watchStoryRead().first, isEmpty);
    expect(await repo.watchStoryChoices().first, isEmpty);
  });

  test('v6 saves upgrade to v7 and keep their workouts, rewards and hero', () async {
    final old = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE workouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          activity_id TEXT NOT NULL,
          performed_at INTEGER NOT NULL,
          variant TEXT, sets INTEGER, reps INTEGER, duration_seconds INTEGER,
          distance_meters REAL, load_kg REAL, perceived_effort INTEGER,
          notes TEXT, camera_counted INTEGER NOT NULL DEFAULT 0,
          logged_at INTEGER
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
          streak_xp INTEGER NOT NULL DEFAULT 0,
          potion_stock INTEGER NOT NULL DEFAULT 0,
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
        INSERT INTO heroes (id, name, experience, coins, potion_stock, created_at)
          VALUES (1, 'Veteran', 'regular', 54, 2, 1790000000);
        CREATE TABLE app_settings (
          id INTEGER NOT NULL PRIMARY KEY,
          use_metric INTEGER NOT NULL DEFAULT 1,
          reduced_motion INTEGER NOT NULL DEFAULT 0,
          quiet_chad INTEGER NOT NULL DEFAULT 0,
          sound_on INTEGER NOT NULL DEFAULT 1,
          haptics_on INTEGER NOT NULL DEFAULT 1
        );
        CREATE TABLE active_expeditions (
          id INTEGER NOT NULL PRIMARY KEY,
          seed INTEGER NOT NULL, hero_level INTEGER NOT NULL, step_index INTEGER NOT NULL,
          hero_hp INTEGER NOT NULL, potions INTEGER NOT NULL, battles_won INTEGER NOT NULL,
          xp INTEGER NOT NULL, coins INTEGER NOT NULL
        );
        PRAGMA user_version = 6;
      ''');
    }));
    addTearDown(old.close);
    final r = GameRepository(old);

    final h = (await r.watchHero().first)!;
    expect(h.name, 'Veteran');
    expect(h.coins, 54);
    expect(h.potionStock, 2);
    expect((await r.watchWorkouts().first).single.activityId, 'walking');

    // The story tables exist, empty, and can be written to.
    expect(await r.watchStoryRead().first, isEmpty);
    await r.markChapterRead(0, at: DateTime(2026, 10, 22));
    await r.saveStoryChoice('help', 1);
    expect(await r.watchStoryRead().first, {0});
    expect(await r.watchStoryChoices().first, {'help': 1});
  });
}
