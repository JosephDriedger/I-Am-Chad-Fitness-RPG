/// What the little numbers at the top of the guild hall mean, in plain words.
/// Tapping them opens this, so nobody has to guess what a bolt or a flame is.
/// The numbers are read from the rules, so the words cannot drift from the game
/// (test/domain/hud_legend_test.dart checks), and the wording follows
/// docs/CONTENT_GUIDELINES.md: no pressure, nothing about what was not done.
library;

import 'expedition.dart';
import 'rewards.dart';

enum HudIcon { level, energy, coins, week, streak }

class HudLegendEntry {
  const HudLegendEntry(this.icon, this.title, this.text);

  final HudIcon icon;
  final String title;
  final String text;
}

class HudLegend {
  const HudLegend._();

  static const title = 'What You Are Seeing';

  static const footnote = 'All of it comes from moving at your own pace. Rest days are part of the plan and take nothing away.';

  static String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// Every number at the top of the hall. The streak is listed even when it is not
  /// showing yet, because it appears once there is one.
  static List<HudLegendEntry> entries() {
    final r = RewardRules.v1;
    return [
      const HudLegendEntry(
        HudIcon.level,
        'Level and the Gold Bar',
        'Your level goes up as you move. The bar shows how far you are to the next one.',
      ),
      HudLegendEntry(
        HudIcon.energy,
        'Adventure Energy',
        'You earn 1 for every ${_n(r.minutesPerEnergy.toDouble())} minutes of movement. An expedition costs ${Expedition.energyCost}. '
            'You never need it to rest, read the story or practice.',
      ),
      const HudLegendEntry(
        HudIcon.coins,
        'Coins',
        'You find them on adventures. Spend them in the Guild Shop on potions and gear.',
      ),
      const HudLegendEntry(
        HudIcon.week,
        'Days This Week',
        'The days you have moved this week, next to the number you chose to aim for. Any movement counts, and you can change the number on the quest board.',
      ),
      const HudLegendEntry(
        HudIcon.streak,
        'Active Days in a Row',
        'Shows up once you have one. Quiet days in between are fine, and if it ends you keep everything you earned.',
      ),
    ];
  }
}
