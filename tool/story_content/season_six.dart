/// Season Six, "The Comet Road": a prologue and seven chapters. Bertram's very old
/// notebook has an item that has waited seventy-six years, a comet that passes over
/// the Starlit Isles, and the whole guild sets out to see it with him and with Juno,
/// the newcomer who knocked at the door at the end of Season Five. The same rules
/// apply as in the earlier seasons (see docs/STORY.md and docs/CONTENT_GUIDELINES.md):
/// warm and funny, nothing timed, nothing that shames, and rest shown as an ordinary
/// part of the way. It is free for everyone, like the others.
///
/// Its theme is arriving: the long road is the point, a thing that takes seventy-six
/// years can still be reached one night at a time, and the way back is the way on.
library;

import 'package:i_am_chad/domain/story.dart';

const _n = StorySpeaker.narrator;
const _chad = StorySpeaker.chad;
const _maple = StorySpeaker.maple;
const _biscuit = StorySpeaker.biscuit;
const _pip = StorySpeaker.pip;
const _wren = StorySpeaker.wren;
const _sedge = StorySpeaker.sedge;
const _hush = StorySpeaker.hush;
const _tamsin = StorySpeaker.tamsin;
const _bertram = StorySpeaker.bertram;
const _juno = StorySpeaker.juno;
const _comet = StorySpeaker.comet;

