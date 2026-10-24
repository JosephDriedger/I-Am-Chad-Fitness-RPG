/// Season Four, "The Long Table": a prologue and seven chapters that bring back
/// nearly everyone the story has met. The guild hall has outgrown its own table,
/// so Chad throws a feast for everyone who ever came through the door, and the
/// hero helps carry the invitations. The same rules apply as in the earlier
/// seasons (see docs/STORY.md and docs/CONTENT_GUIDELINES.md): warm and funny,
/// nothing timed, nothing that shames, and rest shown as an ordinary part of the
/// way. It is free for everyone, like the others.
///
/// Its theme is making room: hosting, belonging, and the idea that a place gets
/// better when there is a seat for the next person. It ends at the level cap, so
/// it is also a gentle thank-you for everything that came before.
library;

import 'story.dart';

const _n = StorySpeaker.narrator;
const _chad = StorySpeaker.chad;
const _maple = StorySpeaker.maple;
const _biscuit = StorySpeaker.biscuit;
const _brad = StorySpeaker.brad;
const _oakhelm = StorySpeaker.oakhelm;
const _grit = StorySpeaker.grit;
const _murmur = StorySpeaker.murmur;
const _pip = StorySpeaker.pip;
const _wren = StorySpeaker.wren;
const _sedge = StorySpeaker.sedge;
const _fennel = StorySpeaker.fennel;
const _hush = StorySpeaker.hush;
const _tamsin = StorySpeaker.tamsin;
const _skarn = StorySpeaker.skarn;
const _bertram = StorySpeaker.bertram;
const _sphinx = StorySpeaker.sphinx;
const _worm = StorySpeaker.worm;

