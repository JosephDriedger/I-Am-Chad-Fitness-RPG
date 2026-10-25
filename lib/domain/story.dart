/// The story: Season One, "The Dawn Bell", Season Two, "The Lantern Coast",
/// Season Three, "The Weather Chime", and Season Four, "The Long Table".
/// See docs/STORY.md for the cast,
/// themes and the rules every line has to follow.
///
/// The story is told in chapters that unlock as the hero levels up. Level only
/// ever goes up, so nothing in it is timed, nothing can be missed, and it
/// never pressures anyone: it simply waits. Every chapter can be skipped and
/// read again. A few choices are remembered and echoed later.
library;

/// Who is talking. [hero] is the player, who speaks only through choices.
enum StorySpeaker {
  narrator(''),
  chad('Chad'),
  maple('Maple'),
  biscuit('Biscuit'),
  brad('Brad'),
  oakhelm('Oakhelm'),
  grit('Grit'),
  murmur('Murmur'),

  // Season Two, "The Lantern Coast".
  pip('Pip'),
  wren('Wren'),
  sedge('Sedge'),

  // Season Three, "The Weather Chime".
  fennel('Fennel'),
  hush('Hush'),
  tamsin('Tamsin'),
  skarn('Skarn'),

  // Season Four, "The Long Table".
  bertram('Bertram'),
  sphinx('The Sphinx'),
  worm('The Dune Worm'),
  hero('');

  const StorySpeaker(this.label);

  /// The name tag, empty for the narrator and the hero (whose name is used).
  final String label;
}

/// Where a scene is set.
enum StoryBackdrop {
  hall,
  bellTower,
  meadowRoad,
  pebbleHollow,
  oldWood,
  mistHollow,
  hillCamp,
  dawn,

  // Season Two, "The Lantern Coast".
  coastRoad,
  estuary,
  harbour,
  tidePools,
  lighthouse,
  lighthouseNight,

  // Season Three, "The Weather Chime".
  snowRoad,
  passHut,
  iceCave,
  observatory,
  stormTop,
  highCamp,
  summit,

  // Season Four, "The Long Table".
  courtyard,
  dunes,
  feast,
}

/// A line that only appears if an earlier choice went a particular way.
class StoryCondition {
  const StoryCondition(this.key, this.option);

  final String key;
  final int option;
}

sealed class StoryNode {
  const StoryNode({this.only});

  /// If set, this node is skipped unless the player made that choice earlier.
  final StoryCondition? only;
}

class StoryLine extends StoryNode {
  const StoryLine(this.speaker, this.text, {super.only});

  final StorySpeaker speaker;

  /// May contain \`{hero}\`, replaced with the hero's name.
  final String text;
}

class StoryOption {
  const StoryOption(this.label, this.reply);

  final String label;

  /// What happens next. Every option leads on to the same place.
  final List<StoryLine> reply;
}

/// A choice for the player. It is remembered under [key] as the number of the
/// option picked, so later chapters can answer it. No option is wrong.
class StoryChoice extends StoryNode {
  const StoryChoice(this.key, this.prompt, this.options, {super.only});

  final String key;
  final String prompt;
  final List<StoryOption> options;
}

class StoryScene {
  const StoryScene(this.backdrop, this.cast, this.nodes);

  final StoryBackdrop backdrop;

  /// Everyone shown in the scene, left to right. Anyone who speaks must be here.
  final List<StorySpeaker> cast;
  final List<StoryNode> nodes;
}

class StoryChapter {
  const StoryChapter({
    required this.number,
    required this.title,
    required this.unlockLevel,
    required this.summary,
    this.scenes = const [],
    this.season = 1,
  });

  /// Which season this chapter belongs to.
  final int season;

  /// Unique across every season, because it is what is saved when a chapter is
  /// read. Each season's first chapter is its prologue.
  final int number;
  final String title;

  /// The hero level at which this chapter opens.
  final int unlockLevel;

  /// A line for the Chronicle once it has been read, with no spoilers for later.
  final String summary;

  /// What is read. Empty for a chapter of a downloaded season until that season
  /// has been downloaded (see [Story.chapters] and lib/app/content_packs.dart).
  final List<StoryScene> scenes;

  /// Whether the script is here to read.
  bool get hasScenes => scenes.isNotEmpty;

  /// This chapter's place and wording, with [scenes] filled in from a download.
  StoryChapter withScenes(List<StoryScene> scenes) => StoryChapter(
        season: season,
        number: number,
        title: title,
        unlockLevel: unlockLevel,
        summary: summary,
        scenes: scenes,
      );

  /// Where this chapter sits in its own season: 0 is the prologue.
  int get numberInSeason => number - Story.seasonOf(season).firstChapter;

  String get label => numberInSeason == 0 ? 'Prologue' : 'Chapter $numberInSeason';
}

/// A run of chapters with its own title, place and problem.
class StorySeason {
  const StorySeason({
    required this.number,
    required this.title,
    required this.blurb,
    required this.firstChapter,
  });

  final int number;
  final String title;

  /// One sentence for the top of the Chronicle, with no spoilers.
  final String blurb;

  /// The [StoryChapter.number] of this season's prologue.
  final int firstChapter;

  /// Season One is part of the app. The later seasons are downloaded the first
  /// time they are read, so a first install stays small.
  bool get isDownloaded => number > 1;

