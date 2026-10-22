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
  victory,
  defeat,
  lowEnergy,
  capReached,
}

class ChadDialogue {
  const ChadDialogue._();

  static const _lines = <ChadContext, List<String>>{
    ChadContext.welcome: [
      'Welcome, adventurer! I am Chad, legendary guildmaster. Every legend '
          'started at Level 1. Except me. I started at Level 2. Long story.',
      'Ah, a new face! Move at whatever pace suits you. Heroes come in all '
          'sizes of step.',
    ],
    ChadContext.idle: [
      'Whenever you\'re ready. The guild hall isn\'t going anywhere. Mostly.',
      'A short walk is a legendary quest in the right light.',
      'Remember: stop if anything hurts. Even I listen to my knees. Sometimes.',
      'Today\'s quest board is just suggestions. You\'re the hero here.',
    ],
    ChadContext.firstWorkout: [
      'Your very first logged workout! I\'m not crying, the dust in here is '
          'just very emotional.',
    ],
    ChadContext.afterWorkout: [
      'Splendid work! Every rep goes in the chronicle.',
      'That counts, and it counts well. The guild salutes you!',
      'Logged and legendary. Take a sip of water, hero.',
    ],
    ChadContext.restDay: [
      'Rest days are training. I wrote that on a banner. The banner is '
          'correct.',
      'No workout today? The practice yard is open for a relaxed duel.',
      'Recovery is a heroic skill. Put your feet up. That\'s an order. A kind '
          'one.',
    ],
    ChadContext.adventureStart: [
      'Onward! Remember, guarding is a perfectly good tactic. I used it '
          'once. Twice.',
      'Keep an eye on what the enemy is up to. Cleverness beats cardio, in '
          'here.',
    ],
    ChadContext.victory: [
      'Victory! I would say I taught you everything, but we both know you did '
          'the hard part.',
      'A triumph! I\'ll tell this story at the tavern. Slightly improved.',
    ],
    ChadContext.defeat: [
      'No shame in a retreat. Heroes regroup and try again. Fewer injuries, '
          'more stories.',
      'That one got away. Your rewards so far are yours to keep.',
    ],
    ChadContext.lowEnergy: [
      'Out of adventure energy! Log a little movement, or enjoy a free '
          'practice duel.',
    ],
    ChadContext.capReached: [
      'That\'s the most today\'s rewards can give. Anything more is just for '
          'you. Rest well!',
    ],
  };

  /// Picks a line deterministically from [seed] so it doesn't flicker on
  /// rebuild, but varies from day to day.
  static String line(ChadContext context, {int seed = 0}) {
    final options = _lines[context]!;
    return options[seed.abs() % options.length];
  }
}
