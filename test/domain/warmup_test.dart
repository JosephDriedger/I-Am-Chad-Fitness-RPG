import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/warmup.dart';
import 'package:i_am_chad/game/demo/exercise_demo.dart';

void main() {
  test('it is about a minute, in a few gentle moves', () {
    expect(WarmUp.steps.length, inInclusiveRange(3, 6));
    expect(WarmUp.totalSeconds, inInclusiveRange(45, 90));
    for (final s in WarmUp.steps) {
      expect(s.seconds, inInclusiveRange(8, 30));
    }
  });

  test('every move is a real mobility exercise with no equipment and an animated demonstration', () {
    for (final s in WarmUp.steps) {
      final a = ActivityCatalog.byId(s.activityId);
      expect(a, isNotNull, reason: s.activityId);
      expect(a!.category, ActivityCategory.mobility, reason: s.activityId);
      expect(a.equipment, Equipment.none, reason: '${s.activityId} needs no kit');
      expect(demoFor(s.activityId), isNotNull, reason: s.activityId);
    }
    expect({for (final s in WarmUp.steps) s.activityId}.length, WarmUp.steps.length, reason: 'no move twice');
  });

  test('it says it is optional, that you can stop, and that it pays nothing', () {
    final all = WarmUp.words.join(' ').toLowerCase();
    expect(all, contains('stop'));
    expect(all, contains('skip'));
    expect(all, contains('no rewards'));
    expect(all, contains('stop if anything hurts'));
  });

  test('the words are kind: nothing pressures, shames or talks about bodies', () {
    const banned = [
      'lazy', 'weak', 'failure', 'failed', 'excuse', 'weight', 'in shape', 'burn off', 'hurry',
      'must ', 'you have to', 'no pain', 'deadline', 'streak',
    ];
    for (final w in WarmUp.words) {
      final lower = w.toLowerCase();
      for (final b in banned) {
        expect(lower.contains(b), isFalse, reason: '"$b" in: $w');
      }
      expect(RegExp(r'[.!?]$').hasMatch(w) || w == WarmUp.title, isTrue, reason: w);
    }
    for (final s in WarmUp.steps) {
      expect(s.chadLine.length, inInclusiveRange(30, 160), reason: s.chadLine);
    }
  });
}