  String get name => switch (number) {
        1 => 'Season One',
        2 => 'Season Two',
        3 => 'Season Three',
        _ => 'Season Four',
      };
}

class StoryText {
  const StoryText._();

  static const heroToken = '{hero}';

  /// Puts the hero's name into [text].
  static String fill(String text, {required String hero}) =>
      text.replaceAll(heroToken, hero);

  /// The nodes of [scene] that apply given the earlier [choices].
  static List<StoryNode> visible(StoryScene scene, Map<String, int> choices) =>
      [
        for (final n in scene.nodes)
          if (n.only == null || choices[n.only!.key] == n.only!.option) n,
      ];
}

/// Where the player stands in the story: what has opened and what is unread.
class StoryStatus {
  const StoryStatus({required this.level, required this.read});

  final int level;

  /// Numbers of the chapters already read.
  final Set<int> read;

  List<StoryChapter> get unlocked => StoryRules.unlocked(level);

  /// Open chapters not yet read, in order.
  List<StoryChapter> get unread => [
        for (final c in unlocked)
          if (!read.contains(c.number)) c,
      ];

  /// The next chapter still closed, or null at the end of the season.
  StoryChapter? get next => StoryRules.next(level);

  bool isUnlocked(StoryChapter c) => c.unlockLevel <= level;
  bool isRead(StoryChapter c) => read.contains(c.number);

  /// The most recently opened chapter.
  StoryChapter get latest => unlocked.last;
}

class StoryRules {
  const StoryRules._();

  /// Chapters open at these hero levels. They are spaced so the first few come
  /// quickly and the rest arrive over a few months of regular movement.
  static List<StoryChapter> unlocked(int level) => [
    for (final c in Story.chapters)
      if (c.unlockLevel <= level) c,
  ];

  /// The next chapter still closed at [level], or null at the end of the season.
  static StoryChapter? next(int level) {
    for (final c in Story.chapters) {
      if (c.unlockLevel > level) return c;
    }
    return null;
  }
}

class Story {
  const Story._();

  static const seasons = <StorySeason>[
    StorySeason(
      number: 1,
      title: 'The Dawn Bell',
      blurb: 'A silent bell, a foggy valley, and a hall waiting for a hero.',
      firstChapter: 0,
    ),
    StorySeason(
      number: 2,
      title: 'The Lantern Coast',
      blurb: 'A light in the west, a long road to the sea, and a keeper who forgot to rest.',
      firstChapter: 8,
    ),
    StorySeason(
      number: 3,
      title: 'The Weather Chime',
      blurb: 'A pass full of snow, a silent chime, and a long way up that is allowed to take as long as it takes.',
      firstChapter: 16,
    ),
    StorySeason(
      number: 4,
      title: 'The Long Table',
      blurb: 'A hall too full for its own table, a feast for everyone who ever came, and room for one more.',
      firstChapter: 24,
    ),
  ];

  static StorySeason seasonOf(int season) => seasons.firstWhere((s) => s.number == season);

  /// The chapters of one season, in order.
  static List<StoryChapter> inSeason(int season) => [
        for (final c in chapters)
          if (c.season == season) c,
      ];

  static StoryChapter? byNumber(int n) {
    for (final c in chapters) {
      if (c.number == n) return c;
    }
    return null;
  }

  /// Every chapter of every season, in the order they open.
  static const chapters = <StoryChapter>[...seasonOne, ...seasonTwo, ...seasonThree, ...seasonFour];

  // Seasons Two to Four are downloaded the first time they are read (see
  // docs/CONTENT_PACKS.md). The app keeps only what the Chronicle and the unlock
  // rules need: each chapter's place, title, level and summary, with no scenes.
  // The scripts live in tool/story_content, and tool/build_packs.dart turns them
  // into the files that get downloaded. test/domain/story_packs_test.dart fails
  // if this list and the scripts disagree.
  static const seasonTwo = <StoryChapter>[
    StoryChapter(
      season: 2,
      number: 8,
      title: 'A Hall Full of Strangers',
      unlockLevel: 18,
      summary:
          'The hall is busier than ever, a newcomer called Pip needs a friend, and a light is calling from the west.',
    ),
    StoryChapter(
      season: 2,
      number: 9,
      title: 'The Road West',
      unlockLevel: 20,
      summary:
          'A signpost with eleven arrows, a rival with a lot of energy, and a lesson about which way is behind.',
    ),
    StoryChapter(
      season: 2,
      number: 10,
      title: 'The Slowest Ferry in the World',
      unlockLevel: 23,
      summary:
          'The river between the road and the coast has a ferry, and the ferry has a tortoise.',
    ),
    StoryChapter(
      season: 2,
      number: 11,
      title: 'The Keeper Who Forgot to Rest',
      unlockLevel: 26,
      summary:
          'In the harbour, a keeper is carrying a lantern with the last of her strength.',
    ),
    StoryChapter(
      season: 2,
      number: 12,
      title: 'What the Tide Brings',
      unlockLevel: 30,
      summary:
          'At low tide, the shards of the lamp are waiting, and so is someone very worried about tomorrow.',
    ),
    StoryChapter(
      season: 2,
      number: 13,
      title: 'A Letter from Oakhelm',
      unlockLevel: 34,
      summary:
          'The lamp needs a new frame, and help arrives by cart, very slowly written.',
    ),
    StoryChapter(
      season: 2,
      number: 14,
      title: 'The Night Before the Light',
      unlockLevel: 38,
      summary:
          'Under the stars at the foot of the tower, everyone is a little nervous, and someone walks a very long way.',
    ),
    StoryChapter(
      season: 2,
      number: 15,
      title: 'The Answering Light',
      unlockLevel: 42,
      summary:
          'The lamp is lit, the fleet comes home, and something far away answers.',
    ),
  ];

