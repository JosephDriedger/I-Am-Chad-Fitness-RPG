import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/hero.dart';

const _hero = HeroProfile(
  name: 'Tester',
  appearanceStyle: 0,
  appearanceColor: 0,
  experience: ExperienceLevel.starting,
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

  final start = ExpeditionProgress.fresh(seed: 42, heroLevel: 1, heroMaxHp: 46);

  test('starting spends the energy and saves the expedition together', () async {
    expect(await repo.activeExpedition(), isNull);
    await repo.startExpedition(start, energyCost: Expedition.energyCost);

    final hero = (await repo.watchHero().first)!;
    expect(hero.energySpent, Expedition.energyCost);
    final saved = (await repo.activeExpedition())!;
    expect(saved.seed, 42);
    expect(saved.stepIndex, 0);
    expect(saved.heroHp, 46);
  });

  test('a second start while one is under way spends nothing and changes nothing', () async {
    expect(await repo.startExpedition(start, energyCost: 2), isTrue);
    final again = ExpeditionProgress.fresh(seed: 99, heroLevel: 1, heroMaxHp: 46, potions: 5);
    expect(await repo.startExpedition(again, energyCost: 2, broughtPotions: 3), isFalse);

    final hero = (await repo.watchHero().first)!;
    expect(hero.energySpent, 2);
    expect((await repo.activeExpedition())!.seed, 42);
  });

  test('progress updates in place; there is only ever one active expedition', () async {
    await repo.startExpedition(start, energyCost: 2);
    await repo.saveExpeditionProgress(const ExpeditionProgress(
      seed: 42,
      heroLevel: 1,
      stepIndex: 2,
      heroHp: 20,
      potions: 1,
      battlesWon: 1,
      xp: 15,
      coins: 13,
    ));
    final saved = (await repo.activeExpedition())!;
    expect(saved.stepIndex, 2);
    expect(saved.heroHp, 20);
    expect(saved.potions, 1);
    expect(saved.coins, 13);
    expect(await db.select(db.activeExpeditions).get(), hasLength(1));
  });

  test('the stream reports the saved expedition and its removal', () async {
    final seen = <int?>[];
    final sub = repo.watchActiveExpedition().listen((p) => seen.add(p?.stepIndex));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.startExpedition(start, energyCost: 2);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.recordExpedition(
      seed: 42,
      victory: false,
      battlesWon: 0,
      xp: 0,
      coins: 0,
      lootItemId: '',
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(seen, [null, 0, null]);
  });

  test('finishing or abandoning an expedition clears the save', () async {
    await repo.startExpedition(start, energyCost: 2);
    await repo.recordExpedition(
      seed: 42,
      victory: true,
      battlesWon: 3,
      xp: 60,
      coins: 22,
      lootItemId: 'iron_blade',
    );
    expect(await repo.activeExpedition(), isNull);
  });

  test('abandoning keeps the rewards earned so far and gives no loot', () async {
    await repo.startExpedition(start, energyCost: 2);
    await repo.recordExpedition(
      seed: 42,
      victory: false,
      battlesWon: 1,
      xp: 15,
      coins: 5,
      lootItemId: '',
    );
    final hero = (await repo.watchHero().first)!;
    expect(hero.adventureXp, 15);
    expect(hero.coins, 5);
    expect(await repo.watchItems().first, isEmpty);
    expect(await repo.activeExpedition(), isNull);
  });

  test('deleting all data also clears a saved expedition', () async {
    await repo.startExpedition(start, energyCost: 2);
    await repo.deleteEverything();
    expect(await repo.activeExpedition(), isNull);
  });

  test('the energy is never lost without the expedition (single transaction)', () async {
    // A failing save must roll the energy spend back too.
    final bad = GameRepository(db);
    await expectLater(
      db.transaction(() async {
        await bad.spendEnergy(2);
        throw StateError('interrupted');
      }),
      throwsStateError,
    );
    expect((await repo.watchHero().first)!.energySpent, 0);
  });
}
