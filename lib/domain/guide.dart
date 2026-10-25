/// "How the Game Works": a plain-words guide to every term the game uses, kept
/// in one place so Settings can show it whenever someone wonders. Every number
/// here is read from the rules themselves, so the guide cannot drift from the
/// game (test/domain/guide_test.dart checks it). See docs/CONTENT_GUIDELINES.md
/// before changing the words.
library;

import 'combat.dart';
import 'difficulty.dart';
import 'expedition.dart';
import 'hero.dart';
import 'reminders.dart';
import 'rewards.dart';
import 'shop.dart';

class GuideEntry {
  const GuideEntry(this.term, this.text);

  /// A name, in Title Case.
  final String term;

  /// A sentence or two in plain words.
  final String text;
}

class GuideSection {
  const GuideSection(this.title, this.entries);

  final String title;
  final List<GuideEntry> entries;
}

class Guide {
  const Guide._();

  static const title = 'How the Game Works';

  static const intro =
      'Everything the game says, in plain words. None of it is a test: you can read as much or as little as you like, and the game works the same either way.';

  static String _n(num x) => x == x.roundToDouble() ? '${x.round()}' : x.toStringAsFixed(1);

  static final _r = RewardRules.current;

  static List<GuideSection> get sections => [
        GuideSection('Moving and Rewards', [
          GuideEntry(
            'Effort Minutes',
            'A common measure, so a walk, a stretch and a set of push-ups can sit side by side. Every entry is worth at least ${_n(_r.minEffortPerEntry)} of them, because showing up counts. That holds for the first ${_r.maxFlooredEntriesPerDay} short entries of a day; after that, a very short one counts for its real length.',
          ),
          const GuideEntry(
            'Easier Versions',
            'An easier version of an exercise earns exactly the same as a harder one, and so does a lighter load. The game never rewards doing more than is right for you.',
          ),
          GuideEntry(
            'Daily Limit',
            'The first ${_n(_r.fullValueMinutes)} effort minutes of a day count in full, the next ${_n(_r.halfValueMinutes)} count for half, and after that nothing more is added. That keeps ${_n(_r.maxDailyXp)} XP and ${_n(_r.maxDailyEnergy)} energy as the most a day can give, so there is never a reason to push past what feels good.',
          ),
          GuideEntry(
            'XP and Levels',
            'You earn ${_n(_r.xpPerCreditedMinute)} XP for each counted minute, plus a little from expeditions and streaks. XP raises your level, up to Level ${Progression.maxLevel}, and each level opens a little more of the story and the world.',
          ),
          GuideEntry(
            'Adventure Energy',
            'You earn 1 energy for every ${_n(_r.minutesPerEnergy)} counted minutes. An expedition costs ${Expedition.energyCost}. You never need energy to rest, read the story, or play a practice duel.',
          ),
          const GuideEntry(
            'Quick Honesty Check',
            'The game cannot see what you did, so it trusts you. If a number looks unusual it asks once, kindly, and then saves exactly what you chose. It never changes a reward.',
          ),
        ]),
        GuideSection('Rest and Routine', [
          const GuideEntry(
            'Rest Days',
            'Rest days are training. Nothing is taken from you for a quiet day, and the game never tells you that you should have done more.',
          ),
          const GuideEntry(
            'Active Days and Streaks',
            'Any movement makes a day active. A streak is active days in a row, with quiet days allowed in between. A longer run pays small one-time rewards, and if it ends, you keep everything you earned and simply begin a fresh one.',
          ),
          const GuideEntry(
            'Ideas for Today',
            'Beside the quests, the quest board offers a few ideas: something that goes with a quest, and exercises you may not have tried. They are only ideas, and what you pick is up to you. For anything you have done before, you will see your last time and your own best marks, just to look back on.',
          ),
          GuideEntry(
            'Weekly Goal',
            'A gentle target of active days in a week, from ${HeroProfile.minWeeklyGoal} to ${HeroProfile.maxWeeklyGoal}. You choose it on the quest board, and you can change it whenever you like. Until you do, Chad suggests about what you have been doing lately, once you have a few weeks behind you.',
          ),
          const GuideEntry(
            'Warm-Up and Calm Minute',
            'On the Train screen Chad offers a one-minute warm-up and a minute of slow breathing. Both are optional, pay nothing, save nothing, and you can stop whenever you like.',
          ),
          const GuideEntry(
            'Last Week',
            'Once you have been around for a week, the quest board looks back at the one just gone: how many days you moved, your effort minutes and what you logged most. It only ever looks at your own week, never compares you with anyone, and a quiet week is simply a rest week.',
          ),
          GuideEntry(
            'Gentle Reminders',
            'On phones that can send them, Settings has an optional nudge, off until you turn it on. You pick the days and the hour, between ${ReminderPrefs.earliestHour} AM and ${ReminderPrefs.latestHour - 12} PM. You get at most one a day, none on a day you have already moved, and none once your week is done. They never mention what you missed, and they stop by themselves if you stop opening the game.',
          ),
          const GuideEntry(
            'Back-Dated Workouts',
            'You can add a workout from an earlier day so your journal is complete. It goes in the journal only, and earns no rewards, because rewards are for what you do now.',
          ),
        ]),
        GuideSection('Adventures', [
          GuideEntry(
            'Expeditions',
            'A short run of battles and camps, ending in a boss and a chest. It costs ${Expedition.energyCost} energy. If you are knocked out, or retreat, you keep the XP and coins from the battles you already won.',
          ),
          GuideEntry(
            'Regions',
            'There are ${Difficulty.maxTier}. ${_regionList()} A region stays open for good, so you can always go back to an easier one.',
          ),
          const GuideEntry(
            'Camps and Forks',
            'Between battles you stop at a camp, where you might heal, find a potion, pick up coins or start the next fight with focus. At a fork in the road you choose one of two ways. Each gives a different camp\'s benefit, and neither is a wrong choice.',
          ),
          const GuideEntry(
            'Practice Duel',
            'A relaxed fight in the guild yard. Always free, always against gentle enemies, and it pays nothing. It is there for rest days.',
          ),
          const GuideEntry(
            'Your Moves',
            'Attack builds focus. Guard halves the damage you take this turn and also builds focus. Power Strike spends 2 focus for a big hit. Potion heals about a third of your health.',
          ),
          const GuideEntry(
            'Focus',
            'You gain 1 focus each time you attack or guard, up to ${BattleState.maxFocus}, and it resets at the start of every battle.',
          ),
          GuideEntry(
            'Potions',
            'You start every expedition with ${Shop.basePotions}. You can buy more for ${Shop.potionPrice} coins each, keep up to ${Shop.potionPouchMax} in your pouch, and bring up to ${Shop.maxPotionsBrought} of them along. Any you do not use come home again.',
          ),
          const GuideEntry(
            'Enemy Moves',
            'The enemy always shows its next move before you pick yours. Winding up means a heavy blow, so guard. Striking twice means two quick blows, so guard when you are hurt. Bracing means your next hit lands at half strength, so save the Power Strike. Mending means it will heal, so hit hard first.',
          ),
          const GuideEntry(
            'Fired Up',
            'A boss that has taken enough damage gets fired up and hits harder for the rest of the fight. A potion beforehand is wise.',
          ),
        ]),
        GuideSection('Coins, Gear and Looks', [
          const GuideEntry(
            'Coins',
            'You earn coins from expeditions, from spare gear, and from streak rewards. You spend them in the Guild Shop on potions and gear. Coins can never be bought with money.',
          ),
          const GuideEntry(
            'Gear',
            'Each piece gives small bonuses, and you wear one of each kind: head, body, weapon and trinket. You find gear as loot, or buy it. If you find one you already own, it turns into coins.',
          ),
          const GuideEntry(
            'Pennants and Trophies',
            'Milestones hang as pennants across the top of the guild hall, and the bigger ones stand as trophies on the top shelf of the Journal bookshelf. Small keepsakes for each finished story season stand on the hall floor. They appear as you earn them, and they never go away.',
          ),
          const GuideEntry(
            'Mantles and Hair Dyes',
            'Changes to how your hero looks, and nothing else. Some are earned by finishing a season or reaching a level, and some come with the optional Patron Pack. None makes you stronger, and none is ever required.',
          ),
          const GuideEntry(
            'The Patron\'s Hall',
            'An optional place to say thank you and get extra looks. Real money buys looks only, never XP, energy, coins or anything that makes the game easier.',
          ),
        ]),
        GuideSection('Story', [
          const GuideEntry(
            'The Chronicle',
            'Each chapter opens at a hero level and waits for you, so nothing can be missed and nothing is timed. You can skip a chapter, leave it, or read it again whenever you like. The first season is in the game. Later seasons download once, the first time you read them, and stay on your phone.',
          ),
          const GuideEntry(
            'Choices',
            'A few moments ask what you think. No answer is wrong, none changes what you earn, and a later chapter may remember what you said.',
          ),
          const GuideEntry(
            'Free Stories',
            'Every chapter of every season is free. Before a chapter you have not read yet there may be one short ad, and the Patron\'s Hall can remove it for good.',
          ),
        ]),
        GuideSection('Your Data', [
          const GuideEntry(
            'Saved on Your Device',
            'Your hero, workouts and progress stay on your phone. There is no account. In Settings you can copy a full backup to keep or to move to a new phone, restore one, save your workouts as a spreadsheet to look at, or delete it all.',
          ),
          const GuideEntry(
            'Camera Counting',
            'If you choose to count reps with the camera, the pictures are looked at on your phone as they arrive. They are never saved and never sent anywhere.',
          ),
          const GuideEntry(
            'Stop If Anything Hurts',
            'The game cannot check your form or your health. Warm up, drink water, take it easy, and talk to a professional if you are unsure about anything.',
          ),
        ]),
      ];

  /// "Meadowmere from Level 1, The Gullhaven Coast from Level 5, ..."
  static String _regionList() => [
        for (final r in Difficulty.regions) '${r.name} from Level ${r.minLevel}.',
      ].join(' ');

  /// Every line a player reads, for tests.
  static List<String> get words => [
        title,
        intro,
        for (final s in sections) ...[s.title, for (final e in s.entries) ...[e.term, e.text]],
      ];
}
