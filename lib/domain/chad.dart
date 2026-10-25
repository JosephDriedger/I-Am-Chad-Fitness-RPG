/// Chad's dialogue. Warm, theatrical, never guilt-based or body-shaming.
/// See docs/CONTENT_GUIDELINES.md before adding lines.
library;

enum ChadContext {
  welcome,
  idle,
  firstWorkout,
  afterWorkout,
  restDay,
  adventureStart,
  resume,
  victory,
  defeat,
  lowEnergy,
  capReached,
  streakReward,
  freshStart,
  backDated,
  newChapter,
}

class ChadDialogue {
  const ChadDialogue._();

  static const _lines = <ChadContext, List<String>>{
    ChadContext.welcome: [
      'Welcome, adventurer! I am Chad, legendary guildmaster. Every legend '
          'started at Level 1. Except me. I started at Level 2. Long story.',
      'Ah, a new face! Move at whatever pace suits you. Heroes come in all '
          'sizes of step.',
      'Welcome, hero! If you would like a gentle start, the training yard has '
          'a one-minute warm-up with me. No rewards, no pressure, just a stretch.',
    ],
    ChadContext.idle: [
      'Whenever you\'re ready. The guild hall isn\'t going anywhere. Mostly.',
      'A short walk is a legendary quest in the right light.',
      'Remember: stop if anything hurts. Even I listen to my knees. Sometimes.',
      'Today\'s quest board is just suggestions. You\'re the hero here.',
      'Stretch, stroll, or stare at the horizon dramatically. All three '
          'count as a warm-up.',
      'I once trained for an hour and a half. It was mostly choosing a '
          'headband.',
      'Every hero has a pace. Yours is the right one. Mine is "dramatic".',
      'The kettle is on. Biscuit is guarding it. Biscuit is not good at '
          'guarding.',
      'Water first, heroics second. That is my whole philosophy, and also my '
          'whole book.',
      'Some days a quest is ten minutes and a good song. That is a full '
          'quest.',
      'Nobody here is keeping score but the chronicle, and the chronicle is '
          'very kind.',
      'I have a theory that stairs are just hills that lost an argument.',
      'Do the bit you feel like doing. The bit counts. The bit always '
          'counts.',
      'Try something new today, or something familiar. Both are on the menu.',
    ],
    ChadContext.firstWorkout: [
      'Your very first logged workout! I\'m not crying, the dust in here is '
          'just very emotional.',
    ],
    ChadContext.afterWorkout: [
      'Splendid work! Every rep goes in the chronicle.',
      'That counts, and it counts well. The guild salutes you!',
      'Logged and legendary. Take a sip of water, hero.',
      'Done and dusted! The chronicle is writing it down with its best pen.',
      'Another one for the wall. Go and have a snack. A heroic one.',
      'I would clap, but I am holding a kettle. Please imagine the clapping.',
      'Whatever you did, you did it. That is the whole bar, and you cleared '
          'it.',
      'Well moved, hero. Stretch if you like, and sit as long as you like.',
    ],
    ChadContext.restDay: [
      'Rest days are training. I wrote that on a banner. The banner is '
          'correct.',
      'No workout today? The practice yard is open for a relaxed duel.',
      'Recovery is a heroic skill. Put your feet up. That\'s an order. A kind '
          'one.',
      'A day off is not a day lost. The guild keeps every one of your days '
          'safe.',
      'Tea, a stretch, maybe a nap. The nap is legally a quest.',
      'Even the Dawn Bell takes the afternoon off. Sit down, hero.',
    ],
    ChadContext.adventureStart: [
      'Onward! Remember, guarding is a perfectly good tactic. I used it '
          'once. Twice.',
      'Keep an eye on what the enemy is up to. Cleverness beats cardio, in '
          'here.',
      'Pack a potion, pick a plan, and watch what the enemy is up to. In '
          'that order.',
      'The enemy always shows its next move. Read first, then act. It is '
          'the secret of every great duellist.',
      'If you are nervous, guard. If you are curious, attack. If you are me, '
          'give a speech.',
    ],
    ChadContext.resume: [
      'Back already? Good. The enemy waited, like a gentleman.',
      'Your expedition kept your place. Shall we?',
      'Welcome back to the expedition. The path remembered you.',
    ],
    ChadContext.victory: [
      'Victory! I would say I taught you everything, but we both know you did '
          'the hard part.',
      'A triumph! I\'ll tell this story at the tavern. Slightly improved.',
      'You read the enemy and it showed. I took notes.',
      'Well fought, and wisely too. Guarding when it matters is a lovely '
          'skill.',
      'The chest, the glory, the snack. In that order. Enjoy.',
      'Another expedition in the chronicle! I will be telling this one for '
          'weeks.',
    ],
    ChadContext.defeat: [
      'No shame in a retreat. Heroes regroup and try again. Fewer injuries, '
          'more stories.',
      'That one got away. Your rewards so far are yours to keep.',
      'A knock-out is just a pause with extra steps. Everything you earned is '
          'safe.',
      'Every hero has a day like that. The next expedition is a clean page '
          'and a fresh plan.',
      'Sit down, have some tea. The monsters will still be there, looking '
          'slightly smug.',
    ],
    ChadContext.lowEnergy: [
      'Out of adventure energy! Log a little movement, or enjoy a free '
          'practice duel.',
      'Adventure energy is resting. Log a little movement, or take on a '
          'practice duel just for fun.',
    ],
    ChadContext.capReached: [
      'That\'s the most today\'s rewards can give. Anything more is just for '
          'you. Rest well!',
      'Today\'s rewards are all gathered. Anything more is purely for the '
          'joy of it.',
    ],
    ChadContext.streakReward: [
      'A streak, and what a lovely one! Rest days count too. This guild is '
          'not strict about calendars.',
      'Day after day, the chronicle grows. The guild notices. The guild is '
          'proud.',
      'Consistency suits you. So does that grin.',
      'Showing up in whatever way you could, again and again. That is the '
          'whole trick, and you are doing it.',
    ],
    ChadContext.freshStart: [
      'A fresh start is a good start. Your best run is still on the wall, and '
          'so are you.',
      'Welcome back, hero. The guild kept your chair warm.',
      'Coming back is a skill, and you are doing it. Two push-ups is a fine '
          'comeback. I have the paperwork.',
      'No catching up needed. The chronicle simply carries on from here, '
          'with you in it.',
      'The hall is glad you are back. Biscuit especially. He has been sitting '
          'by the door.',
    ],
    ChadContext.backDated: [
      'Into the chronicle it goes. Rewards are for what you log on the day, '
          'but the record is yours to keep.',
      'Remembered and written down. Next time, tell me the same day and the '
          'guild will pay up.',
    ],
    ChadContext.newChapter: [
      'A new page has turned in the Chronicle. Read it whenever you like. It '
          'will keep.',
      'The Chronicle has something new in it. No hurry, hero. Stories are '
          'patient.',
      'There is a new chapter waiting. I have not read it. I am saving it for '
          'you.',
      'A fresh chapter has opened. Tea first, if you like. Stories keep.',
    ],
  };

