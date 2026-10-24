import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/combat.dart';
import 'package:i_am_chad/domain/difficulty.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/guide.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/reminders.dart';
import 'package:i_am_chad/domain/rewards.dart';
import 'package:i_am_chad/domain/shop.dart';

String _entry(String term) {
  for (final s in Guide.sections) {
    for (final e in s.entries) {
      if (e.term == term) return e.text;
    }
  }
  fail('no guide entry called "$term"');
}

void main() {
  final all = Guide.words.join('\n');

  test('it covers every term the game uses, in a few sections', () {
    expect(Guide.sections.length, inInclusiveRange(4, 8));
    const terms = [
      'Effort Minutes', 'Daily Limit', 'XP and Levels', 'Adventure Energy', 'Rest Days', 'Camps and Forks',
      'Active Days and Streaks', 'Weekly Goal', 'Gentle Reminders', 'Last Week', 'Expeditions', 'Regions', 'Practice Duel', 'Focus',
      'Potions', 'Enemy Moves', 'Fired Up', 'Coins', 'Gear', 'Pennants and Trophies', 'The Chronicle',
      'Saved on Your Device', 'Stop If Anything Hurts', 'Quick Honesty Check',
    ];
    for (final t in terms) {
      _entry(t);
    }
  });

  test('its numbers are the real rules, so it cannot drift', () {
    final r = RewardRules.v1;
    expect(_entry('Daily Limit'), contains('${r.maxDailyXp} XP'));
    expect(_entry('Daily Limit'), contains('${r.maxDailyEnergy} energy'));
    expect(_entry('Daily Limit'), contains('first ${r.fullValueMinutes.round()}'));
    expect(_entry('Effort Minutes'), contains('${r.minEffortPerEntry.round()} of them'));
    expect(_entry('XP and Levels'), contains('${r.xpPerCreditedMinute} XP'));
    expect(_entry('XP and Levels'), contains('Level ${Progression.maxLevel}'));
    expect(_entry('Adventure Energy'), contains('every ${r.minutesPerEnergy} counted'));
    expect(_entry('Adventure Energy'), contains('costs ${Expedition.energyCost}'));
    expect(_entry('Expeditions'), contains('${Expedition.energyCost} energy'));
    expect(_entry('Focus'), contains('up to ${BattleState.maxFocus}'));
    expect(_entry('Potions'), contains('${Shop.potionPrice} coins'));
    expect(_entry('Potions'), contains('${Shop.potionPouchMax} in your pouch'));
    expect(_entry('Potions'), contains('${Shop.maxPotionsBrought} of them'));
    expect(_entry('Gentle Reminders'), contains('${ReminderPrefs.earliestHour} AM and ${ReminderPrefs.latestHour - 12} PM'));
    expect(_entry('Gentle Reminders'), contains('off until you turn it on'));
    expect(_entry('Weekly Goal'), contains('${HeroProfile.minWeeklyGoal} to ${HeroProfile.maxWeeklyGoal}'));
  });

  test('every region is listed with the level it opens at, including any added later', () {
    final regions = _entry('Regions');
    expect(regions, contains('There are ${Difficulty.maxTier}.'));
    for (final r in Difficulty.regions) {
      expect(regions, contains('${r.name} from Level ${r.minLevel}.'));
    }
  });

  test('every move an enemy can make, and every action the player can take, is explained', () {
    final moves = _entry('Enemy Moves').toLowerCase();
    for (final m in EnemyMove.values) {
      final word = switch (m) {
        EnemyMove.strike => null,
        EnemyMove.windUp => 'winding up',
        EnemyMove.flurry => 'twice',
        EnemyMove.brace => 'bracing',
        EnemyMove.mend => 'mending',
      };
      if (word != null) expect(moves, contains(word), reason: '$m');
    }
    final mine = _entry('Your Moves');
    for (final a in BattleAction.values) {
      expect(mine, contains(a.label), reason: a.label);
    }
  });

  test('terms are unique Title Case names and the text is finished sentences', () {
    const small = {'a', 'the', 'and', 'of', 'to', 'for', 'with', 'from', 'in', 'at', 'on', 'if'};
    final terms = [for (final s in Guide.sections) for (final e in s.entries) e.term];
    expect(terms.toSet().length, terms.length);
    for (final s in Guide.sections) {
      expect(s.entries, isNotEmpty);
      for (final e in s.entries) {
        final words = e.term.split(' ');
        for (var i = 0; i < words.length; i++) {
          if (i > 0 && small.contains(words[i])) continue;
          expect(words[i][0], words[i][0].toUpperCase(), reason: '"${e.term}"');
        }
        expect(e.text.length, inInclusiveRange(40, 460), reason: e.term);
        expect(RegExp(r'[.!?]$').hasMatch(e.text), isTrue, reason: e.term);
      }
    }
  });

  test('it is kind: nothing pressures, shames or talks about bodies', () {
    const banned = [
      'lazy', 'weak', 'failure', 'failed', 'excuse', 'weight', 'in shape', 'burn off', 'hurry',
      'must ', 'you have to', 'no pain', 'deadline', "don't break", 'overdue', 'falling behind', 'miss out',
    ];
    final lower = all.toLowerCase();
    for (final b in banned) {
      expect(lower.contains(b), isFalse, reason: '"$b" in the guide');
    }
  });

  test("it keeps the game's promises where a reader would look for them", () {
    expect(_entry('Rest Days'), contains('Rest days are training'));
    expect(_entry('Easier Versions'), contains('exactly the same'));
    expect(_entry('Free Stories'), contains('free'));
    expect(_entry("The Patron's Hall").toLowerCase(), contains('looks only'));
    expect(_entry('Camera Counting'), contains('never saved'));
    expect(_entry('Saved on Your Device'), contains('no account'));
    expect(_entry('Back-Dated Workouts'), contains('no rewards'));
    expect(_entry('Stop If Anything Hurts').toLowerCase(), contains('professional'));
  });
}