const seasonFourChapters = <StoryChapter>[
  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 4,
    number: 24,
    title: 'A Table That Does Not Fit',
    unlockLevel: 74,
    summary: 'The hall has a very good table and nowhere to put it, and a new member has arrived with a notebook.',
    scenes: [
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _pip, _bertram, _biscuit], [
        StoryLine(
          _n,
          "The Guild Hall of Steady Steps has a problem, and the problem is a table.",
        ),
        StoryLine(
          _maple,
          "It is a very good table. I built it myself. It seats sixty. The hall seats forty. I measured twice, then I "
          "measured the hall, and then I sat down.",
        ),
        StoryLine(
          _chad,
          "It is a magnificent table, Maple! The only thing wrong with it is the hall.",
        ),
        StoryLine(
          _pip,
          "I have been counting. We have more members than chairs, and more chairs than socks. I do not know how that "
          "happened.",
        ),
        StoryLine(
          _n,
          "Someone small and brisk is standing in the doorway, in a maroon cardigan and a beret, holding a notebook "
          "and wearing the look of a person who has just been handed a present.",
        ),
        StoryLine(
          _bertram,
          "Good afternoon! Is this the place one begins? I am eighty-three and I would very much like to begin.",
        ),
        StoryLine(
          _chad,
          "Eighty-three! A fine age to begin! I started at Level 2!",
        ),
        StoryLine(_maple, "He did not."),
        StoryLine(
          _bertram,
          "I have made a list. Item one: stretch. Item two: ask someone what stretching is. Item three: tea.",
        ),
        StoryLine(
          _pip,
          "I'll show you the Duck Mat, Bertram. Everyone starts on the Duck Mat.",
        ),
        StoryLine(
          _pip,
          "Someone told me once that the wall counts. So I'll tell you too: the wall counts.",
          only: StoryCondition('pip', 0),
        ),
        StoryLine(
          _pip,
          "Someone told me once to rest at every landing. I'll show you where all of ours are.",
          only: StoryCondition('pip', 1),
        ),
        StoryLine(
          _pip,
          "Someone once walked right beside me, so I will walk right beside you. That is how it is done here.",
          only: StoryCondition('pip', 2),
        ),
        StoryChoice('host', 'What do you say to Bertram?', [
          StoryOption('You are exactly on time.', [
            StoryLine(
              _bertram,
              "Am I? I was sure I was either too early or about forty years late. Exactly on time. I shall write it down.",
            ),
          ]),
          StoryOption('Start wherever you like.', [
            StoryLine(
              _bertram,
              "Wherever I like! Oh, that is a thrilling thing to be told. I like the kettle. Let us begin with the kettle.",
            ),
          ]),
          StoryOption('Tea first, and then everything else.', [
            StoryLine(
              _maple,
              "That is the correct order. I wrote it on a sign. The sign is also in the kitchen.",
            ),
          ]),
        ]),
      ]),
      StoryScene(StoryBackdrop.courtyard, [_chad, _maple, _pip, _bertram, _biscuit], [
        StoryLine(
          _n,
          "The table has been carried out into the courtyard in nine pieces and put together again in the sunshine. "
          "It stretches nearly from one wall to the other, and it is still not quite long enough.",
        ),
        StoryLine(
          _chad,
          "What if the table is not the problem? What if we simply have never invited enough people to need it?",
        ),
        StoryLine(
          _maple,
          "That is not a solution, Chad. That is the problem again, wearing a hat.",
        ),
        StoryLine(
          _chad,
          "A feast! A long table, for everyone who ever came through our door. The coast, the mountain, the valley. "
          "Everyone!",
        ),
        StoryLine(
          _pip,
          "Fennel could carry the invitations. Fennel is very good at roads now, and at stopping.",
        ),
        StoryLine(
          _bertram,
          "I shall write them! I have excellent handwriting and no commitments until Thursday.",
        ),
        StoryLine(
          _maple,
          "Nothing here has a deadline. People will come when they come, and the table will wait.",
        ),
        StoryLine(
          _chad,
          "And anyone who cannot come, we will save a chair for. Rest is training, after all. A chair is just a rest "
          "with legs.",
        ),
        StoryLine(
          _n,
          "Biscuit, who has been listening carefully to the word 'feast', sits down very close to the table and does "
          "not move for the rest of the afternoon.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 4,
    number: 25,
    title: 'Letters on Every Road',
    unlockLevel: 77,
    summary: 'Forty-one invitations, four roads, and a tortoise who does not have appointments.',
    scenes: [
      StoryScene(StoryBackdrop.meadowRoad, [_fennel, _bertram, _pip, _chad], [
        StoryLine(
          _fennel,
          "Forty-one letters, four roads, and I am walking. On purpose! I have stopped for tea twice already.",
        ),
        StoryLine(
          _bertram,
          "I have written every one by hand. The first twenty say 'Dear Friend'. The last twenty-one say 'Dear Friend' "
          "with a doodle. I got bored of the first version.",
        ),
        StoryLine(
          _chad,
          "What does the invitation say, exactly? I would like to hear it. I have not been shown it. I am the host.",
        ),
        StoryChoice('invite', 'What does the invitation say?', [
          StoryOption('Come as you are.', [
            StoryLine(
              _bertram,
              "'Come as you are.' I shall add 'in whatever shoes you have.' Shoes are important at my age.",
            ),
          ]),
          StoryOption('Bring a chair, or do not.', [
            StoryLine(
              _bertram,
              "'Bring a chair, or do not.' Perfect. It tells them everything they need and nothing they do not.",
            ),
          ]),
          StoryOption('There is soup.', [
            StoryLine(
              _fennel,
              "'There is soup.' That has worked on me every time. I have been trapped in a hut by it for a week.",
            ),
          ]),
        ]),
        StoryLine(
          _pip,
          "People don't always know they're allowed to come to things. It helps to be told, in writing, with a doodle.",
        ),
        StoryLine(
          _n,
          "They walk on towards the sea, and the doodles on the letters grow bolder with every mile.",
        ),
      ]),
      StoryScene(StoryBackdrop.harbour, [_wren, _sedge, _bertram, _fennel], [
        StoryLine(
          _wren,
          "A feast! For everyone! Oh, I would love that. Gullhaven is very good at shifts now. The lamp is looked "
          "after by a rota of eleven people and a dog.",
        ),
        StoryLine(
          _wren,
          "I still have the spark you struck. I keep it in a jar. It is quite well-behaved.",
          only: StoryCondition('light', 0),
        ),
        StoryLine(
          _wren,
          "Everybody helped you light it. It is the only way I would light it now. Together, and not tidily.",
          only: StoryCondition('light', 1),
        ),
        StoryLine(
          _wren,
          "Pip lights the great lamp every Friday now. They have become excellent at it. They still ask if they can.",
          only: StoryCondition('light', 2),
        ),
        StoryLine(
          _sedge,
          "I shall set off today. I will arrive when I arrive.",
        ),
        StoryLine(
          _bertram,
          "Excellent! Item: ferry. May I ask how long a tortoise's 'today' is?",
        ),
        StoryLine(_sedge, "About three weeks."),
        StoryLine(
          _wren,
          "He has never missed a party, and he has never once been on time. Those are very different things.",
        ),
        StoryLine(
          _fennel,
          "That is the thing I was getting wrong for two winters, you know. You can arrive without being early.",
        ),
        StoryLine(
          _n,
          "Sedge adjusts his small red cap, lowers himself gently into the water, and begins the longest journey in "
          "the whole of the story, at exactly the speed he likes.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 4,
    number: 26,
    title: 'Soup for Forty',
    unlockLevel: 80,
    summary: 'A very large host, a very large pot, and a promise that there will always be soup.',
    scenes: [
      StoryScene(StoryBackdrop.snowRoad, [_fennel, _bertram, _brad, _hush], [
        StoryLine(
          _n,
          "The road up to the snow line is much shorter than it used to be, now that everyone in the party knows where "
          "all the landings are. They arrive at the little stone hut in good time and in a good mood.",
        ),
        StoryLine(
          _hush,
          "You are back. I put a mug on the step. I always do. This time somebody picked it up.",
        ),
        StoryLine(
          _bertram,
          "Is this a hut? It is exactly the size of a hut. I do so admire a building that knows what it is.",
        ),
        StoryLine(
          _brad,
          "I carried a pot all the way here. It was empty, and I still have strong opinions about it.",
        ),
        StoryLine(
          _fennel,
          "Hush, we are having a feast. For everyone. There is a table with sixty seats, and it needs soup.",
        ),
        StoryLine(
          _hush,
          "Soup for sixty. ...I can do soup for forty. I would need a bigger pot for sixty.",
        ),
        StoryLine(_brad, "I have a bigger pot. I did not know why I brought it. Now I know."),
      ]),
      StoryScene(StoryBackdrop.passHut, [_hush, _bertram, _brad, _fennel, _chad], [
        StoryLine(
          _hush,
          "On a mountain every path has a hut. In a hall, every table needs a kitchen. It is the same rule with "
          "different shoes.",
        ),
        StoryLine(
          _chad,
          "I will give a speech about soup. It is a very moving speech. It has a goose in it.",
        ),
        StoryLine(_hush, "Sit down, Chad."),
        StoryLine(_chad, "...Sitting down."),
        StoryLine(
          _bertram,
          "Mr Hush, may I help? I cannot lift anything heavy, but I can stir for as long as anyone likes. I have "
          "wonderful patience and an unreasonable number of spoons.",
        ),
        StoryLine(
          _hush,
          "You may stir. If you stir, someone else rests. That is how a kitchen is kept warm.",
        ),
        StoryChoice('dish', 'What do you bring to the table?', [
          StoryOption('A pie, slightly lopsided.', [
            StoryLine(
              _hush,
              "A lopsided pie tastes best. It has been loved too hard to sit up straight.",
            ),
          ]),
          StoryOption('My own soup, for Hush to try.', [
            StoryLine(
              _hush,
              "Oh. Nobody has ever brought me soup. ...It is very good. I will need to sit down.",
            ),
          ]),
          StoryOption('A very large bag of apples.', [
            StoryLine(
              _brad,
              "Apples! I will carry them. I have been looking for a purpose all day and this is a good one.",
            ),
          ]),
        ]),
        StoryLine(
          _brad,
          "Rest is training. I have been resting since the bell rang and look at me! I am nearly exactly as good as I "
          "was.",
        ),
        StoryLine(
          _n,
          "By evening the hut is steaming at every window, and the biggest pot in the mountains is gently bubbling in "
          "front of the stove, with Bertram standing guard over it with a very long spoon.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 4,
    number: 27,
    title: 'Chairs, Slowly',
    unlockLevel: 83,
    summary: 'A very old tree is asked for a very large number of chairs, and says yes, eventually.',
    scenes: [
      StoryScene(StoryBackdrop.oldWood, [_oakhelm, _grit, _bertram, _pip], [
        StoryLine(
          _n,
          "The old wood is as green and as slow as ever. A great many tiny, patient saplings have sprung up around "
          "Oakhelm's roots, and not one of them is in a hurry either.",
        ),
        StoryLine(
          _pip,
          "Oakhelm, we need chairs. A great many chairs. For a feast. We would be so grateful for a few branches.",
        ),
        StoryLine(
          _oakhelm,
          "...Chairs. ...I have... been thinking... about chairs... since... Tuesday.",
        ),
        StoryLine(
          _grit,
          "BUTTONS! For the cushions! I have eleven hundred. They are all different. It is the best day of my life.",
        ),
        StoryLine(
          _bertram,
          "Mr Oakhelm, I should say that I am eighty-three, and I have never been so thoroughly understood by a tree.",
        ),
        StoryLine(
          _oakhelm,
          "...We... are... the same... speed... you and I.",
        ),
        StoryLine(
          _n,
          "It takes the whole afternoon, and very few of the branches come down. The wood decides, gently, which ones "
          "are ready. Nobody asks it to hurry. Nobody could.",
        ),
      ]),
      StoryScene(StoryBackdrop.courtyard, [_chad, _maple, _grit, _bertram, _pip], [
        StoryLine(
          _maple,
          "Sixty-three chairs. None match. I have never been so happy.",
        ),
        StoryLine(
          _chad,
          "And a special one for me! The host! Which chair shall I have, {hero}? You choose. I trust you with my "
          "posterior.",
        ),
        StoryChoice('chair', 'What kind of chair should Chad get?', [
          StoryOption('One with a very tall back.', [
            StoryLine(
              _chad,
              "A tall back! Like a throne! Maple, I am going to need a longer cape.",
            ),
            StoryLine(_maple, "You do not have a cape. You have a towel."),
          ]),
          StoryOption('One that rocks.', [
            StoryLine(
              _chad,
              "A rocking chair! I shall sway all through the speeches. Nobody will know whether I am nervous or just "
              "enjoying myself.",
            ),
          ]),
          StoryOption('One with a cushion shaped like a duck.', [
            StoryLine(
              _grit,
              "I can do a duck! I have buttons for the eyes! They are different sizes! That is what makes it a good duck!",
            ),
            StoryLine(_chad, "I have never been so honoured in my life."),
          ]),
        ]),
        StoryLine(
          _bertram,
          "I have added chairs to my list, Mr Chad. Item forty-seven. Item forty-eight is a cushion for the dog.",
        ),
        StoryLine(
          _pip,
          "Every chair here is different, and every one of them fits someone. That is the whole trick, I think.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 4,
    number: 28,
    title: 'The Edge of the Dunes',
    unlockLevel: 86,
    summary: 'A riddle, a very loud hello, and two guests who will need rather a lot of chair.',
    scenes: [
      StoryScene(StoryBackdrop.dunes, [_sphinx, _fennel, _bertram, _pip], [
        StoryLine(
          _n,
          "Where the road runs out, the sand begins. It is warm and gold and very quiet, apart from the sound of "
          "something very large thinking.",
        ),
        StoryLine(
          _fennel,
          "I have one letter left for the desert. It says 'Dear Friend', and then a drawing of a table, and then "
          "a drawing of a very long table.",
        ),
        StoryLine(
          _sphinx,
          "Welcome. I will ask you a riddle. If you answer, I shall come to your feast. If you do not, I shall come "
          "to your feast anyway. But I do enjoy asking.",
        ),
        StoryLine(
          _bertram,
          "How marvellous. I have always wanted to be asked a riddle by a cat. A very large cat. A cat of "
          "enormous dignity.",
        ),
        StoryLine(
          _sphinx,
          "What can be had by anyone, costs nothing, makes everything better, and is best taken at your own pace?",
        ),
        StoryChoice('riddle', 'What is the answer?', [
          StoryOption('A nap.', [
            StoryLine(
              _sphinx,
              "...Correct. It is always correct. Nobody has ever got it wrong, you know. I just like to ask.",
            ),
          ]),
          StoryOption('Soup.', [
            StoryLine(
              _sphinx,
              "Soup! ...Well, that is also true. I shall allow it. Soup has been described as a kind of nap.",
            ),
          ]),
          StoryOption('I would rather you told me.', [
            StoryLine(
              _sphinx,
              "That is the wisest answer I have ever been given. The answer is a nap. Please tell no one.",
            ),
          ]),
        ]),
      ]),
      StoryScene(StoryBackdrop.dunes, [_worm, _sphinx, _bertram, _fennel, _pip], [
        StoryLine(
          _n,
          "The sand ahead rises into a hill, and the hill, very slowly, turns round and looks at them.",
        ),
        StoryLine(_worm, "HELLO."),
        StoryLine(
          _bertram,
          "Hello! Is he always like this?",
        ),
        StoryLine(
          _sphinx,
          "He says hello with his whole body. It is a gift. It is also a lot.",
        ),
        StoryLine(
          _worm,
          "I... AM... COMING... TO... THE... TABLE... DO... I... FIT?",
        ),
        StoryLine(
          _pip,
          "We will make you a seat, and it will fit. A very long seat. Probably the table's whole second half.",
        ),
        StoryLine(
          _bertram,
          "Item sixty-one: make sure the table is longer than the worm.",
        ),
        StoryLine(
          _worm,
          "THANK... YOU. ...I... HAVE... NEVER... BEEN... INVITED... TO... ANYTHING.",
        ),
        StoryLine(
          _fennel,
          "That is exactly the sort of thing the letters are for. Nobody ever stops being glad to be asked.",
        ),
        StoryLine(
          _n,
          "The whole way back across the dunes, the Dune Worm comes up beside them every few minutes to say hello "
          "again, just in case it did not land the first time.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 4,
    number: 29,
    title: 'The Weatherkeeper Comes Down',
    unlockLevel: 89,
    summary: 'Four hundred and twelve steps, taken one landing at a time, and a forecast for the feast.',
    scenes: [
      StoryScene(StoryBackdrop.observatory, [_tamsin, _fennel, _bertram, _pip], [
        StoryLine(
          _n,
          "At the foot of the long stair, somebody in a storm-blue coat is sitting on a folding chair with a "
          "thermos, looking at the steps she has just come down.",
        ),
        StoryLine(
          _tamsin,
          "I said I would come down by stages, and I did. Eleven days. Forty-one landings. I sat at every one.",
        ),
        StoryLine(
          _tamsin,
          "You sat beside me at the bottom of my stair once. I thought of that at every landing on the way down.",
          only: StoryCondition('stair', 0),
        ),
        StoryLine(
          _tamsin,
          "You asked me to try one step. It turned out to be a great many steps, taken one at a time. That is the trick.",
          only: StoryCondition('stair', 1),
        ),
        StoryLine(
          _tamsin,
          "You asked me about the view. I have now seen it from the top and from every landing. They are all different.",
          only: StoryCondition('stair', 2),
        ),
        StoryLine(
          _bertram,
          "Eleven days for four hundred and twelve steps! That is thirty-seven steps a day! I shall put that in my "
          "notebook as the finest piece of arithmetic I have ever heard.",
        ),
        StoryLine(
          _tamsin,
          "It is not about the arithmetic. It was about the landings. At every one, I thought: this is a place a "
          "person can stop.",
        ),
        StoryLine(
          _pip,
          "A place a person can stop. I might put that on a banner.",
        ),
        StoryLine(
          _fennel,
          "You are coming to the feast, then?",
        ),
        StoryLine(
          _tamsin,
          "I would not miss it. And I have brought someone. He insisted. He has also brought a weather forecast.",
        ),
      ]),
      StoryScene(StoryBackdrop.summit, [_skarn, _tamsin, _bertram, _fennel, _pip], [
        StoryLine(
          _skarn,
          "Hello! I came down the stair on my own. Mostly. Tamsin was at the other end the whole time, which "
          "counts for a good deal.",
        ),
        StoryLine(
          _skarn,
          "Tamsin led and I followed, and it came out right. I still think about that note.",
          only: StoryCondition('chime', 0),
        ),
        StoryLine(
          _skarn,
          "You let me ring first, once. I think about that more than the weather, and the weather is my whole job.",
          only: StoryCondition('chime', 1),
        ),
        StoryLine(
          _skarn,
          "We rang it all together, the three of us and the whole mountain. I think that is how it will always be.",
          only: StoryCondition('chime', 2),
        ),
        StoryLine(
          _skarn,
          "I have been asked for a forecast for the feast. It is my first official forecast. I am a little bit "
          "nervous, which, as you know, shows up in the sky.",
        ),
        StoryChoice('forecast', 'What weather should Skarn send for the feast?', [
          StoryOption('A clear night.', [
            StoryLine(
              _skarn,
              "A clear night. Stars, and no wind. I can do that. I have been practising. I will only be slightly "
              "damp in the top corner.",
            ),
          ]),
          StoryOption('A little breeze.', [
            StoryLine(
              _skarn,
              "A breeze, just enough to make the lanterns sway. Yes! I can make a breeze. I have a lot of sighs "
              "in reserve.",
            ),
          ]),
          StoryOption('Whatever he is feeling.', [
            StoryLine(
              _tamsin,
              "That is the bravest forecast anyone has asked for. I think we will all be a little rained on and "
              "glad of it.",
            ),
            StoryLine(_skarn, "Oh. Oh, I think I might cry. That is a weather. I am sorry."),
          ]),
        ]),
        StoryLine(
          _bertram,
          "Item seventy-three: umbrellas, and also not umbrellas.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 4,
    number: 30,
    title: 'The Night Before the Table',
    unlockLevel: 93,
    summary: 'Everyone is arriving, the lanterns are going up, and someone has counted the chairs again.',
    scenes: [
      StoryScene(StoryBackdrop.feast, [_chad, _maple, _pip, _bertram, _biscuit], [
        StoryLine(
          _n,
          "By dusk the courtyard looks like the inside of a kind person's head. Lanterns hang in strings from wall to "
          "wall, sixty-three mismatched chairs line a table that is finally long enough, and there is a smell of "
          "soup from every direction.",
        ),
        StoryLine(
          _maple,
          "I have counted the chairs eleven times. There is one for everyone. There is one for the worm, "
          "and it is a long one. There is one for a person I have not met yet, in case.",
        ),
        StoryLine(
          _chad,
          "In case! The best two words in the language! Maple, I do not tell you often enough that you are the "
          "backbone of this guild.",
        ),
        StoryLine(
          _maple,
          "You tell me every Tuesday. It is on a banner. I am keeping the banner.",
        ),
        StoryLine(
          _pip,
          "I used to think a guild was a place where people who know what they are doing teach people who do not. "
          "Now I think it is just a place with enough chairs.",
        ),
        StoryLine(
          _bertram,
          "I have crossed off every single item on my list, except the last. 'Be here when it happens.' I do not "
          "think one crosses that off. One simply keeps doing it.",
        ),
        StoryChoice('gift', 'What would you like to give the guild?', [
          StoryOption('A story.', [
            StoryLine(
              _chad,
              "A story! The guild runs on them. I will tell it at the tavern, slightly improved, with you "
              "as a considerably more handsome hero.",
            ),
          ]),
          StoryOption('A song.', [
            StoryLine(
              _bertram,
              "A song! I shall learn the words. It may take me until Thursday. I am an excellent slow learner.",
            ),
          ]),
          StoryOption('An afternoon.', [
            StoryLine(
              _maple,
              "An afternoon. ...That is the most valuable thing I have ever been offered. I will put it in the "
              "pantry for later.",
            ),
          ]),
        ]),
      ]),
      StoryScene(StoryBackdrop.feast, [_hush, _wren, _tamsin, _skarn, _murmur], [
        StoryLine(
          _n,
          "One by one, in the lantern light, the guests are arriving. They come along the road from the coast, down the "
          "pass, through the dunes and up from the fog, and every one of them stops at the gate to look at the "
          "table and breathe out.",
        ),
        StoryLine(
          _hush,
          "I brought the pot. It is the biggest in the mountains. It needed seven people to lift it, and four of them "
          "were soup.",
        ),
        StoryLine(
          _wren,
          "The lamp is lit and Gullhaven is minding it. I have not been away from it for a night in forty-one years. "
          "I do not think I have ever felt so rested.",
        ),
        StoryLine(
          _murmur,
          "I did not think I would come. I thought: what if I arrive and nobody remembers me? ...And then somebody "
          "said my name before I had even got to the gate.",
        ),
        StoryLine(
          _tamsin,
          "Nothing here has a deadline, Murmur. That includes arriving. You were exactly on time.",
        ),
        StoryLine(
          _skarn,
          "It is going to be a clear night with a breeze. It is working. I can feel it working. Nobody look at me.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 4,
    number: 31,
    title: 'The Long Table',
    unlockLevel: 97,
    summary: 'The table is laid, the chairs are full, and there is room for one more.',
    scenes: [
      StoryScene(StoryBackdrop.feast, [_chad, _hush, _wren, _tamsin, _bertram], [
        StoryLine(
          _n,
          "The feast begins with a sound that is very hard to describe: forty people, a tortoise, a worm and a dog all "
          "sitting down at once and discovering that they all fit.",
        ),
        StoryLine(
          _chad,
          "Friends! Guild! Strangers who are about to stop being strangers! I will keep this brief. I have prepared "
          "a speech with a goose in it. I am not going to give it.",
        ),
        StoryLine(
          _chad,
          "I started this guild with a hall, a bell, and a dog. Everything else is you. Every chair at this table is "
          "somebody who walked in, and somebody who walked in after them.",
        ),
        StoryLine(
          _wren,
          "Hear, hear. And to the people who rested, and the people who stopped, and the people who came back. Those "
          "are the ones who made the hall.",
        ),
        StoryLine(
          _hush,
          "I made soup. That was my part. I would like it to be enough.",
        ),
        StoryLine(_tamsin, "It is enough. It is always enough. That is what soup is for."),
        StoryLine(
          _bertram,
          "I would like to say that eighty-three is a fine age to begin. Also eighty-four. I plan to try that one "
          "as well.",
        ),
        StoryChoice('seat', 'Where do you sit?', [
          StoryOption('Between Chad and Bertram.', [
            StoryLine(
              _chad,
              "Between us! The best seat! You will hear everything twice, once from each side, and a third time at "
              "the end of the evening.",
            ),
          ]),
          StoryOption('Next to whoever is shy.', [
            StoryLine(
              _tamsin,
              "Then you will be sitting beside half the table. It is a good place to be.",
            ),
          ]),
          StoryOption('At the end, where I can see everyone.', [
            StoryLine(
              _wren,
              "The end of a table is a lighthouse. You can see everyone, and everyone can see you. I recommend it.",
            ),
          ]),
        ]),
      ]),
      StoryScene(StoryBackdrop.feast, [_chad, _maple, _pip, _bertram, _biscuit], [
        StoryLine(
          _n,
          "The lanterns sway in a small, careful breeze. Overhead the stars are bright and orderly, and only one "
          "of them, near the top corner, is very slightly damp.",
        ),
        StoryLine(
          _maple,
          "Every chair is full. There is a chair left over, at the far end, and I have decided it is for whoever "
          "arrives next.",
        ),
        StoryLine(
          _pip,
          "I think that is the point of it. Whoever comes next, there is always one more seat.",
        ),
        StoryLine(
          _bertram,
          "I have a last item for my list. Item one hundred and four: thank you. I do not think I need to cross it off.",
        ),
        StoryLine(
          _chad,
          "Biscuit has gone to sleep under the table, with a sausage. I would like it noted that this is exactly where "
          "he is supposed to be.",
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Move however you like, rest when you need to, and always bring a chair. "
          "The hall is yours.",
          only: StoryCondition('motivation', 0),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Have fun with it, the way you said you would, and bring a friend, "
          "or a worm. The hall is yours.",
          only: StoryCondition('motivation', 1),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Stay curious, the way you did from the very first day. There is a seat "
          "for whatever you find. The hall is yours.",
          only: StoryCondition('motivation', 2),
        ),
        StoryLine(
          _n,
          "Far away a bell rings, and a lamp winks, and a chime sings across the dark. Under all of it, a very long "
          "table, laid for everyone, at their own pace, with one chair kept for whoever comes next.",
        ),
      ]),
    ],
  ),
];