  /// Tips for setting out in each region, told in Chad's voice. Each one is true
  /// of the combat rules (see docs/COMBAT_AND_EXPEDITIONS.md): they are how the
  /// game teaches its enemy moves, one region at a time. Every region needs at
  /// least one.
  static const _regionTips = <int, List<String>>{
    1: [
      'Meadow monsters wind up before a heavy blow. When you see it coming, '
          'guard, and it barely tickles.',
      'Focus builds every time you attack or guard. Save it for a Power '
          'Strike when you are ready.',
    ],
    2: [
      'Crabs brace behind their shells. When one is bracing, skip the Power '
          'Strike and build a little focus instead.',
      'Jellies mend themselves when nobody is looking. If one is about to, '
          'hit it harder first.',
      'Gulls strike twice in a row. Guarding halves both. Excellent value, '
          'guarding.',
    ],
    3: [
      'Echo bats say everything twice, and strike twice. Guard when you are '
          'hurt.',
      'Glowcaps mend between blows. A strong hit before they do beats a '
          'patient nibble.',
      'Crystal beetles brace. Let them, and build up some focus.',
    ],
    4: [
      'Yetis hit hard when they mean it. Guard on the wind-up and it bounces '
          'right off.',
      'Frost sprites strike twice, quick as a sneeze. Guard when you are '
          'hurt and they cannot do much.',
      'Icicle golems brace and stay put, politely. Build focus, then strike.',
    ],
    5: [
      'Thunder clouds rumble twice before they strike. If it says two blows, '
          'guard.',
      'A boss that gets fired up hits harder for the rest of the fight. A '
          'potion beforehand is wise.',
      'Static imps brace and mend. Hit hard when they are neither, and they '
          'fizzle.',
    ],
    6: [
      'Scarabs brace, and mend in the shade. Hold your Power Strike for the '
          'moment they do neither.',
      'The sphinx will ask a riddle. The answer is "a nap". Do not tell '
          'anyone I said so.',
      'The dune worm says hello loudly. Guard on the wind-up and say hello '
          'back.',
    ],
    7: [
      'Comet cats and lantern moths strike twice. Guard when you are hurt, and '
          'they run out of sparkle.',
      'Star turtles brace behind their shells and mend slowly. Be patient, '
          'build focus, then strike.',
      'Nova is too bright to look at, so look at the intent line instead. It '
          'always says what is coming.',
    ],
    8: [
      'Cinder sprites strike twice and fizzle fast. Guard when you are hurt and they run out of spark.',
      'Anvil golems brace and ring like bells. Build focus while they do, then hit them when they stop.',
      'Magma slugs mend slowly, so hit them hard while they are hurt. The forgemaster only wants to talk about swords.',
    ],
  };

  /// Picks a line deterministically from [seed] so it doesn't flicker on
  /// rebuild, but varies from day to day.
  static String line(ChadContext context, {int seed = 0}) {
    final options = _lines[context]!;
    return options[seed.abs() % options.length];
  }

  /// What Chad says when setting out in region [tier]: his usual send-off, or
  /// a tip about the enemies there.
  static String adventureLine(int tier, {int seed = 0}) {
    final options = [..._lines[ChadContext.adventureStart]!, ...?_regionTips[tier]];
    return options[seed.abs() % options.length];
  }

  /// Every line there is, for tests.
  static List<String> get every => [
        for (final lines in _lines.values) ...lines,
        for (final tips in _regionTips.values) ...tips,
      ];

  /// The regions that have tips, for tests.
  static Iterable<int> get tipRegions => _regionTips.keys;
}