const seasonSixChapters = <StoryChapter>[
  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 6,
    number: 40,
    title: 'A Date in the Notebook',
    unlockLevel: 123,
    summary: 'Bertram has an item on his list from seventy-six years ago, and the sky has finally caught up with it.',
    scenes: [
      StoryScene(StoryBackdrop.hearth, [_chad, _maple, _pip, _bertram, _juno], [
        StoryLine(
          _n,
          "The hearth glows low and steady, the way it has all season, and for once nobody is leaning towards it. "
          "Bertram has his notebook open on his knee and is looking at one very old line.",
        ),
        StoryLine(
          _bertram,
          "I have found item twelve. It is the oldest one in the book. It says, in handwriting that is mostly mine, "
          "'See the comet.' It was written in pencil, when I was eight.",
        ),
        StoryLine(
          _maple,
          "That is a very small item for such a very old list. What comet?",
        ),
        StoryLine(
          _bertram,
          "The one that passes over the Starlit Isles once every seventy-six years. I was put to bed early that night. "
          "I was told it was too late for a child to stay up. I have thought about it on and off ever since.",
        ),
        StoryLine(
          _juno,
          "When does it come back? Is it, sorry, is it soon?",
        ),
        StoryLine(
          _n,
          "Bertram turns a page and holds it up. Someone, some time ago, has done a great deal of arithmetic in the margin and "
          "underlined the answer three times.",
        ),
        StoryLine(
          _bertram,
          "It is due this winter. It will take about as long to reach as it takes a very slow tortoise to cross a river.",
        ),
        StoryLine(
          _chad,
          "A comet! A date! A deadline in the actual sky! Everybody pack! We leave at once! We leave yesterday!",
        ),
        StoryLine(
          _maple,
          "Chad. It is seventy-six years long. It has never once been in a hurry.",
        ),
        StoryLine(
          _pip,
          "And nothing here has a deadline, you said so yourself. This is just a very big appointment.",
        ),
        StoryLine(
          _chad,
          "...A very big appointment that will not be rushed, at which I will arrive absolutely on time and perfectly calm.",
        ),
        StoryLine(
          _juno,
          "I think I'd like to come. If that's all right. I haven't been anywhere yet, except here.",
        ),
        StoryLine(
          _juno,
          "I still have the warm cup you gave me, you know. I've been drinking out of it for months.",
          only: StoryCondition('pass', 0),
        ),
        StoryLine(
          _juno,
          "I still have the little poker, you know. I keep it in my pocket. I haven't poked a single thing.",
          only: StoryCondition('pass', 1),
        ),
        StoryLine(
          _juno,
          "I still sit in the chair by the fire, you know. It's mine now, a bit. I hope that's all right.",
          only: StoryCondition('pass', 2),
        ),
        StoryChoice('date', 'What do you say to Bertram?', [
          StoryOption('It is going to be wonderful.', [
            StoryLine(
              _bertram,
              "Thank you. I have waited seventy-six years to be told that, and I am pleased to find it was worth the wait.",
            ),
          ]),
          StoryOption('We will get you there.', [
            StoryLine(
              _maple,
              "We will. I have already begun the list. I am on page two and it is not yet lunch.",
            ),
          ]),
          StoryOption('What is item thirteen?', [
            StoryLine(
              _bertram,
              "Ah. Item thirteen is 'ask what item thirteen is'. I wrote it when I was eight and I have never worked out why.",
            ),
          ]),
        ]),
        StoryLine(
          _chad,
          "Right! Maple, the list. Juno, boots. Bertram, a very warm hat. Pip, the map. And I will bring the cape and a "
          "quiet, dignified attitude.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 6,
    number: 41,
    title: 'Packing for the Sky',
    unlockLevel: 126,
    summary: 'Maple has a list, Chad has a cape, and Biscuit has already packed himself.',
    scenes: [
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _pip, _juno, _biscuit], [
        StoryLine(
          _n,
          "The hall has become a luggage shop. There are bags on the Duck Mat, bags on the bench and, for reasons nobody "
          "has yet explained, one bag on the ceiling.",
        ),
        StoryLine(
          _maple,
          "Item one: socks, two pairs. Item two: a flask. Item three: a spare flask in case the first flask has opinions.",
        ),
        StoryLine(
          _chad,
          "I have packed the cape, three capes, a cape for the cape, a rope and a drum.",
        ),
        StoryLine(
          _maple,
          "You will not need a drum.",
        ),
        StoryLine(
          _chad,
          "A drum is an emotional support instrument. I will be carrying it myself.",
        ),
        StoryLine(
          _juno,
          "Should I bring the notebook? I started one. It's not like Bertram's. It only has five items.",
        ),
        StoryLine(
          _pip,
          "Five is a great number. Mine had one for a whole month and it said 'ask where the Duck Mat is'.",
        ),
        StoryLine(
          _n,
          "Biscuit has been quietly missing for some time. He is eventually discovered inside the largest bag, sitting very "
          "still, with a small sausage and the air of a dog who has understood exactly what is going on.",
        ),
        StoryLine(_biscuit, "Woof."),
        StoryLine(
          _maple,
          "He has packed himself. That is, frankly, the most organised thing anyone has done in this hall all week.",
        ),
        StoryChoice('luggage', 'What goes in your bag?', [
          StoryOption('A warm layer, and a snack for later.', [
            StoryLine(
              _maple,
              "Layers and a snack. I want that on a sign. It is the entire art of travelling in four words and a comma.",
            ),
          ]),
          StoryOption('Something small from home.', [
            StoryLine(
              _juno,
              "That's what I'm bringing too. The cup. It weighs hardly anything and it makes everywhere feel a bit like here.",
            ),
          ]),
          StoryOption('Nothing at all. I will borrow.', [
            StoryLine(
              _chad,
              "Magnificent! A traveller of pure trust! Take my second cape. Take my third. Take the drum.",
            ),
            StoryLine(_maple, "Do not take the drum."),
          ]),
        ]),
        StoryLine(
          _n,
          "At the doorway Maple stops and looks at the whole untidy heap. She does not sigh. She has, over the years, stopped "
          "sighing at things she is fond of.",
        ),
        StoryLine(
          _maple,
          "Rest is training, and so is packing slowly. We leave in the morning. Nobody has to be anywhere before the kettle.",
        ),
        StoryLine(
          _chad,
          "At your own pace, everyone! That is the rule! Mostly I mean mine, but yours too!",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 6,
    number: 42,
    title: 'The Road Back Through Everywhere',
    unlockLevel: 129,
    summary: 'The way to the Isles runs through every place the guild has been, and everyone has something to hand over.',
    scenes: [
      StoryScene(StoryBackdrop.coastRoad, [_chad, _wren, _bertram, _juno], [
        StoryLine(
          _n,
          "The road to the Starlit Isles is not the shortest. It is, however, the one that goes back through everywhere, and "
          "nobody has the heart to suggest another.",
        ),
        StoryLine(
          _wren,
          "I heard you were passing. The light is lit, the fleet is in, and I have slept eleven hours. I have also brought a "
          "present.",
        ),
        StoryLine(
          _n,
          "She holds out a small brass lamp with a glass the colour of honey. A flame is already burning in it, steady and low.",
        ),
        StoryLine(
          _wren,
          "It is a little piece of the great lamp. It will not go out. Bertram, this is for the dark parts of the road.",
        ),
        StoryLine(
          _bertram,
          "I have never been given a lamp before. I would like it recorded that it is a great deal heavier than a notebook and "
          "ever so much more welcome.",
        ),
        StoryLine(
          _juno,
          "Is it always like this? People just give you things, on the way?",
        ),
        StoryLine(
          _chad,
          "Not always! It helps if you once said hello at a very dull moment in the past. Wren. Nice to see you rested.",
        ),
        StoryLine(
          _wren,
          "I am practically unrecognisable. I go to bed when the sun goes. It is shocking how much more day there is in the day.",
        ),
      ]),
      StoryScene(StoryBackdrop.passHut, [_chad, _hush, _tamsin, _bertram, _juno], [
        StoryLine(
          _n,
          "The next stop is a hut at the snow line, where a stove has been going for longer than anyone has counted, and a "
          "sign on the door says STOP HERE in careful paint.",
        ),
        StoryLine(
          _hush,
          "There is soup. There is always soup. I made a pot for sixty and then I made a smaller pot, because I thought you "
          "might be hungry in a smaller way.",
        ),
        StoryLine(
          _tamsin,
          "I came down my steps for this. Nine landings, and I stopped at every one. It took the whole morning, and I enjoyed "
          "all of it.",
        ),
        StoryLine(
          _hush,
          "I have brought you this, Bertram. It is a mug. It does not have a lid, because it is meant to be finished.",
        ),
        StoryLine(
          _bertram,
          "A mug to finish. Yes. I should like to finish a great many things. I have been collecting them.",
        ),
        StoryChoice('souvenir', 'What do you take from the road?', [
          StoryOption('A spoonful of soup, for the way.', [
            StoryLine(
              _hush,
              "A spoonful is the correct amount. It is exactly enough to know that there is more.",
            ),
          ]),
          StoryOption('The hut\'s sign, in my head.', [
            StoryLine(
              _tamsin,
              "'Stop here.' It is the best thing anyone has ever painted on a door. Take it with you, and use it at once and often.",
            ),
          ]),
          StoryOption('A good long look at everyone.', [
            StoryLine(
              _juno,
              "That's what I'm doing. I've only been here a short while and I want to remember how everybody looks when they are glad.",
            ),
          ]),
        ]),
        StoryLine(
          _chad,
          "On! To the next! To the dunes and the Sphinx and the Worm! At the speed of a leisurely walk!",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 6,
    number: 43,
    title: 'The Last Ferry',
    unlockLevel: 132,
    summary: 'A very slow tortoise, a very wide sky, and a crossing that takes exactly as long as it takes.',
    scenes: [
      StoryScene(StoryBackdrop.estuary, [_chad, _sedge, _bertram, _juno, _pip], [
        StoryLine(
          _n,
          "At the edge of the known map there is a river, and on the river there is a ferry, and on the ferry there is a "
          "tortoise who looks as though he has been expecting them for about four hundred years.",
        ),
        StoryLine(
          _sedge,
          "The ferry leaves when it leaves.",
        ),
        StoryLine(
          _chad,
          "Sedge! Old friend! When does it leave?",
        ),
        StoryLine(
          _sedge,
          "When you are all aboard and the tea is poured.",
        ),
        StoryLine(
          _pip,
          "It's what he said the first time, when I came to the coast. I thought it was a joke. It's actually just the truth.",
        ),
        StoryLine(
          _juno,
          "I've never been on a boat. Is it, how is it? Does it go quickly?",
        ),
        StoryLine(
          _sedge,
          "It goes at the speed of a river. Which is to say, it arrives.",
        ),
        StoryLine(
          _bertram,
          "I should like that on my list. 'Go at the speed of a river.' I shall tick it off the moment we land.",
        ),
        StoryChoice('crossing', 'How do you spend the crossing?', [
          StoryOption('Watching the water.', [
            StoryLine(
              _sedge,
              "Good. The water has a great deal to say, if nobody interrupts it.",
            ),
          ]),
          StoryOption('Looking up, for the first stars.', [
            StoryLine(
              _bertram,
              "Yes. I have been looking up for seventy-six years. I never get bored of it. Come and look with me, {hero}.",
            ),
          ]),
          StoryOption('Sitting with Sedge, saying nothing.', [
            StoryLine(
              _sedge,
              "Hm. You are very good company. It takes some people decades to learn to say nothing well.",
            ),
          ]),
        ]),
        StoryLine(
          _n,
          "The ferry slides away from the bank with no more fuss than a leaf. On the far shore, so faint it might be a smudge "
          "on the evening, a line of small lights floats a little above the water.",
        ),
        StoryLine(
          _juno,
          "Those are the islands. Those are really them. They look like somebody left a lot of lanterns out to dry.",
        ),
        StoryLine(
          _sedge,
          "The Isles are not far. Nothing is far, if you are not in a hurry. It is the rule of my whole profession.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 6,
    number: 44,
    title: 'Moths, Cats and One Large Turtle',
    unlockLevel: 135,
    summary: 'The Isles are full of polite creatures, and every one of them has been waiting for the comet too.',
    scenes: [
      StoryScene(StoryBackdrop.isles, [_chad, _bertram, _juno, _pip, _biscuit], [
        StoryLine(
          _n,
          "The Starlit Isles are exactly as they look from a distance, only more so. The grass is silver, the paths are "
          "made of small flat clouds, and everything makes a faint sound like a very pleased kettle.",
        ),
        StoryLine(
          _pip,
          "I thought it'd be scary. It's actually the calmest place I've ever been. Even the wind says 'pardon me'.",
        ),
        StoryLine(
          _n,
          "A large moth settles on Chad's shoulder, with a lantern glowing in its belly. It looks at him for a long time and "
          "then, apparently satisfied, goes to sit on the drum.",
        ),
        StoryLine(
          _chad,
          "It has chosen the drum. It knows. It knows the drum has meaning.",
        ),
        StoryLine(
          _n,
          "A cat the colour of twilight pads over, leaving a very faint trail of sparkle, and sits in front of Juno with the "
          "dignity of a diplomat. She holds out a hand. The cat considers it, and then, with great ceremony, leans.",
        ),
        StoryLine(
          _juno,
          "Oh. Oh, hello. You're warm. You're, hello. Is this a yes?",
        ),
        StoryLine(
          _bertram,
          "That is a yes. I have known a number of cats, and that was a signed and witnessed yes.",
        ),
        StoryLine(
          _n,
          "Behind them, very slowly, a hill stands up. It has a shell. It has a small, kind face. There are stars on its back, "
          "and some of them are joined by faint lines.",
        ),
        StoryLine(
          _n,
          "It is the Star Turtle. It looks at the little group for a long moment and then lowers its head, like a very large "
          "person bowing in a very small doorway.",
        ),
        StoryChoice('greeting', 'How do you greet the creatures of the Isles?', [
          StoryOption('With a slow bow.', [
            StoryLine(
              _pip,
              "That's what I'd do. It seems to understand it. It's bowing back, a bit slower, so we don't feel rushed.",
            ),
          ]),
          StoryOption('By sitting down with them.', [
            StoryLine(
              _juno,
              "That's the best idea. Everything is easier when you're at the same height as it.",
            ),
          ]),
          StoryOption('By asking what they are waiting for.', [
            StoryLine(
              _bertram,
              "Ah. That is the right question. I have a feeling the answer is the same as mine.",
            ),
          ]),
        ]),
        StoryLine(
          _n,
          "Every one of them, the moth, the cat, the turtle, the hundred small lights in the grass, has turned to look at the "
          "same patch of sky. They have been waiting too. Nobody here is in a hurry. The waiting is the thing itself.",
        ),
        StoryLine(
          _biscuit,
          "Woof.",
        ),
        StoryLine(
          _chad,
          "Biscuit agrees. He always does, but this time it counts.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 6,
    number: 45,
    title: 'The Comet King Is Early',
    unlockLevel: 138,
    summary: 'The most important guest in the sky has arrived three days ahead of himself and is very worried about it.',
    scenes: [
      StoryScene(StoryBackdrop.cometSky, [_chad, _bertram, _juno, _comet], [
        StoryLine(
          _n,
          "On the highest island there is a very bright light, sitting on the grass with its arms around its knees, and a "
          "crown slightly askew. It is, quite clearly, trying not to be seen.",
        ),
        StoryLine(
          _comet,
          "Go away. No. Do not go away. But do not look at me. I am not supposed to be here for three days.",
        ),
        StoryLine(
          _chad,
          "Your Majesty! I am Chad, guildmaster, and I would like to say that I am a tremendous admirer of arriving on time.",
        ),
        StoryLine(
          _comet,
          "That is the whole problem. I have arrived on time for seventy-six years, and this time I came early. I looked at the "
          "road and I thought, what if I am late, and I went too fast, and now I am here, and nothing is ready.",
        ),
        StoryLine(
          _juno,
          "I think everything is ready. The moths are ready. The cat is ready. There's a turtle with the whole sky on its back.",
        ),
        StoryLine(
          _comet,
          "But I am three days early. A king is not three days early. A king is on the dot.",
        ),
        StoryLine(
          _bertram,
          "May I say something? I have waited seventy-six years for you, and I have never once minded that you took your time. "
          "I should not mind three days at all. I would be glad of the company.",
        ),
        StoryLine(
          _comet,
          "...You would?",
        ),
        StoryLine(
          _n,
          "The light turns slowly, and for the first time shows its face. It is round and rather pale and has the look of "
          "somebody who has not slept properly since a previous century.",
        ),
        StoryLine(
          _chad,
          "Stay right where you are, Your Majesty. Rest is training. You have been going for seventy-six years. Sit. We will "
          "bring tea.",
        ),
        StoryChoice('king', 'What do you say to the Comet King?', [
          StoryOption('Early is only another way to arrive.', [
            StoryLine(
              _comet,
              "Early is only another way to arrive. I shall put that on a flag. I have a great many flags.",
            ),
          ]),
          StoryOption('Nobody minds. We are glad you came.', [
            StoryLine(
              _comet,
              "Glad. That is a word I do not hear very often, on my long road. It is a very good word. I should like some more of it.",
            ),
          ]),
          StoryOption('Would you like to stay with us until it is time?', [
            StoryLine(
              _comet,
              "Yes. Yes, I should. I have never stayed anywhere. I have only ever passed.",
            ),
          ]),
        ]),
        StoryLine(
          _comet,
          "I have an idea. I will not pass over tonight. I will not cross the sky until you are all rested and ready. A king may "
          "do that. A king may be as slow as his guests like.",
        ),
        StoryLine(
          _chad,
          "Your Majesty. Truly. You are my favourite king.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 6,
    number: 46,
    title: 'The Night Before the Sky',
    unlockLevel: 141,
    summary: 'Everyone lies on their backs on a floating island and says what they would tell the person they were at the start.',
    scenes: [
      StoryScene(StoryBackdrop.highCamp, [_chad, _maple, _pip, _bertram, _juno], [
        StoryLine(
          _n,
          "There is a small fire, the low red kind. There are blankets and a flask and, a little way off, a king who has "
          "lain down with his crown over his eyes and is almost certainly asleep.",
        ),
        StoryLine(
          _maple,
          "I have checked the list. There is nothing left on it. I have not been here before, and I find I do not mind in the slightest.",
        ),
        StoryLine(
          _pip,
          "I want to say something. If I could tell the me who walked in, who was so sure everybody knew what they were doing, I'd say: "
          "the wall counts. And so do you.",
        ),
        StoryLine(
          _juno,
          "I'd tell the me at the door that it's fine to be nervous. And that someone will have the kettle on. They really will.",
        ),
        StoryLine(
          _maple,
          "I would tell mine to stop counting for a minute and sit down. It would not listen. I would sit beside it anyway.",
        ),
        StoryLine(
          _bertram,
          "And I would say to the boy who was put to bed early: it is all right. It was only a long way off. It was always going "
          "to be worth the wait.",
        ),
        StoryLine(
          _chad,
          "I would tell the Chad who arrived with a very big cape and no idea what he was doing that he did start at Level 1, like "
          "everyone. And that it turned out all right. And that the cape was too long.",
        ),
        StoryChoice('stars', 'What would you tell the person you were at the start?', [
          StoryOption('You do not have to be good at it yet.', [
            StoryLine(
              _juno,
              "Yes. That's the one I needed. I think I needed it more than anything.",
            ),
          ]),
          StoryOption('Keep going at your own pace. It all adds up.', [
            StoryLine(
              _maple,
              "At your own pace. It adds up, slowly, in the background, the way interest does. I keep a column for it.",
            ),
          ]),
          StoryOption('Look up sometimes.', [
            StoryLine(
              _bertram,
              "Look up sometimes. Item one hundred and twelve. I shall write it in ink.",
            ),
          ]),
        ]),
        StoryLine(
          _pip,
          "Nothing here has a deadline, even the comet. It's just waiting for us to be ready.",
        ),
        StoryLine(
          _n,
          "One by one they lie back in the silver grass. The fire ticks. Somewhere a moth settles on a drum with a faint, "
          "contented thump. For a long time nobody says anything, which is the best thing anyone could have said.",
        ),
        StoryLine(
          _juno,
          "Everything's very big. And I'm very small. And it doesn't feel bad at all.",
        ),
        StoryLine(
          _bertram,
          "No. It feels like belonging to something. Good night, everyone. Good night, sky.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 6,
    number: 47,
    title: 'The Comet Road',
    unlockLevel: 144,
    summary: 'The comet passes, an old notebook gets a tick, and the road home is the road on.',
    scenes: [
      StoryScene(StoryBackdrop.cometSky, [_chad, _bertram, _juno, _pip, _comet], [
        StoryLine(
          _n,
          "The sky does not warn anyone. It simply, very quietly, begins to glow along one edge, the way a window does when "
          "somebody in the next room turns on a lamp.",
        ),
        StoryLine(
          _comet,
          "I am ready now. I would like to say I have rested, and that I have never been so well prepared for a journey in my "
          "entire very long life.",
        ),
        StoryLine(
          _bertram,
          "Then let us all be quiet and look.",
        ),
        StoryLine(
          _n,
          "He rises in a long, bright arc, trailing a tail of blue light across the whole dark width of the world. It is slow. "
          "It is gentle. It is, without any exaggeration, the most beautiful thing any of them has ever seen.",
        ),
        StoryLine(
          _juno,
          "Oh. Oh, it's really there. It's actually there.",
        ),
        StoryLine(
          _pip,
          "I can't believe it's so quiet. You'd think it'd be louder.",
        ),
        StoryLine(
          _chad,
          "I had prepared a speech with a goose in it. I find I have nothing to say at all. This is a first.",
        ),
        StoryLine(
          _n,
          "Bertram takes out his notebook. His hands are not quite steady. He finds item twelve, in the pencil of a boy of eight, "
          "and, slowly, with a pen that has been in his pocket the whole journey, he draws a tick.",
        ),
        StoryLine(
          _bertram,
          "There. It is done. It took seventy-six years and an extra eleven weeks of packing, and I would not change a minute.",
        ),
        StoryChoice('look', 'What do you do as the comet passes?', [
          StoryOption('Stand beside Bertram.', [
            StoryLine(
              _bertram,
              "Thank you. It is a great thing, to be next to somebody at the moment a very old wish comes true.",
            ),
          ]),
          StoryOption('Make a wish of your own.', [
            StoryLine(
              _juno,
              "I'm doing that too. I won't say what. It's a small one, and it's already coming true.",
            ),
          ]),
          StoryOption('Just look, with everything you have.', [
            StoryLine(
              _comet,
              "Yes. That is what I am for. It is all I ever hoped anybody would do.",
            ),
          ]),
        ]),
        StoryLine(
          _comet,
          "I shall be back in seventy-six years. I would be delighted if there were a chair for me. I will bring the early arrival, "
          "and a very good reason.",
        ),
        StoryLine(
          _chad,
          "There will be a chair. There will be a very good chair, and it will be next to Juno's, and a kettle will be on.",
        ),
      ]),
      StoryScene(StoryBackdrop.hearth, [_chad, _maple, _pip, _bertram, _juno], [
        StoryLine(
          _n,
          "The road home is shorter than the road there, as roads home always are. The hall is dark, except for one low red line "
          "in the grate, which has been there the whole time.",
        ),
        StoryLine(
          _maple,
          "The hearth has held. Nobody fed it. It has been keeping itself quite well, thank you.",
        ),
        StoryLine(
          _juno,
          "I think I get it now. All of it. It's not about getting there. It's about being the sort of person who goes.",
        ),
        StoryLine(
          _pip,
          "And there's a chair by the fire for whoever turns up next. There always is.",
        ),
        StoryLine(
          _bertram,
          "I have a new list. It has only one item. Item one: whatever comes next. I do not know what it is. I am delighted.",
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Move however you like, rest when you need to, and always leave the kettle on. The hall is yours.",
          only: StoryCondition('motivation', 0),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Have fun with it, the way you said you would, and bring a comet, or a friend. The hall is yours.",
          only: StoryCondition('motivation', 1),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Stay curious, the way you did from the very first day. There is always one more sky. The hall is yours.",
          only: StoryCondition('motivation', 2),
        ),
        StoryLine(
          _n,
          "Far away a bell rings, a lamp winks, a chime sings, a table is laid and a small fire is kept. And somewhere very high, "
          "a king drifts on, taking his time, at his own pace, towards a chair that will be waiting seventy-six years from now.",
        ),
      ]),
    ],
  ),
];
