/// Season Five, "The Banked Fire": a prologue and seven chapters set partly in the
/// guild hall and partly in the forge below it. The great hearth is burning low,
/// Chad's answer is to feed it all night, and an old note in the founder's hand says
/// the fire is meant to be kept, not fed. The same rules apply as in the earlier
/// seasons (see docs/STORY.md and docs/CONTENT_GUIDELINES.md): warm and funny,
/// nothing timed, nothing that shames, and rest shown as an ordinary part of the way.
/// It is free for everyone, like the others.
///
/// Its theme is keeping a flame going: effort that lasts is low, steady and shared,
/// a fire is banked rather than blazed, and everyone takes a turn. It also carries
/// the story past the old level cap, and ends with somebody new at the door.
library;

import 'package:i_am_chad/domain/story.dart';

const _n = StorySpeaker.narrator;
const _chad = StorySpeaker.chad;
const _maple = StorySpeaker.maple;
const _biscuit = StorySpeaker.biscuit;
const _pip = StorySpeaker.pip;
const _wren = StorySpeaker.wren;
const _fennel = StorySpeaker.fennel;
const _hush = StorySpeaker.hush;
const _tamsin = StorySpeaker.tamsin;
const _bertram = StorySpeaker.bertram;
const _brun = StorySpeaker.brun;
const _magmara = StorySpeaker.magmara;

