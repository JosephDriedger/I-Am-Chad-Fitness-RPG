/// Season Two, "The Lantern Coast": a prologue and seven chapters that pick up
/// the lantern glowing in the west at the end of "The Dawn Bell". The same rules
/// apply as in Season One (see docs/STORY.md and docs/CONTENT_GUIDELINES.md):
/// warm and funny, nothing timed, nothing that shames, and rest shown as an
/// ordinary part of the work. It is free for everyone, like Season One.
library;

import 'package:i_am_chad/domain/story.dart';

const _n = StorySpeaker.narrator;
const _chad = StorySpeaker.chad;
const _maple = StorySpeaker.maple;
const _biscuit = StorySpeaker.biscuit;
const _brad = StorySpeaker.brad;
const _grit = StorySpeaker.grit;
const _murmur = StorySpeaker.murmur;
const _pip = StorySpeaker.pip;
const _wren = StorySpeaker.wren;
const _sedge = StorySpeaker.sedge;

const seasonTwoChapters = <StoryChapter>[
  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 2,
    number: 8,
    title: 'A Hall Full of Strangers',
    unlockLevel: 18,
    summary: 'The hall is busier than ever, a newcomer called Pip needs a friend, and a light is calling from the west.',
    scenes: [
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _biscuit], [
        StoryLine(
          _n,
          "Since the Dawn Bell rang, the Guild Hall of Steady Steps has never been quiet. There is a queue for the "
          "stretching mats, a waiting list for the good kettle, and a sign in Maple's handwriting: PLEASE TAKE TURNS.",
        ),
        StoryLine(
          _chad,
          "{hero}! Come in, come in, mind the queue! I have been a guildmaster for years and I have never once had to say "
          "'mind the queue'. I love it.",
        ),
        StoryLine(_maple, "He has said it forty times today. It has not worked once."),
        StoryLine(
          _chad,
          "Everyone came because of the bell. Some walked from the coast! Maple, tell {hero} about the coast.",
        ),
        StoryLine(
          _maple,
          "Hm. Fishing boats have been turning up since Tuesday. They say the harbour at Gullhaven is stuck. Fog on "
          "the water, and the lighthouse lamp has gone dark.",
        ),
        StoryLine(
          _maple,
          "All except one small lantern in the window. Somebody lights it every single night. Nobody knows who.",
        ),
        StoryLine(
          _chad,
          "The lantern from the end of last time! I have been wondering about it for weeks. I made a chart. It is "
          "mostly question marks.",
        ),
        StoryLine(_biscuit, "*Woof!*"),
        StoryLine(
          _chad,
          "He says it is a good lantern. He has never seen it. He is a very trusting dog.",
        ),
      ]),
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _pip, _biscuit], [
        StoryLine(
          _n,
          "Somebody small is standing very still beside the notice board, holding a rolled-up mat in front of them "
          "like a shield.",
        ),
        StoryLine(
          _chad,
          "Ah, a newcomer! Step forward. Do not be alarmed, I only bite on Tuesdays.",
        ),
        StoryLine(_maple, "He does not bite."),
        StoryLine(_chad, "I am working on a reputation."),
        StoryLine(
          _pip,
          "Hi. I'm Pip. I heard the bell, and I thought maybe I could try. But everyone here looks like they know "
          "exactly what they're doing.",
        ),
        StoryLine(
          _maple,
          "Nobody knows exactly what they are doing. They have just been doing it for longer.",
        ),
        StoryLine(
          _chad,
          "{hero}! You were new here yourself not so long ago. Would you show Pip around?",
        ),
        StoryLine(
          _n,
          "Pip looks at you hopefully, then at the mat, then at the floor.",
        ),
        StoryChoice('welcome', 'How do you welcome Pip?', [
          StoryOption('Show Pip around the hall.', [
            StoryLine(
              _pip,
              "Oh! There is a kettle? And a mat with a duck on it?",
            ),
            StoryLine(
              _chad,
              "The Duck Mat. Nobody knows why it has a duck. It is the best mat we own.",
            ),
          ]),
          StoryOption('Share a snack and a seat.', [
            StoryLine(
              _pip,
              "Thanks. I was not sure if I was allowed to sit down yet.",
            ),
            StoryLine(
              _maple,
              "You are allowed to sit down. Sitting down is in the rules. I wrote that rule.",
            ),
          ]),
          StoryOption('Tell Pip you started small too.', [
            StoryLine(_pip, "Really? You? ...Oh. That helps. That helps a lot."),
            StoryLine(
              _chad,
              "I did not start small! I started at Level 2. ...I started at Level 1, like everyone. Please carry on.",
            ),
          ]),
        ]),
        StoryLine(
          _chad,
          "Right! Pip, you are on the guild's books. That means you may take as long as you like, rest whenever you "
          "like, and nothing here has a deadline. Rest is training. I will keep saying so until somebody stops me.",
        ),
        StoryLine(_pip, "Okay. Okay. I think I can do that."),
      ]),
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _pip, _biscuit], [
        StoryLine(
          _maple,
          "The coast road is long. Somebody should go and see what is wrong with that lighthouse.",
        ),
        StoryLine(
          _chad,
          "And I would love to go, but a guildmaster cannot abandon his hall. Also my knees have filed a formal "
          "complaint.",
        ),
        StoryLine(
          _chad,
          "{hero}, would you go? At your own pace, with Biscuit and a bag of Maple's sandwiches?",
        ),
        StoryLine(_pip, "Can I come too? I am not very fast."),
        StoryLine(
          _chad,
          "Fast is something that happens to some people. Arriving is something that happens to everyone.",
        ),
        StoryLine(
          _n,
          "And so the Chronicle turns to a new page, and a road that leads west toward the sea.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 2,
    number: 9,
    title: 'The Road West',
    unlockLevel: 20,
    summary: 'A signpost with eleven arrows, a rival with a lot of energy, and a lesson about which way is behind.',
    scenes: [
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _pip, _biscuit], [
        StoryLine(
          _maple,
          "One flask. Two sandwiches each. A spare sock, because there is always a spare sock. And a map.",
        ),
        StoryLine(
          _chad,
          "I drew the map myself. It is mostly arrows. They are very confident arrows.",
        ),
        StoryLine(_maple, "Hm. They point in three directions."),
        StoryLine(
          _chad,
          "Confident in three directions! Go well, you two. If the road is long, sit down. If the road is lovely, "
          "sit down anyway.",
        ),
      ]),
      StoryScene(StoryBackdrop.coastRoad, [_brad, _pip, _biscuit], [
        StoryLine(
          _brad,
          "{hero}! Pip! I am your escort! I have scouted ahead. To that tree. And back. And to that tree again. The "
          "road is four hundred tree-lengths long.",
        ),
        StoryLine(
          _brad,
          "I have taken your advice, {hero}. I now rest on purpose. It is going very well. I have a schedule for it.",
          only: StoryCondition('brad', 0),
        ),
        StoryLine(
          _brad,
          "Remember when you asked to join my rest? I kept your spot. I labelled it. It says RESERVED.",
          only: StoryCondition('brad', 1),
        ),
        StoryLine(
          _brad,
          "You said my secret was safe, {hero}, and it has been. Nobody knows about my naps. Pip, do not ask about my naps.",
          only: StoryCondition('brad', 2),
        ),
        StoryLine(_pip, "I did not ask."),
        StoryLine(_brad, "Good. Keep not asking."),
        StoryLine(
          _n,
          "A signpost stands at a fork in the road. It has eleven arrows. Ten of them say GULLHAVEN, and one says "
          "SORRY.",
        ),
        StoryLine(
          _pip,
          "I keep falling behind you both. I am sorry. You can go on ahead, honestly.",
        ),
        StoryLine(
          _brad,
          "Behind is a direction, Pip. It is not a verdict. I read that on a bookmark.",
        ),
        StoryChoice('pace', 'How do you walk the road?', [
          StoryOption("At Pip's pace.", [
            StoryLine(
              _pip,
              "...You do not mind? Oh. Then I will look at the view. I have not looked at a single view yet.",
            ),
          ]),
          StoryOption('A little ahead, then wait.', [
            StoryLine(
              _brad,
              "I do this already! I call it a lap! Pip, you are my favourite finish line.",
            ),
          ]),
          StoryOption('Side by side.', [
            StoryLine(
              _pip,
              "Side by side. Nobody in front and nobody behind. I did not know that was an option.",
            ),
          ]),
        ]),
        StoryLine(
          _n,
          "Biscuit trots in loops around all three of them, which is, strictly speaking, a different pace again. "
          "Everybody allows it.",
        ),
      ]),
      StoryScene(StoryBackdrop.coastRoad, [_brad, _pip, _biscuit], [
        StoryLine(
          _n,
          "The road tops a rise, and the whole sea opens out below: wide, bright and rocking gently, as if it has "
          "all the time in the world.",
        ),
        StoryLine(
          _pip,
          "Oh. It is so big. And look, way over there on the cliff. Is that the lighthouse? It is so small.",
        ),
        StoryLine(
          _brad,
          "It is far. It is a bit farther than it looks. Everything worth reaching is. I read that too.",
        ),
        StoryLine(
          _n,
          "A tiny golden spark flickers in the tower, small and stubborn against the afternoon. Somebody is up there. "
          "Somebody is keeping it lit.",
        ),
        StoryLine(_pip, "I think I want to meet whoever that is."),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 2,
    number: 10,
    title: 'The Slowest Ferry in the World',
    unlockLevel: 23,
    summary: 'The river between the road and the coast has a ferry, and the ferry has a tortoise.',
    scenes: [
      StoryScene(StoryBackdrop.estuary, [_sedge, _brad, _pip, _biscuit], [
        StoryLine(
          _n,
          "The road ends at a wide, golden river mouth. There is a wooden jetty, a flat-bottomed ferry, and a sign "
          "that says: FERRY. LEAVES WHEN IT LEAVES.",
        ),
        StoryLine(
          _n,
          "On the ferry sits a very old tortoise in a small red cap. He does not look up. He does not need to.",
        ),
        StoryLine(
          _brad,
          "Excellent! A ferry! When does it leave? I have been ready since the signpost.",
        ),
        StoryLine(_sedge, "...Hello."),
        StoryLine(_brad, "Hello! When does it leave?"),
        StoryLine(_sedge, "...When it leaves."),
        StoryLine(
          _pip,
          "I like him already. He has not asked me to hurry once, and he has said four words.",
        ),
        StoryLine(
          _sedge,
          "Sedge. Ferry. ...Three hundred years. Never been late.",
        ),
        StoryLine(
          _pip,
          "Never once? How?",
        ),
        StoryLine(
          _sedge,
          "Never had... an appointment.",
        ),
        StoryLine(
          _brad,
          "That is either the wisest thing I have ever heard or the most annoying. I will let you know in a minute.",
        ),
      ]),
      StoryScene(StoryBackdrop.estuary, [_sedge, _brad, _pip, _biscuit], [
        StoryLine(
          _n,
          "The ferry slides away from the jetty so gently that no one notices until the jetty is small. The river "
          "goes by in long, shining ripples.",
        ),
        StoryLine(
          _brad,
          "How long does this crossing take?",
        ),
        StoryLine(_sedge, "...Longer than you would like. ...Shorter than you will remember."),
        StoryChoice('ferry', 'How do you spend the crossing?', [
          StoryOption('Watch the water go by.', [
            StoryLine(
              _sedge,
              "Good. ...Most of the river is only seen... by those who stop.",
            ),
          ]),
          StoryOption('Ask Sedge about the lantern.', [
            StoryLine(
              _sedge,
              "The keeper. Wren. ...Lights it every night. ...Has not crossed to rest in a long time.",
            ),
          ]),
          StoryOption('Close your eyes for a while.', [
            StoryLine(_n, "You doze to the sound of the river. Nobody wakes you."),
            StoryLine(_sedge, "The ferry will keep. ...It always does."),
          ]),
        ]),
        StoryLine(
          _sedge,
          "The big lamp. ...Its glass broke in the storm. Pieces fell. ...Into the harbour. Into the tide pools.",
        ),
        StoryLine(
          _pip,
          "So if we find the pieces, the lamp could shine again?",
        ),
        StoryLine(_sedge, "...If someone... looks. Slowly. Carefully."),
        StoryLine(
          _brad,
          "I have counted four hundred ripples and I have not exploded. Pip, I think I am improving.",
        ),
        StoryLine(
          _pip,
          "You are doing really well, Brad.",
        ),
      ]),
      StoryScene(StoryBackdrop.estuary, [_sedge, _brad, _pip, _biscuit], [
        StoryLine(
          _n,
          "At last the ferry noses into the far jetty. The sun has sunk a hand's width lower, and nobody can say "
          "exactly when.",
        ),
        StoryLine(
          _sedge,
          "Gullhaven is... a short walk. ...I will be here. ...I am always here.",
        ),
        StoryLine(
          _pip,
          "Thank you, Sedge. For not making me hurry.",
        ),
        StoryLine(
          _sedge,
          "Nobody... was ever made to hurry. ...By a river.",
        ),
        StoryLine(
          _n,
          "Brad opens his mouth to answer, closes it, and walks the first ten steps of the path at a perfectly "
          "reasonable speed.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 2,
    number: 11,
    title: 'The Keeper Who Forgot to Rest',
    unlockLevel: 26,
    summary: 'In the harbour, a keeper is carrying a lantern with the last of her strength.',
    scenes: [
      StoryScene(StoryBackdrop.harbour, [_grit, _brad, _pip, _biscuit], [
        StoryLine(
          _n,
          "Gullhaven harbour is full of boats and empty of sailors. They sit on upturned crates, looking out at the "
          "fog, listening for a sound they used to hear every morning.",
        ),
        StoryLine(
          _grit,
          "SURPRISE! I followed you! I was in Brad's backpack! It was very dark and it smelled of Brad!",
        ),
        StoryLine(_brad, "That is why my backpack was so heavy. I thought I was getting stronger."),
        StoryLine(
          _grit,
          "Remember the swap? I kept the shiny you gave me! It is my second-favourite shiny!",
          only: StoryCondition('gremlin', 0),
        ),
        StoryLine(
          _grit,
          "You shared a snack with me! I have thought about that snack for months! Do you have another? ...Is that a "
          "trick? It is not a trick, is it?",
          only: StoryCondition('gremlin', 1),
        ),
        StoryLine(
          _grit,
          "You asked me nicely, {hero}! Nobody asks nicely! It is the shiniest thing anyone has ever done!",
          only: StoryCondition('gremlin', 2),
        ),
        StoryLine(
          _grit,
          "Anyway! I found something shiny in a fishing net! It is the best shiny yet! It is very sharp, so I am "
          "holding it by the very end!",
        ),
        StoryLine(
          _pip,
          "Grit, that is a piece of lamp glass! That is exactly what we are looking for!",
        ),
        StoryLine(_grit, "I KNEW it was good. I always know."),
      ]),
      StoryScene(StoryBackdrop.harbour, [_wren, _grit, _brad, _pip, _biscuit], [
        StoryLine(
          _n,
          "A figure comes along the quay in a navy coat and a yellow hat, carrying a lantern in front of her like "
          "something precious. She is walking the way people walk when they have forgotten how to stop.",
        ),
        StoryLine(
          _wren,
          "Visitors. Good. Hello. I cannot talk long. The lamp has to be lit every night, or somebody out there is "
          "lost.",
        ),
        StoryLine(_pip, "How many nights have you lit it?"),
        StoryLine(_wren, "Forty-one. I think. It could be forty-three."),
        StoryLine(
          _wren,
          "I am Wren. Keeper of the Gullhaven light. I am fine. Fine is my whole job.",
        ),
        StoryLine(
          _n,
          "Her eyes close for just a moment, and she sways. Pip steps forward before anyone else can move.",
        ),
        StoryLine(
          _wren,
          "I am fine. The light cannot go out. I promised I would never let it go out.",
        ),
        StoryChoice('wren', 'What do you say to Wren?', [
          StoryOption('Let us take the first watch.', [
            StoryLine(
              _wren,
              "You would... You would mind it for me? Strangers? ...I do not know what to say.",
            ),
          ]),
          StoryOption('Come and sit. I will make tea.', [
            StoryLine(
              _wren,
              "Tea. I have not had tea sitting down since... I cannot remember. That is the answer, is it not?",
            ),
          ]),
          StoryOption('The light can wait an hour.', [
            StoryLine(
              _wren,
              "An hour. Just an hour. It sounds so small and so enormous at the same time.",
            ),
          ]),
        ]),
        StoryLine(
          _wren,
          "...One hour. Please do not let the lantern go out.",
        ),
      ]),
      StoryScene(StoryBackdrop.harbour, [_wren, _grit, _brad, _pip, _biscuit], [
        StoryLine(
          _n,
          "Wren lies down on a coil of rope. In under a minute, she is asleep. The lantern, in Pip's careful hands, "
          "does not flicker once.",
        ),
        StoryLine(
          _brad,
          "I have never watched anything so important for so long. I am extremely good at it. Do not tell Chad.",
        ),
        StoryLine(
          _pip,
          "I think she needed someone to say it was allowed. Resting, I mean. She did not think it was.",
        ),
        StoryLine(
          _grit,
          "Is sleeping catching? I think I might be catching it. Is it normal to get sleepy when you are surrounded "
          "by shiny things?",
        ),
        StoryLine(
          _n,
          "An old sailor on a crate leans over to Pip and nods at the harbour wall. The tide goes out at dawn, he "
          "says. That is when the pools show what they are hiding.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 2,
    number: 12,
    title: 'What the Tide Brings',
    unlockLevel: 30,
    summary: 'At low tide, the shards of the lamp are waiting, and so is someone very worried about tomorrow.',
    scenes: [
      StoryScene(StoryBackdrop.tidePools, [_pip, _brad, _grit, _biscuit], [
        StoryLine(
          _n,
          "At dawn the sea draws back and leaves the beach full of bright, shallow pools, each one a small, quiet "
          "world.",
        ),
        StoryLine(
          _brad,
          "Right. A plan! We search the beach in neat rows. Row one, row two, row three. Efficient. Methodical.",
        ),
        StoryLine(
          _grit,
          "I am searching in a spiral! Spirals are shinier!",
        ),
        StoryLine(_biscuit, "*Woof!*"),
        StoryLine(
          _n,
          "Biscuit is not searching in rows or in a spiral. He is digging a hole. He appears to be enjoying himself "
          "more than anyone.",
        ),
        StoryLine(
          _pip,
          "Wait. Wait! There is something in this pool. Something glittering. I think... I found one. I actually "
          "found one!",
        ),
        StoryLine(
          _brad,
          "Technically I found the pool.",
        ),
        StoryLine(
          _pip,
          "Technically, yes! Thank you, Brad! Look at it. It has a rainbow in it!",
        ),
      ]),
      StoryScene(StoryBackdrop.tidePools, [_murmur, _pip, _grit, _biscuit], [
        StoryLine(
          _n,
          "On a rock at the edge of the beach, hugging a piece of driftwood, sits something small and purple, "
          "staring at the empty sand.",
        ),
        StoryLine(
          _murmur,
          "The sea went away. It went away, and I do not think it is coming back. What if tomorrow it does not come "
          "back? What if tomorrow is just... sand?",
        ),
        StoryLine(
          _murmur,
          "You said tomorrow was good too, {hero}. I have been practising saying it. 'Tomorrow is good too.' It is "
          "still a bit wobbly.",
          only: StoryCondition('murmur', 0),
        ),
        StoryLine(
          _murmur,
          "You said you would wait for me, {hero}. Nobody ever waits. I have been trying to be worth the wait. I am "
          "not sure how to start.",
          only: StoryCondition('murmur', 1),
        ),
        StoryLine(
          _murmur,
          "You asked me to walk with you, {hero}. I thought about it for a very long time. Then I walked. Here I am. "
          "A bit late.",
          only: StoryCondition('murmur', 2),
        ),
        StoryLine(
          _pip,
          "Hello, Murmur. I know that feeling. When everything goes away and you cannot see it coming back.",
        ),
        StoryChoice('tide', 'What do you tell Murmur about the tide?', [
          StoryOption('It goes out every day, and comes back.', [
            StoryLine(
              _murmur,
              "Every day? Even when I am not watching? ...That is very reliable of it.",
            ),
          ]),
          StoryOption("Let's watch it come in together.", [
            StoryLine(
              _murmur,
              "Together. I think I can be brave for a little while if it is together.",
            ),
          ]),
          StoryOption('Nothing has to be rushed.', [
            StoryLine(
              _murmur,
              "No rushing. The tide does not rush. It just... turns. I think I would like to turn, too.",
            ),
          ]),
        ]),
        StoryLine(
          _grit,
          "I have a shiny for sad times! It is a button! It is for you! It is a very good button!",
        ),
        StoryLine(_murmur, "...It is a very good button. Thank you."),
      ]),
      StoryScene(StoryBackdrop.tidePools, [_murmur, _pip, _brad, _grit, _biscuit], [
        StoryLine(
          _n,
          "Slowly, so slowly that you only notice it by looking away and back, the water creeps in. It fills the "
          "channels, then the pools, then the sand.",
        ),
        StoryLine(
          _murmur,
          "It is coming back. Just like that. It did not even say it was sorry for leaving.",
        ),
        StoryLine(
          _pip,
          "The pools did not disappear, did they? They were just resting.",
        ),
        StoryLine(
          _brad,
          "That is the best thing I have heard all week. I would like it printed on a bookmark.",
        ),
        StoryLine(
          _grit,
          "I counted! Seven pieces of glass! Seven! It is a lot! It is basically a lamp already!",
        ),
        StoryLine(
          _n,
          "Murmur tucks the driftwood under one arm and, after a long breath, falls in with the others on the path "
          "toward the headland. Nobody asks them to hurry.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 2,
    number: 13,
    title: 'A Letter from Oakhelm',
    unlockLevel: 34,
    summary: 'The lamp needs a new frame, and help arrives by cart, very slowly written.',
    scenes: [
      StoryScene(StoryBackdrop.lighthouse, [_wren, _pip, _grit, _biscuit], [
        StoryLine(
          _n,
          "Wren is up and about, rested, and a little embarrassed. She has swept the whole lamp room twice, which "
          "she says is not working, just tidying.",
        ),
        StoryLine(
          _wren,
          "I slept eleven hours. I did not know I still could. Thank you. I mean it. I do not say it enough.",
        ),
        StoryLine(
          _wren,
          "Here is the trouble. We have the glass, and the glass is lovely. But the frame that held the great lens "
          "split in the storm, and it needs a long, straight beam of good timber.",
        ),
        StoryLine(
          _grit,
          "I know a place with lots of timber! It is an Oak Wood! There is a tree there who says 'hmph'!",
        ),
        StoryLine(
          _wren,
          "I promised my teacher I would never let the light go out. I heard 'never rest'. I think she meant "
          "'never be alone with it'.",
        ),
        StoryLine(
          _pip,
          "That is a big difference.",
        ),
        StoryLine(_wren, "It is the whole difference."),
      ]),
      StoryScene(StoryBackdrop.lighthouse, [_maple, _wren, _grit, _pip, _biscuit], [
        StoryLine(
          _n,
          "A creaking cart appears on the headland road, pulled by a very patient pony. Sitting on the back is Maple, "
          "with a clipboard, and beside her a young sapling in a pot.",
        ),
        StoryLine(
          _maple,
          "Hm. Delivery. This is a branch. This is a letter. The letter took Oakhelm a whole season to write. I "
          "have not been allowed to hurry it.",
        ),
        StoryLine(
          _maple,
          "I will read it as written. It is slow. Sit down.",
        ),
        StoryLine(
          _maple,
          "'Dear... {hero}. It is raining on me. This is nice.'",
        ),
        StoryLine(
          _maple,
          "'I have heard about your lamp. I have enclosed a branch. It has been growing for forty years. I did not "
          "know it was for this. Neither did the branch.'",
        ),
        StoryLine(
          _maple,
          "'You asked me about the best thing about being old. I have thought it over. It is the seasons coming "
          "back.'",
          only: StoryCondition('oak', 0),
        ),
        StoryLine(
          _maple,
          "'The squirrels have started writing again. They write in very small writing. I have not been able to read "
          "any of it. I do not mind.'",
          only: StoryCondition('oak', 1),
        ),
        StoryLine(
          _maple,
          "'You asked if you might sit a little longer. You may. The bench is yours. It has been yours since you "
          "asked.'",
          only: StoryCondition('oak', 2),
        ),
        StoryLine(
          _maple,
          "'Yours, Oakhelm. P.S. Hmph.'",
        ),
        StoryChoice('letter', 'What do you write back?', [
          StoryOption('Thank you, Oakhelm.', [
            StoryLine(
              _maple,
              "Hm. Short, warm, and no hurry. He will like that. I will carry it back slowly.",
            ),
          ]),
          StoryOption('We will look after the branch.', [
            StoryLine(
              _wren,
              "We will. I will carve the frame myself and keep a spare piece to remember it by.",
            ),
          ]),
          StoryOption('Take your time replying.', [
            StoryLine(
              _maple,
              "That, he will take literally. See you in about a year, {hero}. I will bring biscuits.",
            ),
          ]),
        ]),
      ]),
      StoryScene(StoryBackdrop.lighthouse, [_wren, _maple, _grit, _pip, _biscuit], [
        StoryLine(
          _n,
          "The whole afternoon goes into the frame. Wren carves, Maple measures, Pip holds the shards one by one "
          "against the light, and Grit presses a single shiny button into the very centre, for luck.",
        ),
        StoryLine(
          _grit,
          "It is not a mistake! It is a feature! It is a button feature!",
        ),
        StoryLine(
          _wren,
          "It is the best part of the lens. I thank you all. I forgot that a light is easier to keep when more than "
          "one person is looking after it.",
        ),
        StoryLine(
          _maple,
          "Hm. That is true of most things. Tea?",
        ),
        StoryLine(
          _n,
          "The great lens stands whole at last, patched with rainbow glass and a button. Tomorrow at dusk, the lamp "
          "will be lit.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 2,
    number: 14,
    title: 'The Night Before the Light',
    unlockLevel: 38,
    summary: 'Under the stars at the foot of the tower, everyone is a little nervous, and someone walks a very long way.',
    scenes: [
      StoryScene(StoryBackdrop.lighthouse, [_wren, _pip, _brad, _murmur, _grit], [
        StoryLine(
          _n,
          "Everyone camps at the foot of the tower, wrapped in blankets, with stars appearing one by one over the "
          "dark sea.",
        ),
        StoryLine(
          _brad,
          "Tomorrow I will carry the lamp oil up all one hundred and eighty-two steps. Without stopping. With "
          "enthusiasm.",
        ),
        StoryLine(_wren, "You will stop at every landing."),
        StoryLine(_brad, "...I will stop at every landing, with enthusiasm."),
        StoryLine(
          _murmur,
          "I counted the stars. There were more than yesterday. Tomorrow will have even more. I am almost looking "
          "forward to it.",
        ),
        StoryLine(
          _grit,
          "I counted my shinies! There were exactly the same! I checked three times! That is also good!",
        ),
        StoryLine(
          _wren,
          "I have never lit this lamp with anyone beside me. Do you know what it is like to look up and see "
          "everyone here? It is a bit like being a tide.",
        ),
      ]),
      StoryScene(StoryBackdrop.lighthouse, [_pip, _wren, _brad, _murmur, _grit], [
        StoryLine(
          _n,
          "Later, when the others are quiet, Pip sits on the edge of the rocks beside you, knees pulled up to their "
          "chin.",
        ),
        StoryLine(
          _pip,
          "Can I tell you something? I am really scared about the stairs.",
        ),
        StoryLine(
          _pip,
          "A hundred and eighty-two. What if I get to the middle and cannot go on? What if everyone has to wait for "
          "me, and I ruin the whole night?",
        ),
        StoryChoice('pip', 'What do you tell Pip?', [
          StoryOption('The wall counts.', [
            StoryLine(
              _pip,
              "That is a funny thing to say. But it feels... true? Like it counts, even the small, silly versions.",
            ),
          ]),
          StoryOption('Rest at every landing.', [
            StoryLine(
              _pip,
              "Every landing. There are nine. That is ten small climbs instead of one enormous one. ...I can do ten "
              "small ones.",
            ),
          ]),
          StoryOption("I'll climb right beside you.", [
            StoryLine(
              _pip,
              "Beside me. Not behind and not in front. ...Okay. I think I just got a bit taller.",
            ),
          ]),
        ]),
        StoryLine(
          _pip,
          "Thank you. I know I did not start well. But I am glad I came.",
        ),
        StoryLine(
          _n,
          "From the dark, a grumbling, familiar voice: \"Nobody ruins anything by being slow. Slow is how everything "
          "gets done.\"",
        ),
      ]),
      StoryScene(StoryBackdrop.lighthouse, [_chad, _pip, _brad, _wren, _grit], [
        StoryLine(
          _n,
          "A wheezing shape comes up the headland path, leaning on a very large walking stick and carrying "
          "a very small bag.",
        ),
        StoryLine(_pip, "Chad?! You came!"),
        StoryLine(
          _chad,
          "I walked. All the way. It took four days. I rested at step eleven every single morning, and I saw a "
          "goose do something unspeakable.",
        ),
        StoryLine(
          _brad,
          "You walked? Alone? All that way?",
        ),
        StoryLine(
          _chad,
          "I was not alone. I had my dignity. It was mostly a hindrance.",
        ),
        StoryLine(
          _chad,
          "Maple said the hall can run itself for a week. She wrote it down and made me sign it, in front of "
          "witnesses. And, {hero}, I wanted to see the light. I wanted to see my guild.",
        ),
        StoryLine(
          _wren,
          "You must be Chad. I heard you rang a bell. I have been waiting a long time to meet whoever did.",
        ),
        StoryLine(
          _chad,
          "Oh, I did not ring it. Everyone did. That is what a guild is. ...Please. Is there anywhere to sit?",
        ),
        StoryLine(
          _n,
          "Everyone shuffles up on a single blanket. Biscuit, who has been awake the whole time, politely "
          "pretends to be asleep.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 2,
    number: 15,
    title: 'The Answering Light',
    unlockLevel: 42,
    summary: 'The lamp is lit, the fleet comes home, and something far away answers.',
    scenes: [
      StoryScene(StoryBackdrop.lighthouse, [_wren, _chad, _pip, _brad, _grit], [
        StoryLine(
          _n,
          "At dusk, they climb. All one hundred and eighty-two steps, and nine landings, and a good many pauses. "
          "Chad rests at step eleven. Brad rests at step twelve, purely to support him.",
        ),
        StoryLine(
          _pip,
          "Three more landings. I am doing it. I am actually doing it! Do not look at me, I might get nervous.",
        ),
        StoryLine(
          _grit,
          "I am looking at the buttons on the stairs! There are no buttons on the stairs! I am looking anyway!",
        ),
        StoryLine(
          _n,
          "At the top, the great lens waits in the lamp room, whole, patched with rainbow glass and one shiny "
          "button. Beyond it, the sea turns the colour of a ripe peach.",
        ),
        StoryLine(
          _wren,
          "Forty-one nights I lit the little lantern alone. Tonight, someone else should light the great lamp. "
          "{hero}, will you?",
        ),
        StoryChoice('light', 'How do you light the lamp?', [
          StoryOption('One careful spark.', [
            StoryLine(
              _n,
              "You strike a single spark, patient and steady. The wick takes it, and the flame grows, and grows.",
            ),
          ]),
          StoryOption('With everyone.', [
            StoryLine(
              _n,
              "Wren holds the wick, Pip the lamp, Brad the oil, Chad the spark, and Grit the button. It is not "
              "tidy. The flame catches anyway.",
            ),
          ]),
          StoryOption('Let Pip light it.', [
            StoryLine(
              _pip,
              "Me? ...Okay. Okay! I think I can. Just... hold my hand a second.",
            ),
            StoryLine(
              _n,
              "Pip's spark is small and a little shaky. It is exactly enough.",
            ),
          ]),
        ]),
        StoryLine(
          _n,
          "The great lamp wakes. Light pours through the patched lens, a hundred small rainbows at once, and a "
          "single bright beam sweeps out over the water.",
        ),
      ]),
      StoryScene(StoryBackdrop.lighthouseNight, [_wren, _chad, _pip, _brad, _murmur], [
        StoryLine(
          _n,
          "Out at sea, one by one, small lanterns blink awake on the water. The fleet has been waiting, and now it "
          "is coming home.",
        ),
        StoryLine(
          _murmur,
          "Look at them all. They found the way. I did not think they would. ...I am very glad I was wrong.",
        ),
        StoryLine(
          _n,
          "And then, far off to the east, so faint that everyone has to hold their breath, a deep, warm note rolls "
          "across the dark: BONG.",
        ),
        StoryLine(
          _wren,
          "That is the bell. Your Dawn Bell. Somebody is ringing it, back in the valley. It is answering the light.",
        ),
        StoryLine(
          _chad,
          "Maple. She must have climbed the tower herself. Without telling me. On her day off. ...Dawn Bell by "
          "morning, lantern by night. Someone to say hello at both ends of the day.",
        ),
        StoryLine(
          _brad,
          "I would like it noted that I carried the oil, rested at every landing, and did not explode.",
        ),
        StoryLine(_pip, "It is noted, Brad."),
        StoryLine(
          _wren,
          "Now. If nobody minds, I am going to bed. A real bed, with a pillow. For ten hours. And tomorrow the "
          "lamp will be looked after by the whole of Gullhaven, in shifts.",
        ),
        StoryLine(
          _chad,
          "Rest is training, Wren. It is on a banner. I will send you the banner.",
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Move however you like. Rest when you need to. The hall is yours.",
          only: StoryCondition('motivation', 0),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Have fun with it, the way you said you would. The hall is yours.",
          only: StoryCondition('motivation', 1),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Stay curious, the way you did from the very first day. The hall is yours.",
          only: StoryCondition('motivation', 2),
        ),
        StoryLine(
          _n,
          "The beam sweeps the sea, the bell answers from the hills, and a place is kept at the Guild Hall for "
          "whoever walks in next. The lamp burns on, and everyone sleeps at their own pace.",
        ),
      ]),
    ],
  ),
];
