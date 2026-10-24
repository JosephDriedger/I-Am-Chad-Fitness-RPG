import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/patronage.dart';
import 'package:i_am_chad/domain/workout.dart';

final _at = DateTime(2026, 10, 22, 10);

const _hero = HeroProfile(
  name: 'Ada',
  appearanceStyle: 1,
  appearanceColor: 2,
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

  test('a purchase is saved once, however often the store repeats it', () async {
    expect(await repo.recordPurchase(Patronage.patronPack, 'order-1', at: _at), isTrue);
    expect(await repo.recordPurchase(Patronage.patronPack, 'order-1', at: _at), isFalse);
    // A restore on a new phone brings the pack back under a different transaction.
    expect(await repo.recordPurchase(Patronage.patronPack, 'restored-9', at: _at), isFalse);
    final e = await repo.entitlements();
    expect(e.hasPatronPack, isTrue);
    expect(e.tipCount, 0);
    expect(await db.select(db.purchaseReceipts).get(), hasLength(1));
  });

  test('tips are counted per transaction and unlock nothing', () async {
    await repo.recordPurchase(Patronage.tipSmall, 'a', at: _at);
    await repo.recordPurchase(Patronage.tipSmall, 'a', at: _at); // repeated delivery
    await repo.recordPurchase(Patronage.tipSmall, 'b', at: _at);
    await repo.recordPurchase(Patronage.tipLarge, 'c', at: _at);
    final e = await repo.entitlements();
    expect(e.tipCount, 3);
    expect(e.hasPatronPack, isFalse);
  });

  test('buying changes no reward, stat or progress', () async {
    await repo.addWorkout(WorkoutEntry(
      activityId: 'walking',
      performedAt: _at,
      durationSeconds: 1200,
      loggedAt: _at,
    ));
    Future<List<Object?>> snapshot() async {
      final h = (await repo.watchHero().first)!;
      final grants = await repo.watchGrants().first;
      return [
        h.coins, h.adventureXp, h.streakXp, h.energySpent, h.potionStock, h.victories,
        grants.map((g) => (g.xp, g.energy)).toList(),
        (await repo.watchItems().first).length,
      ];
    }

    final before = await snapshot();
    await repo.recordPurchase(Patronage.patronPack, 'order-1', at: _at);
    await repo.recordPurchase(Patronage.tipLarge, 'tip-1', at: _at);
    expect(await snapshot(), before);
  });

  test('cape and hair dye are saved, and default to the classic look', () async {
    final fresh = (await repo.watchHero().first)!;
    expect(fresh.cape, 'classic');
    expect(fresh.hairDye, '');
    await repo.updateHeroDetails(cape: 'starlit', hairDye: 'mint');
    final h = (await repo.watchHero().first)!;
    expect(h.cape, 'starlit');
    expect(h.hairDye, 'mint');
    expect(h.appearanceStyle, 1); // other details untouched
  });

  test('the export lists purchases, and Delete Everything removes them', () async {
    await repo.recordPurchase(Patronage.patronPack, 'order-1', at: _at);
    final json = await repo.exportJson();
    expect(json, contains('"purchases"'));
    expect(json, contains(Patronage.patronPackId));
    // Nothing identifying the buyer is kept, only the product and when.
    expect(json, isNot(contains('order-1')));

    await repo.deleteEverything();
    expect((await repo.entitlements()).hasPatronPack, isFalse);
    expect(await db.select(db.purchaseReceipts).get(), isEmpty);
  });
}
