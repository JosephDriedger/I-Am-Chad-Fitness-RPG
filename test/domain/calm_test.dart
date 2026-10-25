import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/calm.dart';

void main() {
  test('it is about a minute of slow breaths, with the long part last', () {
    expect(Calm.totalSeconds, inInclusiveRange(50, 75));
    expect(Calm.breaths, inInclusiveRange(4, 8));
    expect(CalmPhase.exhale.seconds, greaterThan(CalmPhase.inhale.seconds), reason: 'longer out than in is the calming one');
    expect(CalmPhase.values.first, CalmPhase.inhale);
    for (final p in CalmPhase.values) {
      expect(p.seconds, inInclusiveRange(1, 8), reason: p.label);
    }
  });

  test('every second of the minute is in exactly one breath and one part of it', () {
    final seen = <String>{};
    for (var s = 0; s < Calm.totalSeconds; s++) {
      final at = Calm.at(s)!;
      expect(at.breath, inInclusiveRange(0, Calm.breaths - 1));
      expect(at.left, inInclusiveRange(1, at.phase.seconds));
      seen.add('${at.breath}/${at.phase.name}');
    }
    expect(seen.length, Calm.breaths * CalmPhase.values.length);
    expect(Calm.at(Calm.totalSeconds), isNull);
    expect(Calm.at(-1), isNull);
  });

  test('the parts come in order and count down', () {
    expect(Calm.at(0)!.phase, CalmPhase.inhale);
    expect(Calm.at(0)!.left, CalmPhase.inhale.seconds);
    expect(Calm.at(CalmPhase.inhale.seconds - 1)!.left, 1);
    expect(Calm.at(CalmPhase.inhale.seconds)!.phase, CalmPhase.hold);
    expect(Calm.at(CalmPhase.inhale.seconds + CalmPhase.hold.seconds)!.phase, CalmPhase.exhale);
    expect(Calm.at(Calm.breathSeconds)!.phase, CalmPhase.inhale);
    expect(Calm.at(Calm.breathSeconds)!.breath, 1);
  });

  test('there is a cue for every breath', () {
    expect(Calm.cues.length, Calm.breaths);
  });

  test('it says it is optional, pays nothing, lets you stop, and watches out for dizziness', () {
    final all = Calm.words.join(' ').toLowerCase();
    expect(all, contains('stop whenever you like'));
    expect(all, contains('no rewards'));
    expect(all, contains('nothing is counted'));
    expect(all, contains('dizzy'));
    expect(all, contains('rest is training'));
  });

  test('the words are kind: nothing pressures, shames or demands a certain breath', () {
    const banned = [
      'lazy', 'weak', 'failure', 'failed', 'excuse', 'weight', 'in shape', 'burn off', 'hurry',
      'must ', 'you have to', 'no pain', 'deadline', 'streak', 'as deep as', 'as deeply as', 'hold your breath',
    ];
    for (final w in Calm.words) {
      final lower = w.toLowerCase();
      for (final b in banned) {
        expect(lower.contains(b), isFalse, reason: '"$b" in: $w');
      }
      expect(RegExp(r'[.!?]$').hasMatch(w) || w == Calm.title || CalmPhase.values.any((p) => p.label == w), isTrue, reason: w);
    }
    for (final c in Calm.cues) {
      expect(c.length, inInclusiveRange(30, 120), reason: c);
    }
  });
}