  static const seasonThree = <StoryChapter>[
    StoryChapter(
      season: 3,
      number: 16,
      title: 'A Letter from Above',
      unlockLevel: 45,
      summary:
          'The first post in two winters comes down from the mountains, and it is addressed to the guild.',
    ),
    StoryChapter(
      season: 3,
      number: 17,
      title: 'The Foot of the Pass',
      unlockLevel: 47,
      summary:
          'A courier who only knows one speed, a rival with two flags, and a climb that can be taken any way you like.',
    ),
    StoryChapter(
      season: 3,
      number: 18,
      title: 'Soup at the Snow Line',
      unlockLevel: 50,
      summary:
          'A hut with one rule, a very large host, and a pot of soup that has been waiting for two winters.',
    ),
    StoryChapter(
      season: 3,
      number: 19,
      title: 'The Echo in the Ice',
      unlockLevel: 54,
      summary:
          'A cave of blue ice gives back whatever is said to it, only a little slower, and a lot kinder.',
    ),
    StoryChapter(
      season: 3,
      number: 20,
      title: 'The Weatherkeeper\'s Stair',
      unlockLevel: 58,
      summary:
          'At the top of the pass, a tall tower and a long stair, and someone sitting at the bottom of it.',
    ),
    StoryChapter(
      season: 3,
      number: 21,
      title: 'A Very Small Storm',
      unlockLevel: 62,
      summary:
          'At the top of the heights, a very small wizard is doing his best with a very large storm.',
    ),
    StoryChapter(
      season: 3,
      number: 22,
      title: 'The Night Before the Chime',
      unlockLevel: 66,
      summary:
          'Above the clouds, around a small fire, everyone says what they have come back with.',
    ),
    StoryChapter(
      season: 3,
      number: 23,
      title: 'The Weather Chime',
      unlockLevel: 70,
      summary:
          'The seven bells are rung, the storm settles, and three lights and three sounds answer each other.',
    ),
  ];

  static const seasonFour = <StoryChapter>[
    StoryChapter(
      season: 4,
      number: 24,
      title: 'A Table That Does Not Fit',
      unlockLevel: 74,
      summary:
          'The hall has a very good table and nowhere to put it, and a new member has arrived with a notebook.',
    ),
    StoryChapter(
      season: 4,
      number: 25,
      title: 'Letters on Every Road',
      unlockLevel: 77,
      summary:
          'Forty-one invitations, four roads, and a tortoise who does not have appointments.',
    ),
    StoryChapter(
      season: 4,
      number: 26,
      title: 'Soup for Forty',
      unlockLevel: 80,
      summary:
          'A very large host, a very large pot, and a promise that there will always be soup.',
    ),
    StoryChapter(
      season: 4,
      number: 27,
      title: 'Chairs, Slowly',
      unlockLevel: 83,
      summary:
          'A very old tree is asked for a very large number of chairs, and says yes, eventually.',
    ),
    StoryChapter(
      season: 4,
      number: 28,
      title: 'The Edge of the Dunes',
      unlockLevel: 86,
      summary:
          'A riddle, a very loud hello, and two guests who will need rather a lot of chair.',
    ),
    StoryChapter(
      season: 4,
      number: 29,
      title: 'The Weatherkeeper Comes Down',
      unlockLevel: 89,
      summary:
          'Four hundred and twelve steps, taken one landing at a time, and a forecast for the feast.',
    ),
    StoryChapter(
      season: 4,
      number: 30,
      title: 'The Night Before the Table',
      unlockLevel: 93,
      summary:
          'Everyone is arriving, the lanterns are going up, and someone has counted the chairs again.',
    ),
    StoryChapter(
      season: 4,
      number: 31,
      title: 'The Long Table',
      unlockLevel: 97,
      summary:
          'The table is laid, the chairs are full, and there is room for one more.',
    ),
  ];


