/// Season Three, "The Weather Chime": a prologue and seven chapters that carry
/// the guild up the mountain pass to Thunder Heights. The same rules apply as in
/// the first two seasons (see docs/STORY.md and docs/CONTENT_GUIDELINES.md):
/// warm and funny, nothing timed, nothing that shames, and rest shown as an
/// ordinary part of the way. It is free for everyone, like the others.
///
/// Its theme is coming back: stopping is part of any path, and starting again
/// after a break is a smaller thing than it looks from the bottom of the stairs.
library;

import 'story.dart';

const _n = StorySpeaker.narrator;
const _chad = StorySpeaker.chad;
const _maple = StorySpeaker.maple;
const _biscuit = StorySpeaker.biscuit;
const _brad = StorySpeaker.brad;
const _grit = StorySpeaker.grit;
const _pip = StorySpeaker.pip;
const _fennel = StorySpeaker.fennel;
const _hush = StorySpeaker.hush;
const _tamsin = StorySpeaker.tamsin;
const _skarn = StorySpeaker.skarn;

const seasonThreeChapters = <StoryChapter>[
  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 3,
    number: 16,
    title: 'A Letter from Above',
    unlockLevel: 45,
    summary: 'The first post in two winters comes down from the mountains, and it is addressed to the guild.',
    scenes: [
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _pip, _biscuit], [
        StoryLine(
          _n,
          "Snow has been falling on the Guild Hall of Steady Steps for three days, which it has never done before. "
          "It sits on the windowsills like icing, and Biscuit has declared war on it.",
        ),
        StoryLine(
          _chad,
          "{hero}! Come in, shake off the snow. Not on the Duck Mat. Never on the Duck Mat.",
        ),
        StoryLine(
          _maple,
          "The door has been open since noon and everything is damp. I stopped counting puddles at nineteen.",
        ),
        StoryLine(
          _pip,
          "I have been mopping. The puddles are winning. I don't mind, though. It's nice, being busy because the hall is busy.",
        ),
        StoryLine(
          _n,
          "The door bangs. Somebody comes through it at a run, stops very suddenly, and slides the whole length of the "
          "hall on the wet floor, red scarf arriving a moment later.",
        ),
      ]),
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _pip, _fennel, _biscuit], [
        StoryLine(
          _fennel,
          "Post! Post for the Guild Hall! Is this the Guild Hall? It is. Sorry about the floor! I'm Fennel!",
        ),
        StoryLine(_pip, "Whoa. Are you all right?"),
        StoryLine(
          _fennel,
          "Fine! I only fall over at the end of a run. It keeps things tidy.",
        ),
        StoryLine(_maple, "There is now a Fennel-shaped puddle. Tidy is not the word."),
        StoryLine(
          _fennel,
          "I'm a courier from Thunder Heights, up beyond the pass. This is the first letter to make it down in two "
          "winters. I have been practising the speech all the way and now every word has left.",
        ),
        StoryLine(
          _n,
          "Fennel pulls a damp envelope from the satchel. It is sealed with a blob of blue wax in the shape of a very "
          "small bell.",
        ),
        StoryChoice('greet', 'What do you do for Fennel?', [
          StoryOption('Find a warm drink.', [
            StoryLine(
              _maple,
              "Tea. With honey. Sit. Not on the Duck Mat.",
            ),
            StoryLine(
              _fennel,
              "I don't think I've sat in a hall for two winters. It's very... flat. I like it.",
            ),
          ]),
          StoryOption('Ask them to catch a breath.', [
            StoryLine(
              _fennel,
              "Right. Breath. One... two... I've never done this on purpose before. It's actually quite good.",
            ),
            StoryLine(_pip, "It really is. I do it before I walk into a room."),
          ]),
          StoryOption('Read the letter together.', [
            StoryLine(
              _fennel,
              "Yes! Together! That's the best idea anyone has had since I arrived, and I arrived forty seconds ago.",
            ),
          ]),
        ]),
        StoryLine(
          _chad,
          "'To the Guild Hall that rang the Dawn Bell, and to the light that answered it.' Oh, that's lovely. Somebody up "
          "there has been listening.",
        ),
        StoryLine(
          _chad,
          "{hero} lit the great lamp with one careful spark, and it carried all the way up a mountain. Good sparks do that.",
          only: StoryCondition('light', 0),
        ),
        StoryLine(
          _chad,
          "We lit that lamp together, in a heap, with nobody doing it tidily. It must have been very bright.",
          only: StoryCondition('light', 1),
        ),
        StoryLine(
          _pip,
          "They saw the lamp I lit. From a mountain! I'm going to need to lie down for a bit. Then tell everyone.",
          only: StoryCondition('light', 2),
        ),
        StoryLine(
          _chad,
          "'The Weather Chime, which sings the day's weather down to the high farms, has not sounded in two winters. The "
          "storms have been loud ever since. We do not ask for rescue. The kettle is on, and there is a great deal of stair.'",
        ),
        StoryLine(
          _maple,
          "The pass is shut in winter for a reason, Chad. Nothing here has a deadline. We pack properly and go slowly.",
        ),
        StoryLine(
          _chad,
          "Slowly! Yes! The one thing a mountain can't do is hurry us. I will pack the cape.",
        ),
        StoryLine(_maple, "You will pack the second pair of socks."),
        StoryLine(_chad, "...I will pack the second pair of socks."),
        StoryLine(
          _n,
          "By evening the hall smells of wet wool and plans, and the road north is as white as a clean page.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 3,
    number: 17,
    title: 'The Foot of the Pass',
    unlockLevel: 47,
    summary: 'A courier who only knows one speed, a rival with two flags, and a climb that can be taken any way you like.',
    scenes: [
      StoryScene(StoryBackdrop.snowRoad, [_fennel, _pip, _brad, _chad], [
        StoryLine(
          _n,
          "The road north climbs in long, wide zigzags between pines wearing snow like very large hats.",
        ),
        StoryLine(
          _fennel,
          "Right! Shortcut! If we go straight up the gully we skip four bends, and... hold on. Where did the gully go?",
        ),
        StoryLine(_pip, "It's behind you. You walked past it."),
        StoryLine(
          _fennel,
          "I walk past things at speed. It's a talent. It has never once been useful.",
        ),
        StoryLine(
          _brad,
          "{hero}! I heard there was a mountain! I have brought a rope, two flasks, a flag, and a second flag in case the "
          "first one gets lonely.",
        ),
        StoryLine(_chad, "Brad, there is nobody to plant the flag on yet."),
        StoryLine(
          _brad,
          "I like to be ready. I also rested before we left. I'm very good at it now. Ask anyone.",
        ),
        StoryLine(_chad, "He is. It's annoying."),
        StoryLine(
          _fennel,
          "Serious question. How do you all go up a hill? Because I've only got one speed and it's 'fast, then fall over'.",
        ),
        StoryChoice('climb', 'How do you climb?', [
          StoryOption('Steady, a step at a time.', [
            StoryLine(
              _n,
              "You settle into a rhythm: a step, a breath, a step. The hill, which was expecting an argument, seems "
              "almost pleased.",
            ),
            StoryLine(_brad, "A rhythm! I have one of those. Mine is mostly humming."),
          ]),
          StoryOption('A burst, then a breather.', [
            StoryLine(
              _n,
              "You climb in bursts and stop at every bend to look back. By the third bend the whole valley lies below like a map.",
            ),
            StoryLine(
              _fennel,
              "That's... basically how I run. But I thought bursts didn't count.",
            ),
            StoryLine(_pip, "They count. Bursts count."),
          ]),
          StoryOption('Whatever the hill says.', [
            StoryLine(
              _n,
              "Steep bit, short steps. Flat bit, a stretch of the legs. You let the hill choose, and the hill turns out to "
              "be a very reasonable guide.",
            ),
            StoryLine(_chad, "I've always said mountains give excellent advice. It's their only job."),
          ]),
        ]),
      ]),
      StoryScene(StoryBackdrop.snowRoad, [_pip, _fennel, _chad, _brad], [
        StoryLine(
          _n,
          "Halfway up the second slope, Fennel's pace drops to something nearly human. Pip falls into step beside them.",
        ),
        StoryLine(
          _pip,
          "Someone told me once that the wall counts. Even if all you do is get to the wall. I think about it a lot.",
          only: StoryCondition('pip', 0),
        ),
        StoryLine(
          _pip,
          "Someone told me once to rest at every landing. I still do. Nobody has ever been annoyed. Not once.",
          only: StoryCondition('pip', 1),
        ),
        StoryLine(
          _pip,
          "Someone once climbed a hundred and eighty-two steps right beside me, so I know what that's worth. We'll "
          "go beside you, Fennel.",
          only: StoryCondition('pip', 2),
        ),
        StoryLine(
          _fennel,
          "I've never been looked after on a hill. I'm usually dropping the post and gone before the kettle boils.",
        ),
        StoryLine(
          _brad,
          "Go at your own pace, Fennel. The mountain isn't timing anybody. I checked. It has no watch.",
        ),
        StoryLine(
          _chad,
          "First rule of hills: everybody takes them differently, and they all arrive at the top. Eventually. Mostly with "
          "snacks.",
        ),
        StoryLine(
          _n,
          "Pip, who a season ago clutched a mat like a shield, takes the lead where the road narrows. They know exactly "
          "where the next bend is, and they wait for everyone at it.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 3,
    number: 18,
    title: 'Soup at the Snow Line',
    unlockLevel: 50,
    summary: 'A hut with one rule, a very large host, and a pot of soup that has been waiting for two winters.',
    scenes: [
      StoryScene(StoryBackdrop.snowRoad, [_fennel, _pip, _brad, _chad, _hush], [
        StoryLine(
          _n,
          "Past noon the sky turns the colour of a pewter plate and the wind finds its voice. Then, round a bend, a small "
          "stone hut with a smoking chimney and a very large sign: STOP HERE. THIS MEANS YOU.",
        ),
        StoryLine(
          _fennel,
          "I've never stopped here. I always run straight past. I thought it was for... emergencies.",
        ),
        StoryLine(_chad, "'This means you.' I do love a sign with confidence."),
        StoryLine(_brad, "I would like to stop. I'm excellent at it."),
        StoryLine(
          _pip,
          "It isn't us giving up. It's the sign telling us it's allowed.",
        ),
        StoryLine(
          _n,
          "The door opens before anyone can knock. Warm light spills over the snow, along with a smell of barley and "
          "woodsmoke, and a very deep, very soft voice.",
        ),
        StoryLine(_hush, "Come in. Mind your heads. Mind mine, mostly."),
      ]),
      StoryScene(StoryBackdrop.passHut, [_hush, _fennel, _pip, _chad, _brad], [
        StoryLine(
          _hush,
          "I am Hush. I keep the hut. There is soup. There is always soup. It is my whole job, and I am very good at it.",
        ),
        StoryLine(_chad, "A legendary profession. I've always said so."),
        StoryLine(
          _fennel,
          "You've been here the whole time? Two winters? I've run past this hut more times than I can count!",
        ),
        StoryLine(
          _hush,
          "I saw you. A scarf, going by. Every time, I put a mug on the step. You never saw.",
        ),
        StoryLine(
          _fennel,
          "The mugs! I thought the wind had left them! I've been stepping over mugs! For two winters!",
        ),
        StoryLine(
          _hush,
          "It is all right. The mugs kept. Some people need a long time before they are ready to stop. I keep the stove "
          "warm for all of them.",
        ),
        StoryLine(_pip, "That is the nicest thing I've ever heard anyone say."),
        StoryLine(
          _hush,
          "On a mountain, every path has a hut. Not because anyone is slow. A path with nowhere to sit is not really a "
          "path. It is only a hurry.",
        ),
        StoryLine(_chad, "Rest is training, Hush. It's on a banner."),
        StoryLine(_hush, "I know. Wren sent it over on a seagull. It is above the stove."),
        StoryChoice('soup', 'What soup do you ask for?', [
          StoryOption('Barley and root vegetables.', [
            StoryLine(
              _hush,
              "A sturdy choice. A soup that tells you it will still be here tomorrow.",
            ),
          ]),
          StoryOption('Mushroom, with pepper.', [
            StoryLine(
              _hush,
              "Pepper! A person with ideas. Sit by the stove. The good chair is the one with the dent.",
            ),
          ]),
          StoryOption('Whatever Hush thinks I need.', [
            StoryLine(
              _hush,
              "Oh. Nobody ever lets me choose. ...Mushroom and barley, with a little honey. It is what I make when someone "
              "looks like they have come a long way.",
            ),
          ]),
        ]),
        StoryLine(
          _chad,
          "I once climbed a whole mountain in a single morning, and I'd like to tell you all about—",
        ),
        StoryLine(_hush, "Sit down, Chad."),
        StoryLine(_chad, "...Sitting down."),
        StoryLine(
          _hush,
          "You will meet my cousins on the road, further up. They are shy, and announce it with their fists. They mean "
          "it kindly. Take a scarf.",
        ),
        StoryLine(
          _n,
          "The scarf is enormous, striped, and smells of woodsmoke. Outside the wind howls and the snow comes down, and "
          "inside there is soup, and no one is going anywhere for a little while.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 3,
    number: 19,
    title: 'The Echo in the Ice',
    unlockLevel: 54,
    summary: 'A cave of blue ice gives back whatever is said to it, only a little slower, and a lot kinder.',
    scenes: [
      StoryScene(StoryBackdrop.iceCave, [_grit, _pip, _fennel, _brad], [
        StoryLine(
          _n,
          "The road narrows to a cut in the ice, and the cut becomes a cave. Everything is blue. The pillars shine. Even "
          "the sound seems blue.",
        ),
        StoryLine(
          _n,
          "Something small and green pops out from behind an icicle with a large sack.",
        ),
        StoryLine(
          _grit,
          "BUTTONS! There are buttons in the walls! Thousands! ...Oh. They're crystals. They're still wonderful!",
        ),
        StoryLine(
          _grit,
          "I heard there was a mountain and I thought, a mountain must have the best shiny things. I've been here three "
          "days. I have never been so happy.",
        ),
        StoryLine(_fennel, "Echo test! Hello!"),
        StoryLine(_n, "'...hello,' says the cave, a moment later, a little softer."),
        StoryLine(_brad, "I AM BRAD!"),
        StoryLine(
          _n,
          "'...am Brad,' says the cave, gently, as though pleased to meet him.",
        ),
        StoryLine(
          _grit,
          "It says things back! It says them back NICELY!",
        ),
      ]),
      StoryScene(StoryBackdrop.iceCave, [_pip, _fennel, _grit, _brad], [
        StoryLine(
          _pip,
          "I read that ice caves do this. They give your voice back a bit slower, so you have time to hear it.",
        ),
        StoryLine(
          _fennel,
          "I'm... not very good at slow. And I don't say much out loud. I'm usually gone before anyone asks.",
        ),
        StoryLine(_pip, "Try something you don't usually say. Or just say hello. It's allowed."),
        StoryChoice('echo', 'What do you say to the cave?', [
          StoryOption("I'm doing my best.", [
            StoryLine(
              _n,
              "'...doing my best,' the cave says, slowly, and once more, quieter: 'my best.' It sounds like something worth "
              "hearing twice.",
            ),
          ]),
          StoryOption('That was a good climb.', [
            StoryLine(
              _n,
              "'...a good climb,' the cave agrees. For a moment nobody says anything at all. It was.",
            ),
          ]),
          StoryOption('Hello, cave!', [
            StoryLine(_n, "'Hello, cave,' says the cave."),
            StoryLine(_grit, "It said hello back! We're friends! I'm going to name a crystal after it!"),
          ]),
        ]),
        StoryLine(
          _fennel,
          "Okay. My turn. I always run so nobody asks if I'm all right. ...I'm doing my best.",
        ),
        StoryLine(_n, "'...doing my best,' says the cave."),
        StoryLine(
          _fennel,
          "It sounded nicer coming back. Why does it sound nicer coming back?",
        ),
        StoryLine(
          _pip,
          "That's the cave's trick. It only repeats what you give it. It just says it slowly enough to believe.",
        ),
        StoryLine(
          _brad,
          "I'd like it noted that I said 'I am Brad' and the cave agreed with me.",
        ),
        StoryLine(
          _grit,
          "Here. I found you a shiny. It is a button. It was always going to be a button.",
        ),
        StoryLine(
          _n,
          "They leave the cave with their pockets full of blue light, and Fennel walks out, actually walks, hands in "
          "pockets, looking at the ceiling.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 3,
    number: 20,
    title: "The Weatherkeeper's Stair",
    unlockLevel: 58,
    summary: 'At the top of the pass, a tall tower and a long stair, and someone sitting at the bottom of it.',
    scenes: [
      StoryScene(StoryBackdrop.observatory, [_tamsin, _chad, _pip, _fennel], [
        StoryLine(
          _n,
          "At the head of the pass the road ends at a stone tower. A great many stairs wind around it like ribbon. At the "
          "bottom, on a folding chair, a woman in a long blue coat is drinking from a thermos and looking up.",
        ),
        StoryLine(
          _tamsin,
          "You'll be the guild. I heard the bell. Both times. Welcome to the foot of my stair. I'd say come up, but I'm "
          "told that's rude.",
        ),
        StoryLine(
          _fennel,
          "Tamsin! I got the letter down! It took two winters and a very wet hall!",
        ),
        StoryLine(_tamsin, "Fennel. You stopped, didn't you? For soup. I'm so proud I've gone quiet."),
        StoryLine(
          _chad,
          "Madam Weatherkeeper! Your tower! Your Chime! Your... chair?",
        ),
        StoryLine(
          _tamsin,
          "Four hundred and twelve steps. I used to take them two at a time with a kettle. Then one hard winter I came "
          "down, and I haven't gone up since.",
        ),
        StoryLine(
          _tamsin,
          "It isn't that I can't. It's that I stopped, and every day I didn't climb, the stair got a little taller.",
        ),
        StoryLine(
          _pip,
          "I know that stair. For me it was a wall. Every day I didn't try, it got higher. Then somebody said the wall counts.",
        ),
        StoryChoice('stair', 'What do you say to Tamsin?', [
          StoryOption('Let me sit with you a while.', [
            StoryLine(
              _tamsin,
              "Ah. Sitting. I am excellent at that. It's the one thing I definitely haven't forgotten.",
            ),
            StoryLine(
              _n,
              "You pull up a rock beside her. For a while nobody needs to say anything, and the wind goes round the tower "
              "like a cat.",
            ),
          ]),
          StoryOption('Shall we try one step?', [
            StoryLine(
              _tamsin,
              "One step. That's a suspiciously small number.",
            ),
            StoryLine(_pip, "It's a number you can do. That's what makes it a good one."),
          ]),
          StoryOption('Tell me about the view.', [
            StoryLine(
              _tamsin,
              "The view! Oh, the view. On a clear night you can see a lamp on a far headland, and a bell on a green hill, "
              "and a little smoke from a hut.",
            ),
            StoryLine(_tamsin, "I haven't seen it from the top in a long while. I think I've missed it more than the stair."),
          ]),
        ]),
      ]),
      StoryScene(StoryBackdrop.observatory, [_tamsin, _chad, _pip, _fennel], [
        StoryLine(
          _n,
          "Tamsin folds up the chair, and puts down the thermos, and puts one boot on the bottom step. It is a small step. "
          "She looks at it as though it were the biggest thing on the mountain.",
        ),
        StoryLine(_tamsin, "One."),
        StoryLine(_chad, "Is that all?"),
        StoryLine(_pip, "One counts."),
        StoryLine(
          _tamsin,
          "My teacher used to say it. 'Rest is training.' I'd run up the stair out of embarrassment, just to prove him wrong.",
        ),
        StoryLine(_chad, "He was right. It's on a banner."),
        StoryLine(
          _fennel,
          "Take the landings. Take all of them. I'll sit with you at every one. I'm getting good at it.",
        ),
        StoryLine(
          _n,
          "At the first landing, twelve steps up, Tamsin sits down on the cold stone with a long breath, and Fennel sits "
          "down beside her, and nobody runs anywhere.",
        ),
        StoryLine(
          _tamsin,
          "The second landing tomorrow. Or the day after. The Chime has waited two winters. Nothing here has a deadline.",
        ),
        StoryLine(
          _n,
          "Below them lie the pass, the road, and the thin grey line of Hush's smoke. Tamsin looks at all of it for a "
          "long time.",
        ),
        StoryLine(
          _tamsin,
          "Funny. From here it looks so much shorter. It was always this short. I just wasn't standing on it.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 3,
    number: 21,
    title: 'A Very Small Storm',
    unlockLevel: 62,
    summary: 'At the top of the heights, a very small wizard is doing his best with a very large storm.',
    scenes: [
      StoryScene(StoryBackdrop.stormTop, [_chad, _pip, _fennel, _tamsin, _skarn], [
        StoryLine(
          _n,
          "It takes many days to climb the stair, with a landing for every sit and a sit for every landing. Nobody counts "
          "the days. Tamsin counts the steps, under her breath, and on the last one she says a word that is in no guidebook.",
        ),
        StoryLine(
          _n,
          "At the top the wind is loud and the clouds are low. In the middle of the platform hangs a great iron ring of "
          "seven bells, perfectly silent. Beneath it sits a very small person under a very large thundercloud.",
        ),
        StoryLine(_skarn, "Go away! ...Please. Sorry. Go away, please."),
        StoryLine(_pip, "Are you... making the storm?"),
        StoryLine(
          _skarn,
          "I'm not MAKING it. It just comes out when I'm upset. Which is always, now.",
        ),
        StoryLine(_tamsin, "Skarn. Little Skarn."),
        StoryLine(
          _skarn,
          "Tamsin?! You came UP?! I didn't mean it! I rang one wrong note, and then you stopped coming, and I thought if "
          "I made it loud enough you'd hear it from down there and—",
        ),
        StoryLine(
          _tamsin,
          "Oh, love. You didn't make me stop. I made me stop. It had nothing to do with you.",
        ),
        StoryLine(
          _chad,
          "I have a speech about storms. It's very moving. It has a goose in it.",
        ),
        StoryLine(_skarn, "Please no."),
        StoryLine(_chad, "...Fair."),
        StoryChoice('storm', 'What do you say to Skarn?', [
          StoryOption('It was never your fault.', [
            StoryLine(
              _skarn,
              "Everybody says that. ...But you said it like it was true. Nobody says it like it's true.",
            ),
          ]),
          StoryOption('Would you like a hot drink?', [
            StoryLine(
              _skarn,
              "I'd like that very much. I haven't had one in a long time. I forgot you could just ask.",
            ),
            StoryLine(_fennel, "I have Hush's flask. It's been waiting for someone to need it."),
          ]),
          StoryOption('Show us the Chime.', [
            StoryLine(
              _skarn,
              "Really? You want to see it? I didn't think anyone... Okay. Okay! It's very beautiful, if you're not scared of it.",
            ),
          ]),
        ]),
      ]),
      StoryScene(StoryBackdrop.stormTop, [_chad, _pip, _fennel, _tamsin, _skarn], [
        StoryLine(
          _tamsin,
          "The Chime is rung by two. One for the low bells, one for the high. Skarn took the high ones. He always had "
          "the better ear.",
        ),
        StoryLine(
          _skarn,
          "And then I thought, if I ring them alone it'll be wrong again. And the weather comes out as whatever I'm "
          "feeling. And I'm feeling... rather a lot.",
        ),
        StoryLine(
          _tamsin,
          "Then we'll ring them together. But not tonight, love. Tonight we eat something and go to sleep.",
        ),
        StoryLine(
          _skarn,
          "It doesn't have to be tonight? You promise? The Chime isn't cross?",
        ),
        StoryLine(
          _tamsin,
          "Bells are never cross. They are only waiting. They're extremely good at it.",
        ),
        StoryLine(
          _n,
          "The storm does not go away. But something in it softens, the way a loud voice does when someone finally asks "
          "it what's wrong. The thunder rolls over to one side and sits down.",
        ),
        StoryLine(
          _pip,
          "Can we put a roof on that cloud? Just so it's cosy?",
        ),
        StoryLine(
          _skarn,
          "...You can try. It's quite shy.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 3,
    number: 22,
    title: 'The Night Before the Chime',
    unlockLevel: 66,
    summary: 'Above the clouds, around a small fire, everyone says what they have come back with.',
    scenes: [
      StoryScene(StoryBackdrop.highCamp, [_tamsin, _skarn, _chad, _brad, _pip], [
        StoryLine(
          _n,
          "That night the clouds lie far below like a second ground, silver in the moonlight. A green light ripples "
          "across the sky. In the middle of the platform burns one small, determined fire.",
        ),
        StoryLine(
          _chad,
          "I'll tell you a thing I've never told. One winter I did nothing. Absolutely nothing. By spring I was certain I "
          "would have to start again from the very bottom.",
        ),
        StoryLine(_brad, "I remember. You had a cold. You told everyone it was a quest."),
        StoryLine(
          _chad,
          "Do you know what I did on my first day back? Two push-ups. ...They were the best two push-ups of my life.",
        ),
        StoryLine(_brad, "I counted three."),
        StoryLine(_chad, "You counted two. You're very supportive."),
        StoryLine(
          _tamsin,
          "I used to think coming back was starting over. It isn't. It's picking up where the stair has been waiting for you.",
        ),
        StoryLine(
          _skarn,
          "What if I ring it wrong tomorrow? What if it's a terrible afternoon?",
        ),
        StoryLine(
          _tamsin,
          "Then the weather will be silly for an afternoon, and we'll try again. That's the whole secret of bells.",
        ),
        StoryChoice('camp', 'What do you share by the fire?', [
          StoryOption('Something I am proud of.', [
            StoryLine(
              _tamsin,
              "Good. Say it out loud. Things you are proud of should be said out loud at least once.",
            ),
            StoryLine(_pip, "I'm proud of you for saying it. That counts for two."),
          ]),
          StoryOption('Something I am still learning.', [
            StoryLine(
              _skarn,
              "Me too. I'm learning how to ring a bell without it being the end of the world.",
            ),
            StoryLine(_chad, "A hard one. I'm still learning to sit through a soup without a speech."),
          ]),
          StoryOption('Nothing, just the fire.', [
            StoryLine(
              _tamsin,
              "That's a perfectly good thing to share. Fires are good at that. They never ask for more.",
            ),
          ]),
        ]),
      ]),
      StoryScene(StoryBackdrop.highCamp, [_fennel, _pip, _chad, _skarn, _brad], [
        StoryLine(
          _fennel,
          "I used to think delivering things fast was the only way to matter. I stopped, Pip. Three times this week. "
          "And somehow I've delivered more than I ever did.",
        ),
        StoryLine(
          _pip,
          "I used to think everyone knew exactly what they were doing. Then somebody told me they'd just been doing it "
          "longer.",
        ),
        StoryLine(
          _chad,
          "That's the first rule of the hall. It's on the board, next to the one about the kettle.",
        ),
        StoryLine(
          _brad,
          "I counted the stars. Eleven. Twelve, if you count the one I'm sure about.",
        ),
        StoryLine(
          _n,
          "Far below the cloud sea, tiny lights prick through: a lamp on a far headland, a bell tower on a green hill, a "
          "little glow where a stove burns in a hut.",
        ),
        StoryLine(
          _skarn,
          "I never saw them from up here. I was looking down at my feet so hard.",
        ),
        StoryLine(
          _n,
          "Skarn falls asleep sitting up. His little cloud has stopped thundering. It is snoring. It lets fall one "
          "snowflake at a time.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 3,
    number: 23,
    title: 'The Weather Chime',
    unlockLevel: 70,
    summary: 'The seven bells are rung, the storm settles, and three lights and three sounds answer each other.',
    scenes: [
      StoryScene(StoryBackdrop.summit, [_tamsin, _skarn, _pip, _fennel, _brad], [
        StoryLine(
          _n,
          "Morning comes up gold over a sea of cloud, and the seven bells hang waiting. The wind is hardly there at all.",
        ),
        StoryLine(_skarn, "I'm going to be sick. In a weather way. There might be hail."),
        StoryLine(_tamsin, "There might. If there is, we'll all stand under the Chime and wait for it to pass."),
        StoryLine(_brad, "I brought an umbrella. And a second umbrella."),
        StoryLine(_pip, "In case the first one gets lonely?"),
        StoryLine(_brad, "I'm learning from you, Pip."),
        StoryChoice('chime', 'How do you start the Chime?', [
          StoryOption('Tamsin leads, Skarn follows.', [
            StoryLine(
              _tamsin,
              "Low bells first, then. Skarn, you'll hear where you come in. You always did.",
            ),
          ]),
          StoryOption('Skarn leads, Tamsin follows.', [
            StoryLine(
              _skarn,
              "Me? First? ...Okay. Okay. I know the first note. I've known it all along.",
            ),
          ]),
          StoryOption('All of you, together.', [
            StoryLine(
              _tamsin,
              "Together, then. It's how it was always meant to be, I think. We just forgot to ask.",
            ),
          ]),
        ]),
        StoryLine(
          _n,
          "The first bell sounds, low and warm. Then the second, and the third. The high bells answer, clear as spring "
          "water. Seven notes, and each one a different weather: sun, breeze, rain, snow, fog, thunder, and the quiet "
          "that comes after.",
        ),
        StoryLine(
          _n,
          "The thundercloud over Skarn's head lets go of a long breath and comes apart like a dandelion. Light pours "
          "across the cloud sea.",
        ),
        StoryLine(_skarn, "It's... right. It's actually right."),
      ]),
      StoryScene(StoryBackdrop.summit, [_chad, _tamsin, _skarn, _fennel, _biscuit], [
        StoryLine(
          _n,
          "From out of the clouds, trotting briskly in a knitted coat three sizes too big, comes Biscuit. Nobody asks "
          "how. He seems to feel it is obvious.",
        ),
        StoryLine(
          _fennel,
          "He arrived at the pass post. Addressed to Chad. Stamped 'Fragile, Excellent.'",
        ),
        StoryLine(_biscuit, "*Woof!*"),
        StoryLine(
          _chad,
          "He says it's a fine mountain. I can't say I disagree with him.",
        ),
        StoryLine(
          _n,
          "Then, far below and to the east, a deep, warm note rolls up through the clouds: BONG. The Dawn Bell, answering.",
        ),
        StoryLine(
          _n,
          "And far to the west, on a headland too distant to see, something bright winks once in the morning light, the "
          "way a lamp does when it's saying hello.",
        ),
        StoryLine(
          _tamsin,
          "A bell for morning, a lamp for night, and a Chime for all the weather in between. We've waited a long time to be "
          "part of that.",
        ),
        StoryLine(
          _chad,
          "Skarn! The hall has room for a weather-wizard. The kettle's on, the Duck Mat is free, and Maple makes a "
          "terrifying scone.",
        ),
        StoryLine(
          _skarn,
          "Can I come? Sometimes? I don't think I can leave the Chime. ...Can the Chime come?",
        ),
        StoryLine(
          _tamsin,
          "You'll come down every spring, love, and I'll come down in autumn. By stages. Stopping at all the landings. "
          "I intend to take as long as it takes.",
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Move however you like, rest when you need to, and bring the weather if you "
          "can't help it. The hall is yours.",
          only: StoryCondition('motivation', 0),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Have fun with it, the way you said you would. Bring a snowball. The hall is yours.",
          only: StoryCondition('motivation', 1),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Stay curious, the way you did from the very first day. There is always another "
          "path to wonder at. The hall is yours.",
          only: StoryCondition('motivation', 2),
        ),
        StoryLine(
          _n,
          "The Chime sings, the bell answers, and the lamp winks. Between them lie a hundred places to sit down, and "
          "everyone, at their own pace, is on the way to one of them.",
        ),
      ]),
    ],
  ),
];