const seasonFiveChapters = <StoryChapter>[
  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 5,
    number: 32,
    title: 'The Hearth Goes Quiet',
    unlockLevel: 100,
    summary: 'The great hearth is burning low, Chad has been feeding it all night, and an old note says something else.',
    scenes: [
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _pip, _bertram, _biscuit], [
        StoryLine(
          _n,
          "The great hearth of the Guild Hall of Steady Steps has been lit for longer than anyone can remember. This "
          "morning it is the colour of a very tired peach.",
        ),
        StoryLine(
          _maple,
          "I have counted the logs. We have burned a winter's worth since midnight, and the fire is smaller than when "
          "we started. I would like it written down that I said so.",
        ),
        StoryLine(
          _chad,
          "Nonsense! The answer to a low fire is a bigger fire! More logs! More bellows! I have not slept, and I have "
          "never felt more awake!",
        ),
        StoryLine(
          _pip,
          "Chad, you've been standing there since the lamps went out. You're swaying a little.",
        ),
        StoryLine(_chad, "That is the sway of a man in command of a hearth!"),
        StoryLine(
          _n,
          "Biscuit has left his place on the rug, which has gone cold, and moved to a stool beside the kettle. He is "
          "looking at the hearth the way you look at a friend who has stopped answering.",
        ),
        StoryLine(
          _bertram,
          "I have been reading the old guild book, and there is a note in the margin. 'Do not feed the fire. Keep it.' "
          "It is underlined twice, and then somebody has drawn a very small cake.",
        ),
        StoryLine(
          _maple,
          "That is the founder's handwriting. It is the only note she ever wrote that I do not understand.",
        ),
        StoryLine(_chad, "Keep it! I am keeping it! I am keeping it so hard!"),
        StoryLine(_pip, "Maybe keeping and feeding aren't the same thing?"),
        StoryChoice('first', 'What do you do first?', [
          StoryOption('Sit Chad down with a cup of tea.', [
            StoryLine(
              _maple,
              "Thank you. I have been trying to do that since three o'clock this morning.",
            ),
            StoryLine(
              _chad,
              "I am not sitting. I am leaning. Next to a chair. Companionably.",
            ),
          ]),
          StoryOption('Help Maple read the old book.', [
            StoryLine(
              _maple,
              "A second pair of eyes! I will make you a list. It will have only four things on it, which for me is a "
              "holiday.",
            ),
          ]),
          StoryOption('Ask the fire what it wants.', [
            StoryLine(
              _bertram,
              "Oh, I do like that. Nobody has asked it. We have all been telling it.",
            ),
            StoryLine(
              _n,
              "The hearth gives one soft crackle, in the manner of a very old person clearing their throat.",
            ),
          ]),
        ]),
        StoryLine(
          _maple,
          "The next page has a drawing of the door under the stairs, and beneath it, three words. 'Ask the smith.'",
        ),
        StoryLine(_chad, "We have a smith?"),
        StoryLine(
          _maple,
          "We have a door. I have always assumed it was a cupboard.",
        ),
        StoryLine(
          _bertram,
          "Item one hundred and five. Find out what is in the cupboard. Item one hundred and six: tea.",
        ),
        StoryLine(
          _chad,
          "Right! Down we go! At speed! ...Maple?",
        ),
        StoryLine(
          _maple,
          "At your own pace, Chad. Nothing here has a deadline except the tea, which is cooling.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 5,
    number: 33,
    title: 'The Door Under the Stairs',
    unlockLevel: 103,
    summary: 'A cupboard that was never a cupboard, a great many warm steps down, and a letter for whoever finally asked.',
    scenes: [
      StoryScene(StoryBackdrop.cellar, [_chad, _maple, _pip, _bertram], [
        StoryLine(
          _n,
          "The cupboard under the stairs is not a cupboard. It is a landing, and past the landing is a stair, and the "
          "stair goes down in the confident manner of something that has been going down for years.",
        ),
        StoryLine(
          _pip,
          "Forty-one steps, forty-two... I've lost count. I think that means we're very far down.",
        ),
        StoryLine(
          _bertram,
          "I count in sevens. It is far more restful, and nobody ever argues with a seven.",
        ),
        StoryLine(
          _n,
          "It is getting warmer with every step. The air smells like toast and old iron, in about equal parts.",
        ),
        StoryLine(
          _chad,
          "Onward! Downward! At the speed of a legend! ...I am going to sit on this step for a moment. On purpose. "
          "Tactically.",
        ),
        StoryLine(
          _maple,
          "You have been tactically sitting on every third step for the last ten minutes.",
        ),
        StoryLine(
          _chad,
          "A hero must be well rested to meet a smith. Rest is training. I said that. Mostly. In a quieter voice.",
        ),
        StoryChoice('descent', 'How do you go down?', [
          StoryOption('One landing at a time.', [
            StoryLine(
              _pip,
              "That's what I do too. Landing, breath, landing. It is the same stair, it just stops being long.",
            ),
          ]),
          StoryOption('Carrying the lantern, so everyone can see.', [
            StoryLine(
              _bertram,
              "A lantern bearer! I shall write it down. The lantern bearer is the most important person on the stair, "
              "and also the one who gets to look at everyone's shoes.",
            ),
          ]),
          StoryOption('Right behind Chad, just in case.', [
            StoryLine(
              _maple,
              "That is the best seat on a staircase. I have held it for eleven years.",
            ),
          ]),
        ]),
        StoryLine(
          _n,
          "Something comes up the stair towards them, very fast, then stops, and sits down heavily on a step with its "
          "satchel in its lap. It has a red scarf.",
        ),
      ]),
      StoryScene(StoryBackdrop.cellar, [_chad, _maple, _pip, _fennel], [
        StoryLine(
          _fennel,
          "Hello! I am fine! I have fallen over on the way up and I am being very calm about it.",
        ),
        StoryLine(
          _pip,
          "Fennel! What are you doing under the hall?",
        ),
        StoryLine(
          _fennel,
          "Delivering. I come down this stair every spring and nobody has ever once said hello. It's been the loneliest "
          "post round in the valley, and it's mine.",
        ),
        StoryLine(
          _maple,
          "I am so sorry. I assumed you were something from the cellar.",
        ),
        StoryLine(
          _fennel,
          "I was something from the cellar! I've been something from the cellar for years!",
        ),
        StoryLine(
          _n,
          "Fennel digs in the satchel and produces a very old, very warm envelope. It says: FOR WHOEVER FINALLY ASKED.",
        ),
        StoryLine(
          _chad,
          "'Dear whoever finally asked. The kettle has been on for eleven years. Bring a friend, bring a coat and do "
          "not, under any circumstances, bring more logs. Yours, B.'",
        ),
        StoryLine(
          _maple,
          "Do not bring more logs.",
        ),
        StoryLine(
          _chad,
          "I have a great many logs. I had a great many. I used them all. I am going to put the remaining logs down now, "
          "gently, as if they were sleeping.",
        ),
        StoryLine(
          _fennel,
          "He means it kindly. He signs everything B. He has never once been late with a reply, and I have never once "
          "been on time with the post. It balances.",
        ),
        StoryLine(
          _pip,
          "Come on. It's only a bit further. I can see a glow.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 5,
    number: 34,
    title: 'A Smith With Opinions',
    unlockLevel: 106,
    summary: 'Below the hall a forge has been waiting eleven years, and its smith has a lot to say about fires.',
    scenes: [
      StoryScene(StoryBackdrop.forge, [_chad, _maple, _pip, _bertram, _brun], [
        StoryLine(
          _n,
          "The stair ends in a room so warm and so orange that it feels like walking into the inside of a loaf. There "
          "is an anvil, a wall of tools, a furnace like an open mouth, and a very large person in an apron, who "
          "turns around slowly and takes his goggles off.",
        ),
        StoryLine(
          _brun,
          "Somebody knocked. In eleven years, that is the first knock that was not a goat.",
        ),
        StoryLine(
          _chad,
          "Greetings! I am Chad, the guildmaster! I am here about the hearth, and I have brought everyone, and "
          "I have very nearly stopped bringing logs!",
        ),
        StoryLine(
          _brun,
          "Brun. Forgemaster. I made your bell, your front door, your spoons, and, if I am honest, most of the swords "
          "in your cellar, about which I have opinions.",
        ),
        StoryLine(_maple, "The cellar swords are very good swords."),
        StoryLine(
          _brun,
          "They are adequate. The third one on the left is a crime. I did it on a Tuesday.",
        ),
        StoryLine(
          _bertram,
          "Item one hundred and seven. Ask about the swords. Item one hundred and eight: do not ask about the swords.",
        ),
        StoryLine(
          _brun,
          "I have been waiting for someone to ask me which fire you want. A forge or a hearth. They are not the same "
          "fire.",
        ),
        StoryLine(
          _chad,
          "A fire is a fire! Bigger is better! Hotter is more!",
        ),
        StoryLine(
          _brun,
          "A forge burns hot for an hour and then it rests. A hearth burns low for a hundred years and never once "
          "stops. Different fire. Different fuel. The very same flame.",
        ),
        StoryLine(
          _brun,
          "I lit your hearth, a long time ago, from this forge. A very kind woman asked me to. Then she banked it, "
          "and left a note, and forgot to tell anyone how.",
        ),
        StoryLine(
          _maple,
          "The founder. She forgot to tell anyone how.",
        ),
        StoryLine(
          _brun,
          "She was busy, and she trusted the fire. That is a thing you can only do once you have learned how to keep "
          "one.",
        ),
        StoryChoice('make', 'What would you make, if Brun lent you the anvil?', [
          StoryOption('A spoon, for soup.', [
            StoryLine(
              _brun,
              "A spoon! The best answer anyone has given me since a sword. Spoons are what hold the day together.",
            ),
          ]),
          StoryOption('A very small bell.', [
            StoryLine(
              _brun,
              "Small bells are a delight. They only ever say one thing, and they say it kindly.",
            ),
          ]),
          StoryOption('A sword with opinions.', [
            StoryLine(
              _brun,
              "Oh, no. I made one of those once. It argued with the cat for a decade. I will not do it again. I would "
              "do it again.",
            ),
          ]),
        ]),
        StoryLine(
          _pip,
          "Can you show us how? The keeping? I think we'd all like to learn it properly.",
        ),
        StoryLine(
          _brun,
          "Gladly. But first you must meet whoever is sleeping under the coals, because it is her fire as much as "
          "it is yours.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 5,
    number: 35,
    title: 'Magmara Is Not Annoyed',
    unlockLevel: 109,
    summary: 'A mountain who takes eleven years to get annoyed, and a very small conversation about poking.',
    scenes: [
      StoryScene(StoryBackdrop.embers, [_chad, _pip, _bertram, _brun, _magmara], [
        StoryLine(
          _n,
          "Beyond the forge the floor slopes into a cavern with a slow river of orange running through it. In the "
          "middle of the river, which should be impossible, there is a small, calm mountain with a face.",
        ),
        StoryLine(
          _brun,
          "That is Magmara, the Slow Simmer. The fire in your hearth is the end of her front step. She has been very "
          "kind about it.",
        ),
        StoryLine(
          _bertram,
          "How do you do, Magmara! I am Bertram. I am eighty-four now, so I am rather good at waiting.",
        ),
        StoryLine(
          _n,
          "The mountain's eyes open, very slowly, in the way a window opens when the wind is thinking about it.",
        ),
        StoryLine(
          _magmara,
          "...Hello.",
        ),
        StoryLine(
          _brun,
          "It takes her a little while. I always wait for the next word before I say anything.",
        ),
        StoryChoice('slow', 'How do you speak to Magmara?', [
          StoryOption('Very slowly.', [
            StoryLine(
              _magmara,
              "...Oh. Thank you. Most people talk as if the sentence were on fire. It is... a relief.",
            ),
          ]),
          StoryOption('Quietly, and then wait.', [
            StoryLine(
              _magmara,
              "...That was lovely. You asked, and then you left room. Hardly anyone leaves room.",
            ),
          ]),
          StoryOption('With a hum.', [
            StoryLine(
              _magmara,
              "...Mm. I know that one. Someone hummed it above my head, for ten winters, while they were poking.",
            ),
          ]),
        ]),
        StoryLine(
          _magmara,
          "...I am not annoyed. I want that understood. I have been not annoyed since the third winter. It is going "
          "very well.",
        ),
        StoryLine(_pip, "Oh. Oh no. It's the logs, isn't it."),
        StoryLine(
          _magmara,
          "...It is every night, for eleven years. A poke, and a poke, and a poke. They are very small pokes. I have a "
          "large front step.",
        ),
        StoryLine(
          _chad,
          "...I may have been the poker.",
        ),
        StoryLine(
          _magmara,
          "...You have a great deal of energy.",
        ),
        StoryLine(
          _chad,
          "I do! I have! And I used all of it on the wrong end! I thought a fire was a thing you give your strength to, "
          "and it is a thing you give your patience to, and I have never once given my patience to anything!",
        ),
        StoryLine(
          _brun,
          "He is learning. Look at his face. It is the face of a man who has put down a log.",
        ),
        StoryLine(
          _magmara,
          "...Rest is training. Ask any mountain. You do not get to be a mountain by hurrying.",
        ),
        StoryLine(
          _magmara,
          "...Poke less, banked more. I will keep the seam warm, if you keep the fire low. At my own pace. Nothing "
          "here has a deadline.",
        ),
        StoryLine(
          _chad,
          "I accept! I accept all of it, very quietly!",
        ),
        StoryLine(
          _bertram,
          "Item one hundred and nine. Learn how to leave room. I have a feeling it will fill the notebook.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 5,
    number: 36,
    title: 'How to Bank a Fire',
    unlockLevel: 112,
    summary: 'Rake, cover, leave a little air, and walk away. Everyone has a turn, and Chad has two.',
    scenes: [
      StoryScene(StoryBackdrop.forge, [_brun, _chad, _maple, _bertram, _pip], [
        StoryLine(
          _brun,
          "Banking a fire has four steps. Rake the coals to the middle. Cover them with ash. Leave a thumb of air. And "
          "walk away. The last one is the hardest.",
        ),
        StoryLine(
          _chad,
          "Walk away! From a fire! That is the opposite of everything I believe in!",
        ),
        StoryLine(
          _brun,
          "A fire that is watched every minute is a fire that is being fed every minute. Sooner or later it gets tired "
          "of the attention. You can trust it to know how.",
        ),
        StoryLine(
          _n,
          "Brun hands out rakes. Maple's is the right size. Bertram's is slightly too tall, so he holds it like a "
          "walking stick and pretends that is on purpose.",
        ),
        StoryLine(
          _maple,
          "Rake to the middle. I can do a middle. I have been doing a middle for eleven years.",
        ),
        StoryLine(
          _pip,
          "The coals look so small, all piled up in the middle. Is that all the fire there is?",
        ),
        StoryLine(
          _brun,
          "That is all the fire there ever is. The rest is show. A low red glow can keep a house warm for a week.",
        ),
        StoryLine(
          _n,
          "Chad takes his turn, with ash, with great seriousness. He covers the coals so thoroughly that for a moment "
          "the fire is gone entirely, and everyone holds their breath.",
        ),
        StoryLine(
          _brun,
          "That is too much cover. Smothering is not keeping. Lift a little. There. See it breathe?",
        ),
        StoryLine(
          _chad,
          "It is breathing! I did that! Very well, with help! Mostly with help!",
        ),
        StoryChoice('air', 'How much air does a banked fire need?', [
          StoryOption('A thumb\'s worth.', [
            StoryLine(
              _brun,
              "Exactly a thumb. Not a fist, not a finger. Yours is a very good thumb.",
            ),
          ]),
          StoryOption('As much as it asks for.', [
            StoryLine(
              _brun,
              "That is the answer of someone who listens. It asks for very little, and very quietly, and a good keeper "
              "hears it.",
            ),
          ]),
          StoryOption('Enough to breathe, and no more.', [
            StoryLine(
              _brun,
              "Enough to breathe, and no more. I will carve that over the door.",
            ),
          ]),
        ]),
        StoryLine(
          _brun,
          "People are the same, you know. A fire that blazes all night is out by morning. A fire that is kept is "
          "still there on Tuesday.",
        ),
        StoryLine(
          _maple,
          "I think that was the founder's whole note. 'Do not feed the fire. Keep it.' She was not talking about logs.",
        ),
        StoryLine(
          _chad,
          "I started at Level 2. I would like to try the rest of it at Level Banked.",
        ),
        StoryLine(
          _pip,
          "That's a very good level.",
        ),
        StoryLine(
          _brun,
          "Now take a coal home. Not a log, a coal. A small one, in a clay pot, with the lid on, carried carefully. It "
          "will light the hearth, and the hearth will do the rest.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 5,
    number: 37,
    title: 'The Bucket Chain',
    unlockLevel: 115,
    summary: 'One pot of glowing coals, one very long stair, and a great many friends to hand it along.',
    scenes: [
      StoryScene(StoryBackdrop.embers, [_chad, _brun, _hush, _wren, _tamsin], [
        StoryLine(
          _n,
          "The clay pot is not large. It is warm to hold, as heavy as a loaf, and the stair back up to the hall is "
          "four hundred and twelve steps and a few extra for luck.",
        ),
        StoryLine(
          _brun,
          "You do not carry a coal up a stair by yourself. That is how a coal goes out and a person goes red. You pass "
          "it. Hand to hand.",
        ),
        StoryLine(
          _n,
          "Word has gone up the stair, and down it, and round it. Footsteps are arriving: a yeti with a pot of soup, a "
          "lighthouse keeper in a yellow coat, and a Weatherkeeper who has come down her own steps and now, kindly, "
          "agrees to go up someone else's.",
        ),
        StoryLine(
          _hush,
          "I brought soup. Nobody asked, which is the best time to bring it.",
        ),
        StoryLine(
          _wren,
          "I brought a lantern, in case the stair is dark. It never quite goes out. Neither does Chad, but he is "
          "better in daylight.",
        ),
        StoryLine(
          _tamsin,
          "I came down by landings, and I will go up by landings. A step is a step. Everyone gets their turn at one.",
        ),
        StoryLine(
          _hush,
          "{hero}, you were going to give the guild a story, a song or an afternoon, if I remember. This is an afternoon.",
          only: StoryCondition('gift', 2),
        ),
        StoryLine(
          _wren,
          "{hero} said they would give the guild a story. A stair is a very good length for one.",
          only: StoryCondition('gift', 0),
        ),
        StoryLine(
          _tamsin,
          "{hero} said they would give a song. We have four hundred steps, and a song is about fifty steps long. We "
          "will need eight.",
          only: StoryCondition('gift', 1),
        ),
        StoryChoice('carry', 'Which stretch do you take?', [
          StoryOption('The steepest bit, in short turns.', [
            StoryLine(
              _brun,
              "The steepest bit, where the pot wants to roll. A good place for someone who steps carefully.",
            ),
            StoryLine(
              _chad,
              "I shall be right behind you, saying nothing, extremely quietly!",
            ),
          ]),
          StoryOption('The middle, with a story.', [
            StoryLine(
              _wren,
              "The middle is where it gets long, and the story is what makes it short. Good choice.",
            ),
          ]),
          StoryOption('The top, to hand it over.', [
            StoryLine(
              _tamsin,
              "The last landing. Everyone dreams of it, and hardly anyone knows what to say when they arrive. You will.",
            ),
          ]),
        ]),
        StoryLine(
          _n,
          "The pot goes up. Hush to Wren, Wren to Tamsin, Tamsin to Chad, Chad, for the first time in his life, to "
          "somebody else without trying to carry it further. Each hand is warm for a minute, and then empty, and "
          "that is how it works.",
        ),
        StoryLine(
          _chad,
          "I gave it away! I gave it away and it is still going! That is the most magnificent thing I have ever not "
          "done!",
        ),
        StoryLine(
          _brun,
          "That is the whole of banking. You do not hold the fire. You hand it on.",
        ),
        StoryLine(
          _hush,
          "There is soup at the top. There is always soup at the top.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 5,
    number: 38,
    title: 'The Night Before the Hearth',
    unlockLevel: 118,
    summary: 'A cold hall, a warm pot and some true confessions. Maple tells the real story of the first fire.',
    scenes: [
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _bertram, _pip, _biscuit], [
        StoryLine(
          _n,
          "The hall is dark and the hearth is cold, and in the middle of the cold hearth, in a clay pot with its lid on, "
          "is a small red glow. Everyone has pulled up a chair and a blanket and is looking at it, politely.",
        ),
        StoryLine(
          _biscuit,
          "Woof.",
        ),
        StoryLine(
          _chad,
          "Biscuit says that the pot is the best thing that has ever happened, and I agree with him, and so does he.",
        ),
        StoryLine(
          _pip,
          "Tomorrow we put it in the hearth, don't we? I don't want to do it tonight. It feels like it should wait for "
          "the morning.",
        ),
        StoryLine(
          _maple,
          "Nothing here has a deadline. A fire is lit when it is ready, and not before. I think the founder would "
          "have liked that.",
        ),
        StoryLine(
          _bertram,
          "I would like to say something. I have written it down, so that I do not lose it. 'I came to this hall to "
          "begin. I have found that beginning is something you do over and over.' Item one hundred and ten.",
        ),
        StoryLine(
          _chad,
          "I would also like to say something. I have a confession.",
        ),
        StoryLine(_maple, "Chad."),
        StoryLine(
          _chad,
          "I did not light the first fire. I have always said that I did. In fact I took a great deal of credit, and "
          "I stood very near it.",
        ),
        StoryLine(
          _maple,
          "I lit it, the week you arrived. It was a wet Thursday, and you were out buying a bell. I let you say it was "
          "you.",
        ),
        StoryLine(_chad, "You let me?"),
        StoryLine(
          _maple,
          "You looked so pleased. I thought, a hall needs one person who stands near the fire and says it is theirs, "
          "and one who quietly knows how it works.",
        ),
        StoryLine(
          _chad,
          "I am not even annoyed. That is the strangest part. I am just... deeply impressed.",
        ),
        StoryLine(
          _pip,
          "I think that's the nicest thing anyone's ever said at a hearth.",
        ),
        StoryLine(
          _n,
          "Something small and bright is in {hero}'s hand: a little iron poker, no longer than a fork, with a tiny "
          "flame stamped on the handle. It was in the pot, tucked under the lid. A note is tied to it.",
        ),
        StoryLine(
          _chad,
          "'For the one who carried it. Do not poke. Keep it, and one day give it to someone who is just starting. "
          "Yours, B.'",
        ),
        StoryChoice('keepsake', 'What do you do with Brun\'s little poker?', [
          StoryOption('Hang it by the hearth.', [
            StoryLine(
              _maple,
              "By the hearth, where everyone passes it. I will put a hook up in the morning. I will measure it twice.",
            ),
          ]),
          StoryOption('Keep it in my pocket.', [
            StoryLine(
              _bertram,
              "A pocket is the finest place for a small useful thing. I have a poker, a pencil and a biscuit in mine.",
            ),
          ]),
          StoryOption('Save it for someone who is just starting.', [
            StoryLine(
              _pip,
              "I think that's exactly what it's for. Somebody gave me a mug once, a long time ago, and it is still "
              "my favourite thing.",
            ),
          ]),
        ]),
        StoryLine(
          _chad,
          "Everybody sleep. The fire is in its pot, and the pot is in the hall, and the hall is, for once, not on fire "
          "or about to be.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 5,
    number: 39,
    title: 'The Banked Fire',
    unlockLevel: 120,
    summary: 'The hearth is lit and kept, and somebody new knocks at the door.',
    scenes: [
      StoryScene(StoryBackdrop.hearth, [_chad, _maple, _brun, _bertram, _pip], [
        StoryLine(
          _n,
          "In the morning, light comes through the windows in the careful way it does when it has been invited. Brun "
          "has come up from below with soot on his goggles and an expression of high professional anxiety.",
        ),
        StoryLine(
          _brun,
          "I have not been in a hall for eleven years. I do not know where to put my hands. May I hold something?",
        ),
        StoryLine(
          _maple,
          "Hold the kettle. It is a very forgiving kettle.",
        ),
        StoryLine(
          _n,
          "Maple rakes the cold ash to the sides. Pip lifts the lid of the pot. The coal inside is no bigger than a "
          "walnut, and it glows the way a sleeper breathes.",
        ),
        StoryLine(
          _chad,
          "The fire is the size of a walnut. I have been feeding fires the size of a cart, and I have never been so "
          "proud of anything.",
        ),
        StoryLine(
          _bertram,
          "Rake. Cover. A thumb of air. Walk away. I have it on a card.",
        ),
        StoryLine(
          _n,
          "Everyone takes a turn. Maple lays a little kindling, a handful of dry sticks, and no more. Pip tips the "
          "coal in. Bertram breathes a thumb's worth of air across it. Chad covers it with ash, carefully, and stops "
          "before it is too much.",
        ),
        StoryLine(
          _n,
          "For a moment nothing happens. Then, in the dark of the grate, a small orange line appears, steady and "
          "low, like a pencil mark on a page.",
        ),
        StoryLine(
          _brun,
          "That is it. That is a hearth. It will be here at dawn, and next dawn, and the dawn after that, if you "
          "let it be.",
        ),
        StoryLine(
          _chad,
          "And now I walk away. Slowly. Do not look at me. I am walking away from a fire and it is the bravest thing "
          "I have done.",
        ),
        StoryLine(
          _maple,
          "You will be back in four minutes to check it.",
        ),
        StoryLine(_chad, "Five. I am working on five."),
      ]),
      StoryScene(StoryBackdrop.hearth, [_chad, _maple, _pip, _bertram, _biscuit], [
        StoryLine(
          _n,
          "That evening, in the long gold hush after the last of the bowls have been put away, somebody knocks at the "
          "front door.",
        ),
        StoryLine(
          _n,
          "It is a person with a very small bag and a very large expression of not knowing where to begin. They are "
          "standing in the doorway, with the dark behind them and the firelight in front.",
        ),
        StoryLine(
          _bertram,
          "Good evening! Is this the place one begins? That is what I asked, when I was eighty-three. I was told it "
          "was.",
        ),
        StoryLine(
          _pip,
          "It is. Come in. Mind the Duck Mat, everyone starts on the Duck Mat. I'll show you.",
        ),
        StoryLine(
          _maple,
          "There is soup, a chair and a kettle. In that order, or any order.",
        ),
        StoryChoice('pass', 'What do you hand them?', [
          StoryOption('A warm cup.', [
            StoryLine(
              _bertram,
              "A warm cup. It is a very small thing, and I would trade a great many large ones for it.",
            ),
          ]),
          StoryOption('Brun\'s little poker.', [
            StoryLine(
              _chad,
              "Oh! That is the one meant for the one just starting. It has a little flame on the handle. Do not poke "
              "the hearth with it, and everything will be fine.",
            ),
          ]),
          StoryOption('A chair by the fire.', [
            StoryLine(
              _maple,
              "A chair by the fire. It is always one of the best things you can offer, and it is free.",
            ),
          ]),
        ]),
        StoryLine(
          _n,
          "The newcomer sits. The hearth glows low and red and steady, as it has always meant to, and nobody leans in "
          "to feed it.",
        ),
        StoryLine(
          _chad,
          "Welcome to the Guild Hall of Steady Steps. Do not worry about a thing. I started at Level 1, like "
          "everyone.",
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Move however you like, rest when you need to, and always leave a thumb of "
          "air. The hall is yours.",
          only: StoryCondition('motivation', 0),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Have fun with it, the way you said you would, and bring somebody who is "
          "just starting. The hall is yours.",
          only: StoryCondition('motivation', 1),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Stay curious, the way you did from the very first day. There is always a "
          "new thing to keep. The hall is yours.",
          only: StoryCondition('motivation', 2),
        ),
        StoryLine(
          _n,
          "Far away a bell rings, a lamp winks, a chime sings and a table is laid. Under all of it, in a hall on a "
          "hill, a small red fire is kept, at its own pace, with a thumb of air, and one chair by the hearth for "
          "whoever comes next.",
        ),
      ]),
    ],
  ),
];
