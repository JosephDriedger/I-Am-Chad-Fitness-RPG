import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/rewards.dart';
import 'package:i_am_chad/domain/workout.dart';

WorkoutEntry _e(String id, {int? sets, int? reps, int? secs, double? meters}) =>
    WorkoutEntry(
      activityId: id,
      performedAt: DateTime(2026, 10, 22, 9),
      sets: sets,
      reps: reps,
      durationSeconds: secs,
      distanceMeters: meters,
    );

void main() {
  const rules = RewardRules.v1;

  group('effortMinutes', () {
    test('ten minute walk is ten effort minutes', () {
      expect(rules.effortMinutes(_e('walking', secs: 600)), closeTo(10, 1e-9));
    });

    test('running is worth more than walking for the same time', () {
      expect(rules.effortMinutes(_e('running', secs: 600)),
          greaterThan(rules.effortMinutes(_e('walking', secs: 600))));
    });

    test('tiny entries still earn the minimum, so showing up counts', () {
      expect(rules.effortMinutes(_e('push_up', sets: 1, reps: 2)),
          rules.minEffortPerEntry);
    });

    test('easier variants earn exactly the same as harder ones', () {
      final wall = _e('push_up', sets: 2, reps: 8).copyWith(variant: 'Wall');
      final std = _e('push_up', sets: 2, reps: 8).copyWith(variant: 'Standard');
      expect(rules.effortMinutes(wall), rules.effortMinutes(std));
    });

    test('perceived effort and load never change rewards', () {
      final base = _e('dumbbell_row', sets: 3, reps: 10);
      final heavy = base.copyWith(loadKg: 80, perceivedEffort: 5);
      expect(rules.effortMinutes(heavy), rules.effortMinutes(base));
    });

    test('empty or unknown activities earn nothing', () {
      expect(rules.effortMinutes(_e('walking')), 0);
      expect(rules.effortMinutes(_e('moon_dance', secs: 600)), 0);
    });

    test('distance only falls back to a pace assumption', () {
      expect(
          rules.effortMinutes(_e('walking', meters: 1000)), closeTo(12, 1e-9));
    });
  });

  group('daily curve', () {
    test('is full value up to 20, half value up to 40, then flat', () {
      expect(rules.creditedMinutes(10), 10);
      expect(rules.creditedMinutes(20), 20);
      expect(rules.creditedMinutes(30), 25);
      expect(rules.creditedMinutes(40), 30);
      expect(rules.creditedMinutes(400), 30);
    });

    test('is monotonic and never exceeds the cap', () {
      var prev = -1.0;
      for (var m = 0.0; m <= 600; m += 0.5) {
        final c = rules.creditedMinutes(m);
        expect(c, greaterThanOrEqualTo(prev));
        expect(c, lessThanOrEqualTo(rules.maxCreditedMinutes));
        prev = c;
      }
    });

    test('daily XP and energy are bounded no matter how much is logged', () {
      final marathon = [for (var i = 0; i < 50; i++) _e('running', secs: 3600)];
      final r = rules.rewardForDay(marathon);
      expect(r.xp, rules.maxDailyXp);
      expect(r.energy, rules.maxDailyEnergy);
      expect(r.capReached, isTrue);
    });
  });

  group('rewardForDay', () {
    test('GDD example: two sets of wall push-ups + 10 min walk', () {
      // Push-ups work out to ~2.35 min, lifted to the 3 min per-entry floor.
      final r = rules.rewardForDay([
        _e('push_up', sets: 2, reps: 8),
        _e('walking', secs: 600),
      ]);
      expect(r.rawEffortMinutes, closeTo(13, 0.01));
      expect(r.xp, inInclusiveRange(40, 60));
      expect(r.energy, 3);
      expect(r.capReached, isFalse);
      expect(r.rulesVersion, 1);
    });

    test('a rest day (no entries) is simply zero, not negative', () {
      final r = rules.rewardForDay(const []);
      expect(r.xp, 0);
      expect(r.energy, 0);
    });

    test('explain() always produces text', () {
      expect(rules.explain(rules.rewardForDay([_e('walking', secs: 600)])),
          contains('10'));
      expect(rules.explain(DayReward.none), isNotEmpty);
    });
  });

  group('Progression', () {
    test('levels are monotonic and consistent with thresholds', () {
      expect(Progression.levelForXp(0), 1);
      for (var l = 2; l < 50; l++) {
        final need = Progression.xpForLevel(l);
        expect(Progression.levelForXp(need), l);
        expect(Progression.levelForXp(need - 1), l - 1);
      }
    });

    test('stat growth is soft capped', () {
      final early = Progression.attack(10) - Progression.attack(1);
      final late = Progression.attack(60) - Progression.attack(51);
      expect(late, lessThan(early));
      // Asymptote: attack can never exceed base + growth * 30.
      expect(Progression.attack(99), lessThanOrEqualTo(8 + 1.6 * 30));
    });

    test('progress fraction stays within 0..1', () {
      for (var xp = 0; xp < 5000; xp += 37) {
        expect(Progression.levelProgress(xp), inInclusiveRange(0, 1));
      }
    });
  });
}