  static const seasonOne = <StoryChapter>[
    // ---------------------------------------------------------------------------
    StoryChapter(
      number: 0,
      title: 'A Hall Waiting for a Hero',
      unlockLevel: 1,
      summary:
          'You meet Chad and Biscuit, and learn that the Dawn Bell has been silent for a long time.',
      scenes: [
        StoryScene(
          StoryBackdrop.hall,
          [StorySpeaker.chad, StorySpeaker.biscuit],
          [
            StoryLine(
              StorySpeaker.narrator,
              'The Guild Hall of Steady Steps stands at the top of Meadowmere Valley. Its lamps are lit and its '
              'hall is warm. Its great bell, the Dawn Bell, has been silent for a very long time.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Welcome, welcome, WELCOME! I am Chad, legendary guildmaster of this fine establishment!',
            ),
            StoryLine(
              StorySpeaker.chad,
              'I have wrestled bears, out-stared dragons, and once won an argument with a goose. Some of that is true.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'And you must be {hero}. The guild has been expecting you. Well. Hoping. Mostly the dust has been '
              'expecting you.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'Something small and brown skids around the corner and sits firmly on Chad\'s foot.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'This is Biscuit, our guild dog. Biscuit supervises everything. Biscuit has never been asked to.',
            ),
            StoryLine(StorySpeaker.biscuit, '*Woof!*'),
            StoryLine(
              StorySpeaker.chad,
              'He says you have a lovely aura. ...He did not say that. I translate freely.',
            ),
          ],
        ),
        StoryScene(
          StoryBackdrop.hall,
          [StorySpeaker.chad, StorySpeaker.biscuit],
          [
            StoryLine(
              StorySpeaker.chad,
              'Let me be plain about how this works. You move, in whatever way suits you. Walking, stretching, '
              'lifting, dancing in your kitchen.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'The guild writes it down, and it turns into XP, energy and quests. The quiet days count too. '
              'Rest is training. I wrote that on a banner.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Nothing here has a deadline. The story waits for you. It is very patient. It has to be, because I wrote it.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'So, {hero}. Before we begin, tell me: what brings you to the hall?',
            ),
            StoryChoice('motivation', 'What brings you to the hall?', [
              StoryOption('I want to feel stronger.', [
                StoryLine(
                  StorySpeaker.chad,
                  'Strength! A classic. We will build it one honest rep at a time.',
                ),
              ]),
              StoryOption('I want to have some fun.', [
                StoryLine(
                  StorySpeaker.chad,
                  'Fun! The most underrated training method in the realm. Biscuit agrees. Biscuit has always agreed.',
                ),
              ]),
              StoryOption('I am just curious.', [
                StoryLine(
                  StorySpeaker.chad,
                  'Curiosity is how every legend starts. Ask me anything. I will answer something.',
                ),
              ]),
            ]),
            StoryLine(
              StorySpeaker.chad,
              'Wonderful. Whatever brought you here, it is a good reason.',
            ),
          ],
        ),
        StoryScene(
          StoryBackdrop.hall,
          [StorySpeaker.chad, StorySpeaker.biscuit],
          [
            StoryLine(
              StorySpeaker.chad,
              'Now. There is one small matter. The Dawn Bell, up in the tower, has not rung in ages, and the valley '
              'has gone a bit quiet. A fog has settled in.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'A friendly fog, mostly. Sleepy. It muffles the roads, and the bell, and, well, enthusiasm.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'I would like to ring that bell again. I cannot do it alone. The legend is willing, but the legend\'s '
              'knees have opinions.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Will you help me, {hero}? Slowly. At your own pace. With snacks.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'Biscuit wags so hard that he falls over.',
            ),
            StoryChoice('help', 'Will you help?', [
              StoryOption('Gladly.', [
                StoryLine(StorySpeaker.chad, 'Splendid!'),
              ]),
              StoryOption('One step at a time.', [
                StoryLine(
                  StorySpeaker.chad,
                  'That is the only way anyone has ever walked anywhere. Splendid!',
                ),
              ]),
            ]),
            StoryLine(
              StorySpeaker.narrator,
              'And so the first page of the Chronicle turns.',
            ),
          ],
        ),
      ],
    ),

    // ---------------------------------------------------------------------------
    StoryChapter(
      number: 1,
      title: 'The Bell That Would Not Ring',
      unlockLevel: 2,
      summary:
          'The bell has no clapper. A trail of pebbles leads away, and you meet Maple, the quartermaster.',
      scenes: [
        StoryScene(
          StoryBackdrop.bellTower,
          [StorySpeaker.chad, StorySpeaker.biscuit],
          [
            StoryLine(
              StorySpeaker.narrator,
              'The bell tower is a spiral of old stone steps, a great many of them. Chad climbs eleven, announces '
              'a "tactical pause", and sits down.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Behold! The Dawn Bell! Notice how it is not ringing.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'The bell is enormous, bronze and a little dusty. Inside it, where the clapper should hang, there is '
              'only a loop of empty rope.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Missing! The clapper, the bit that goes "bong". The bell is fine. It simply has nothing to say.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'A bell without a clapper is like a legend without a hat. Possible, but disappointing.',
            ),
            StoryLine(StorySpeaker.biscuit, '*Sniff. Sniff. Woof!*'),
            StoryLine(
              StorySpeaker.narrator,
              'Biscuit is nosing at something in the dust: a trail of tiny, shiny pebbles leading out of the door '
              'and down toward the Meadow Road.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Pebbles! Pebbles, pebbles, pebbles. Only one kind of creature leaves a trail like that. ...I have '
              'forgotten which. It will come to me.',
            ),
          ],
        ),
        StoryScene(
          StoryBackdrop.hall,
          [StorySpeaker.maple, StorySpeaker.chad],
          [
            StoryLine(
              StorySpeaker.narrator,
              'Before you set out, Chad leads you to the quartermaster\'s counter at the back of the hall, where '
              'someone is eating an apple and reading a very long list.',
            ),
            StoryLine(StorySpeaker.maple, 'Hm. New hero.'),
            StoryLine(
              StorySpeaker.chad,
              '{hero}, this is Maple Thistlewick, quartermaster and apothecary. She brews every potion in the valley.',
            ),
            StoryLine(
              StorySpeaker.maple,
              'I label them, too. Healing Potion: tastes like a rumour. Do not shake. Do shake, if you like surprises.',
            ),
            StoryLine(
              StorySpeaker.maple,
              'The coins you earn buy gear and potions at my counter. Nothing random, nothing sneaky. I dislike sneaky. '
              'You will find me under Hero or Adventure.',
            ),
            StoryLine(
              StorySpeaker.maple,
              'And if you are ever tired, sit down. I keep a chair for it. It is the best-kept thing in the building.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'She is the most dependable person I know.',
            ),
            StoryLine(
              StorySpeaker.maple,
              'I am the only dependable person you know.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'You pocket a small bottle labelled "Probably Fine". The Meadow Road is waiting.',
            ),
          ],
        ),
      ],
    ),

    // ---------------------------------------------------------------------------
    StoryChapter(
      number: 2,
      title: 'Pebbles and Misunderstandings',
      unlockLevel: 3,
      summary:
          'The pebble trail ends at Grit\'s hollow, and the clapper comes home.',
      scenes: [
        StoryScene(
          StoryBackdrop.pebbleHollow,
          [StorySpeaker.grit, StorySpeaker.chad, StorySpeaker.biscuit],
          [
            StoryLine(
              StorySpeaker.narrator,
              'The trail ends at a hollow full of sparkling things: buttons, spoons, one boot, and a very large '
              'pile of pebbles.',
            ),
            StoryLine(
              StorySpeaker.grit,
              'INTRUDER! ...Visitor? Visitor! Hello! Do you like shiny things? I like shiny things. I like them a '
              'lot. Please do not take them.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'The Pebble Gremlin is about the size of a loaf of bread and talks at the speed of a sneeze.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'This is Grit! Chief of the Pebble Gremlins and, I want to say, a nuisance. ...No. A collector. Gently.',
            ),
            StoryLine(
              StorySpeaker.grit,
              'Everything here was lonely. Lying around. Nobody looking at it. So I looked at it. Now it is friends.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'Biscuit and Grit stare at each other for a long moment, then touch noses. Instant best friends.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'In the middle of the pile, glinting among the buttons, is a heavy brass clapper, polished by many '
              'small paws.',
            ),
            StoryChoice('gremlin', 'How do you ask for the clapper?', [
              StoryOption('Offer to swap something shiny.', [
                StoryLine(
                  StorySpeaker.grit,
                  'A swap! Fair is fair! What have you got? A button? A BUTTON?! Deal! It is the best button in the hollow!',
                ),
              ]),
              StoryOption('Share a snack.', [
                StoryLine(
                  StorySpeaker.grit,
                  'Snack! Oh! Nobody ever shares snacks! ...Is it a crunchy one? It is a crunchy one. Deal!',
                ),
              ]),
              StoryOption('Ask nicely, and hear about the pile.', [
                StoryLine(
                  StorySpeaker.grit,
                  'You want to hear about the pile?! Okay. So. This boot. It was a long road for this boot...',
                ),
                StoryLine(
                  StorySpeaker.narrator,
                  'Forty minutes later, it is agreed that it was a very good boot.',
                ),
              ]),
            ]),
            StoryLine(
              StorySpeaker.grit,
              'Take the clapper! It is a bell thing, and bells are for everyone. Come back and visit? Bring buttons.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'And that, {hero}, is how a clapper is won. Not by force, but by being kind to a very small gremlin.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'The clapper is home. But the old rope crumbled long ago, and the bell\'s beam is cracked, and then there '
              'is the matter of the fog. One piece at a time.',
            ),
          ],
        ),
      ],
    ),

    // ---------------------------------------------------------------------------
    StoryChapter(
      number: 3,
      title: 'A Rival, Briefly',
      unlockLevel: 5,
      summary:
          'Brad turns up with a rope, a lot of enthusiasm, and a surprising discovery about resting.',
      scenes: [
        StoryScene(
          StoryBackdrop.meadowRoad,
          [StorySpeaker.chad, StorySpeaker.brad],
          [
            StoryLine(
              StorySpeaker.narrator,
              'A cloud of dust, a gleam of sunglasses, and a voice you can hear long before you can see its owner.',
            ),
            StoryLine(
              StorySpeaker.brad,
              'CHAD! Of all the guilds, in all the valleys!',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Brad. You have, ah, a great deal of teeth today.',
            ),
            StoryLine(
              StorySpeaker.brad,
              'Heard you are ringing the Dawn Bell. Bold! I rang a bell first, of course. Years ago. Technically, I was first.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'It was a doorbell, Brad. At a tavern. You were asked to stop.',
            ),
            StoryLine(StorySpeaker.brad, 'A bell is a bell!'),
            StoryLine(
              StorySpeaker.narrator,
              'Brad is tall, tanned, extremely loud, and visibly out of breath. He has run here from three valleys over.',
            ),
            StoryLine(
              StorySpeaker.brad,
              'I have a rope! The best rope in the realm. Braided. Waterproof. You can only have it if you beat me in a friendly contest!',
            ),
            StoryLine(
              StorySpeaker.chad,
              'He is lying. He wants to be in the story.',
            ),
            StoryLine(
              StorySpeaker.brad,
              'I am NOT lying. I... want to be in the story. It looks fun.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'You agree to a friendly duel on the Meadow Road. Win or lose, the rope was always going to be yours.',
            ),
          ],
        ),
        StoryScene(
          StoryBackdrop.meadowRoad,
          [StorySpeaker.chad, StorySpeaker.brad],
          [
            StoryLine(
              StorySpeaker.brad,
              'Phew. *wheeze* Great duel. I definitely let you win.',
            ),
            StoryLine(StorySpeaker.chad, 'He did not.'),
            StoryLine(
              StorySpeaker.brad,
              '...Not entirely. (He sits down heavily.) I do not really rest, you know. Rest is slow. Everyone is ahead of me when I rest.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Brad. That is not how rest works. Rest is not behind. Rest is part of the road.',
            ),
            StoryLine(StorySpeaker.brad, 'Huh.'),
            StoryLine(
              StorySpeaker.narrator,
              'He lies back in the grass for one whole minute. By his own account, it is the longest minute of his life.',
            ),
            StoryLine(StorySpeaker.brad, '...Okay. That is kind of nice.'),
            StoryChoice('brad', 'What do you say to Brad?', [
              StoryOption('Rest well, Brad.', [
                StoryLine(
                  StorySpeaker.brad,
                  'I will. I am going to be so good at it.',
                ),
              ]),
              StoryOption('Mind if I join you?', [
                StoryLine(
                  StorySpeaker.brad,
                  'Pull up some grass. I am not saying it is a competition. But I am winning.',
                ),
              ]),
              StoryOption('Your secret is safe.', [
                StoryLine(StorySpeaker.brad, 'You are all right, hero.'),
              ]),
            ]),
            StoryLine(
              StorySpeaker.brad,
              'Take the rope. It is yours. I am going to lie here a bit longer. Do not tell anyone I said that.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'The rope is yours. Brad is now officially in the story, which he will never let anyone forget.',
            ),
          ],
        ),
      ],
    ),

    // ---------------------------------------------------------------------------
    StoryChapter(
      number: 4,
      title: 'Strong Opinions in the Old Oak Wood',
      unlockLevel: 7,
      summary: 'A very old tree, a slow stretch, and the beam the bell needs.',
      scenes: [
        StoryScene(
          StoryBackdrop.oldWood,
          [StorySpeaker.chad, StorySpeaker.oakhelm, StorySpeaker.biscuit],
          [
            StoryLine(
              StorySpeaker.narrator,
              'The road narrows into the Old Oak Wood, and the trees lean in as if they are listening.',
            ),
            StoryLine(StorySpeaker.oakhelm, 'Hmph.'),
            StoryLine(
              StorySpeaker.chad,
              'Ah. That will be Oakhelm, the Grumbling Treant. Technically a tree. Practically a weather report.',
            ),
            StoryLine(
              StorySpeaker.oakhelm,
              '...I heard that. The ears are in the branches.',
            ),
            StoryLine(
              StorySpeaker.oakhelm,
              'Nobody. Visits. Anymore. Hmph. The fog muffles the birds, you see. And the squirrels have stopped writing.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'He has strong opinions about squirrels.',
            ),
            StoryLine(
              StorySpeaker.oakhelm,
              'The squirrels know what they did.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'Oakhelm blocks the road, not out of malice, but because he is a tree and he is in the road.',
            ),
            StoryLine(
              StorySpeaker.oakhelm,
              'You want a beam. For the bell. The old yoke is cracked, and a cracked yoke swings crooked. I have a good branch.',
            ),
            StoryLine(
              StorySpeaker.oakhelm,
              'But I will not hand it to hurried feet. Sit. Stretch. Breathe. Slow things take time.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'You sit at the foot of the old tree. Oakhelm gives a surprisingly good lecture on stretching, Chad takes '
              'notes, and Biscuit falls asleep.',
            ),
            StoryLine(
              StorySpeaker.oakhelm,
              '"Begin with the roots," I say. "Then everything else." A long, slow stretch is just growing, done carefully. '
              'That is how I got to be this large.',
            ),
            StoryChoice('oak', 'What do you ask Oakhelm?', [
              StoryOption('What is the best thing about being old?', [
                StoryLine(
                  StorySpeaker.oakhelm,
                  'Knowing that most things pass, and the good ones come round again. Hmph. Do not tell the squirrels I said something nice.',
                ),
              ]),
              StoryOption('Why did the squirrels stop writing?', [
                StoryLine(
                  StorySpeaker.oakhelm,
                  'Because I replied. Honestly. Once. In detail. It was a lot of detail.',
                ),
              ]),
              StoryOption('May I sit a little longer?', [
                StoryLine(
                  StorySpeaker.oakhelm,
                  'Take as long as you like. I am not going anywhere. I am, structurally, unable.',
                ),
              ]),
            ]),
            StoryLine(
              StorySpeaker.narrator,
              'A branch lowers itself to your hands, smooth, strong and the exact right length.',
            ),
            StoryLine(
              StorySpeaker.oakhelm,
              'Take it. And come back and visit. It is quiet here. I find it a little less quiet when someone sits. '
              'You are welcome to a friendly bout, too. I consider it good exercise.',
            ),
          ],
        ),
      ],
    ),

    // ---------------------------------------------------------------------------
    StoryChapter(
      number: 5,
      title: 'Maybe Tomorrow',
      unlockLevel: 10,
      summary:
          'In the foggiest corner of the valley, a small, sorry creature, and a cracked weathervane.',
      scenes: [
        StoryScene(
          StoryBackdrop.mistHollow,
          [StorySpeaker.maple, StorySpeaker.murmur, StorySpeaker.chad],
          [
            StoryLine(
              StorySpeaker.narrator,
              'At the bottom of the valley the Quiet Fog is thickest. Everything is soft and grey and far away. A small '
              'voice drifts out of it.',
            ),
            StoryLine(StorySpeaker.murmur, 'Maybe tomorrow.'),
            StoryLine(
              StorySpeaker.chad,
              'A Fog Imp. They say that. Quite often.',
            ),
            StoryLine(
              StorySpeaker.murmur,
              '...Or today? Sorry. Today is also fine. I am Murmur. Sorry. I say sorry quite often, too.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'Murmur is a grey, apologetic creature with an enormous soft voice and an enormous soft scarf.',
            ),
            StoryLine(
              StorySpeaker.murmur,
              'I make the fog. Not on purpose. I am a weather imp. I sigh, and the fog comes. There used to be a '
              'weathervane that turned the wind and cleared it. It creaked, and cracked, and the wind stopped coming.',
            ),
            StoryLine(
              StorySpeaker.murmur,
              'So I sigh because there is no wind, and the fog comes because I sigh. Round and round. I did not know '
              'who to tell.',
            ),
            StoryLine(StorySpeaker.maple, 'Hm. So it is a loop.'),
            StoryLine(
              StorySpeaker.maple,
              'Loops can be broken. With a snack and a spanner.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'Maple climbs the old post with her tool roll in her teeth. She tightens, oils and scolds the weathervane. '
              'It gives a long, hopeful creak, and turns.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'The wind comes. The fog thins at the edges, like breath fading from a window.',
            ),
            StoryLine(
              StorySpeaker.murmur,
              'Oh. Oh! That is... that is the wind. Maybe it is already tomorrow?',
            ),
            StoryLine(
              StorySpeaker.chad,
              'It is today, Murmur. Today works fine.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'A "maybe tomorrow" is nothing to be ashamed of. It is just a forecast. You still get to decide the weather.',
            ),
            StoryChoice('murmur', 'What do you tell Murmur?', [
              StoryOption('Today is good. Tomorrow is good too.', [
                StoryLine(
                  StorySpeaker.murmur,
                  'Both? ...I had not thought of both. Thank you.',
                ),
              ]),
              StoryOption('Take your time. I will wait.', [
                StoryLine(
                  StorySpeaker.murmur,
                  'Nobody has ever said that to me without sounding impatient. Thank you.',
                ),
              ]),
              StoryOption('Would you like to walk with us?', [
                StoryLine(
                  StorySpeaker.murmur,
                  'Really? Nobody asks. I would like that. I can keep the hall\'s weather, if that is useful?',
                ),
              ]),
            ]),
            StoryLine(
              StorySpeaker.murmur,
              'I will keep the weathervane turning. And I will try to sigh less. Or at least sigh a little more happily.',
            ),
          ],
        ),
      ],
    ),

    // ---------------------------------------------------------------------------
    StoryChapter(
      number: 6,
      title: 'The Night Before the Bell',
      unlockLevel: 13,
      summary: 'A campfire on the hill, and the true story of Level 2.',
      scenes: [
        StoryScene(
          StoryBackdrop.hillCamp,
          [
            StorySpeaker.maple,
            StorySpeaker.chad,
            StorySpeaker.brad,
            StorySpeaker.biscuit,
          ],
          [
            StoryLine(
              StorySpeaker.narrator,
              'The whole company camps on the hill below the tower. There is stew, courtesy of Maple, and a sky full of '
              'stars that the fog has finally let through.',
            ),
            StoryLine(
              StorySpeaker.brad,
              '...and that is how I became the first person ever to climb this hill. Technically.',
            ),
            StoryLine(StorySpeaker.maple, 'There was a goat up here.'),
            StoryLine(
              StorySpeaker.brad,
              'Technically, a goat is not a person.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'Eventually even Brad runs out of hill. Biscuit curls up on {hero}\'s feet. Chad stares into the fire.',
            ),
            StoryLine(
              StorySpeaker.chad,
              '{hero}. Can I tell you something? It is about Level 2.',
            ),
            StoryLine(
              StorySpeaker.chad,
              '"Every legend started at Level 1. Except me. I started at Level 2. Long story." I say that a lot.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'It is not true. I started at Level 1, like everyone. And I was so nervous that I could not manage a '
              'single push-up. Not without a wall.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'A wall! Wall push-ups, in front of the whole guild. I wanted to be anywhere else. So I invented Level 2. '
              'It sounded more legendary.',
            ),
            StoryLine(StorySpeaker.brad, 'I knew that.'),
            StoryLine(StorySpeaker.chad, 'You did not.'),
            StoryLine(
              StorySpeaker.brad,
              'I have known for years. It is the best thing about you. Do not make it weird.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Here is what I learned. The wall counts. The wall always counts. Every rep anyone has ever done began '
              'with a wall, or a chair, or one very small step.',
            ),
            StoryChoice('chad', 'What do you say to Chad?', [
              StoryOption('The wall counts.', [
                StoryLine(
                  StorySpeaker.chad,
                  '...Thank you. It does. It really does.',
                ),
              ]),
              StoryOption('Level 1 is a fine place to start.', [
                StoryLine(
                  StorySpeaker.chad,
                  'The finest. I would go back and tell my nervous self, if I could.',
                ),
              ]),
              StoryOption('You sit beside him, saying nothing.', [
                StoryLine(
                  StorySpeaker.narrator,
                  'Chad does not say anything for a long time. It is exactly the right thing.',
                ),
              ]),
            ]),
            StoryLine(
              StorySpeaker.maple,
              'Hm. That is the most honest thing you have said in ten years.',
            ),
            StoryLine(StorySpeaker.chad, 'Please do not tell anyone.'),
            StoryLine(
              StorySpeaker.narrator,
              'Nobody does. The fire crackles. Tomorrow, the bell.',
            ),
          ],
        ),
      ],
    ),

    // ---------------------------------------------------------------------------
    StoryChapter(
      number: 7,
      title: 'The Dawn Bell',
      unlockLevel: 16,
      summary: 'The bell rings, the fog lifts, and the hall fills up.',
      scenes: [
        StoryScene(
          StoryBackdrop.bellTower,
          [
            StorySpeaker.chad,
            StorySpeaker.maple,
            StorySpeaker.brad,
            StorySpeaker.grit,
            StorySpeaker.biscuit,
          ],
          [
            StoryLine(
              StorySpeaker.narrator,
              'At first light, everyone climbs the tower. Brad insists on counting the steps. Chad insists on resting at '
              'step eleven. Both are allowed.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'The bell is whole at last: Grit\'s clapper, Brad\'s rope, Oakhelm\'s beam. Far below, Murmur waves from the '
              'valley, and a wind is turning the weathervane.',
            ),
            StoryLine(
              StorySpeaker.grit,
              'I brought buttons! For luck! A lot of buttons! Is it luck if it is buttons? It is luck if it is buttons!',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'From the valley below, a very old voice rumbles: "Hmph. Get on with it."',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Right. Whoever rings the bell... should be you, {hero}.',
            ),
            StoryChoice('bell', 'How do you ring the Dawn Bell?', [
              StoryOption('One big pull.', [
                StoryLine(
                  StorySpeaker.narrator,
                  'You haul the rope with everything you have. The bell swings, and speaks.',
                ),
              ]),
              StoryOption('Slowly, one pull at a time.', [
                StoryLine(
                  StorySpeaker.narrator,
                  'You pull, ease, pull again. The bell builds, and builds, and then it speaks.',
                ),
              ]),
              StoryOption('All together.', [
                StoryLine(
                  StorySpeaker.narrator,
                  'Everyone grabs the rope: Chad, Maple, Brad, Grit, Biscuit by the end of it. The bell swings, and speaks.',
                ),
              ]),
            ]),
            StoryLine(
              StorySpeaker.narrator,
              'BONG. A deep, warm sound rolls down the valley. The fog lifts like a curtain, and the morning is bright.',
            ),
          ],
        ),
        StoryScene(
          StoryBackdrop.dawn,
          [
            StorySpeaker.chad,
            StorySpeaker.maple,
            StorySpeaker.brad,
            StorySpeaker.biscuit,
          ],
          [
            StoryLine(
              StorySpeaker.narrator,
              'Doors open all down the valley. Lamps are lit. People start up the hill, one by one, then in dozens, and '
              'the hall fills with noise.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Look at that. A hall full of people. I had forgotten how loud it gets. I love it.',
            ),
            StoryLine(StorySpeaker.maple, 'Hm. Good bell.'),
            StoryLine(StorySpeaker.brad, 'I rang that. Technically.'),
            StoryLine(StorySpeaker.maple, 'Technically, you held the rope.'),
            StoryLine(
              StorySpeaker.chad,
              'Everyone gets credit. That is what a guild is.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'And {hero}, the bell is rung, but it is never finished. Bells ring every morning. Not because they have '
              'to. Because mornings are lovely and someone ought to say so.',
            ),
            StoryLine(
              StorySpeaker.chad,
              'Come by when you like. Move however you like. Rest when you need to. The hall is yours.',
              only: StoryCondition('motivation', 0),
            ),
            StoryLine(
              StorySpeaker.chad,
              'Come by when you like. Have fun with it, the way you said you would. The hall is yours.',
              only: StoryCondition('motivation', 1),
            ),
            StoryLine(
              StorySpeaker.chad,
              'Come by when you like. Stay curious, the way you did from the first day. The hall is yours.',
              only: StoryCondition('motivation', 2),
            ),
            StoryLine(
              StorySpeaker.narrator,
              'The Dawn Bell rings, and goes on ringing, and the valley wakes up at its own pace.',
            ),
            StoryLine(
              StorySpeaker.narrator,
              'Far to the west, where the valley ends and the coast begins, a single lantern glows. Someone has lit it. '
              'Someone is waiting. To be continued.',
            ),
          ],
        ),
      ],
    ),
  ];
}
