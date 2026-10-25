import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/hud_legend.dart';
import 'package:i_am_chad/domain/rewards.dart';

void main() {
  final entries = HudLegend.entries();

  test('every number at the top of the hall is explained, once', () {
    expect({for (final e in entries) e.icon}, HudIcon.values.toSet());
    expect(entries.length, HudIcon.values.length);
  });

  test('the numbers in the words come from the rules', () {
    final energy = entries.firstWhere((e) => e.icon == HudIcon.energy).text;
    expect(energy, contains('1 for every ${RewardRules.v1.minutesPerEnergy} minutes'));
    expect(energy, contains('costs ${Expedition.energyCost}'));
  });

  test('titles are names in Title Case and the text is short, finished sentences', () {
    const small = {'a', 'the', 'and', 'of', 'to', 'for', 'with', 'from', 'in', 'at', 'on', 'if'};
    for (final e in entries) {
      final words = e.title.split(' ');
      for (var i = 0; i < words.length; i++) {
        if (i > 0 && small.contains(words[i])) continue;
        expect(words[i][0], words[i][0].toUpperCase(), reason: e.title);
      }
      expect(e.text.length, inInclusiveRange(40, 260), reason: e.title);
      expect(RegExp(r'[.!?]$').hasMatch(e.text), isTrue, reason: e.title);
    }
    expect(HudLegend.title, 'What You Are Seeing');
  });

  test('it is kind: nothing pressures, counts what was missed, or talks about bodies', () {
    const banned = [
      'should', 'must', 'need to', 'have to', 'missed', 'miss out', 'lazy', 'weak', 'failure', 'excuse', 'weight', 'in shape',
      'burn', 'hurry', 'behind', 'only', 'last chance', 'lose', 'lost',
    ];
    final all = [for (final e in entries) '${e.title} ${e.text}', HudLegend.footnote].join('\n').toLowerCase();
    for (final b in banned) {
      expect(RegExp(r'\b' + RegExp.escape(b) + r'\b').hasMatch(all), isFalse, reason: '"$b"');
    }
  });

  test('it says rest is fine and nothing is taken away', () {
    final all = '${entries.map((e) => e.text).join(' ')} ${HudLegend.footnote}'.toLowerCase();
    expect(all, contains('rest'));
    expect(all, contains('keep everything you earned'));
    expect(all, contains('any movement counts'));
  });
}
