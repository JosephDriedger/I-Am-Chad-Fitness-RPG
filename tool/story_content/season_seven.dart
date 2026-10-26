/// Season Seven, "The Day Off": a prologue and seven chapters in which the guild gives
/// Chad, who has never once stopped, a day off, and he has no idea what to do with it.
/// The same rules apply as in the earlier seasons (see docs/STORY.md and
/// docs/CONTENT_GUIDELINES.md): warm and funny, nothing timed, nothing that shames, and
/// rest shown as an ordinary part of the way. It is free for everyone, like the others.
///
/// Its theme is rest, as the main event: that stopping is a skill, that other people
/// rest in other ways, that a thing worth building keeps standing when you step back,
/// and that you are enough when you are still. It is also the first season that opens by
/// how much the player moves rather than by level, because the levels have run out.
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
const _goat = StorySpeaker.goat;

const seasonSevenChapters = <StoryChapter>[
  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 7,
    number: 48,
    title: 'A Hall Without Chad',
    unlockLevel: 144,
    afterChapter: 47,
    afterDays: 0,
    summary: 'The guild votes, with great kindness and no dissent, to give Chad a day off. He takes it badly.',
    scenes: [
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _pip, _juno, _bertram], [
        StoryLine(
          _n,
          "A notice has appeared on the board in the Guild Hall of Steady Steps. It is written in Maple's neatest hand, "
          "signed by everyone, and pinned with a very firm pin.",
        ),
        StoryLine(
          _maple,
          "'Be it known that the Guildmaster is to take a day off. The day may be spread across several days, at his "
          "leisure, which he is also to take.'",
        ),
        StoryLine(
          _chad,
          "A vote! Behind my back! I am the guildmaster! I invented votes!",
        ),
        StoryLine(
          _maple,
          "You voted too. You voted against yourself, asked for a recount, and then voted against yourself again.",
        ),
        StoryLine(
          _pip,
          "We like you a great deal, Chad. That's the whole reason. You haven't sat down since the Comet.",
        ),
        StoryLine(
          _juno,
          "I've never seen him not busy. I didn't know it was something you could be allowed to stop.",
        ),
        StoryLine(
          _bertram,
          "I once read that a person who cannot sit down has often forgotten what it feels like to stand still on purpose. "
          "I wrote it in the margin of item forty. It has aged very well.",
        ),
        StoryLine(
          _chad,
          "I am extremely rested already. Observe. I could run this hall in my sleep. I have, on several occasions.",
        ),
        StoryLine(
          _maple,
          "That is not the argument you think it is.",
        ),
        StoryChoice('vote', 'How do you vote on Chad\'s day off?', [
          StoryOption('Yes, with all my heart.', [
            StoryLine(
              _pip,
              "That makes it unanimous again. We've voted unanimously eleven times this week. It's become a habit.",
            ),
          ]),
          StoryOption('Yes, and I will help run the hall.', [
            StoryLine(
              _maple,
              "Help accepted. I have a list. It has one item on it that says 'let the hall be'.",
            ),
          ]),
          StoryOption('I abstain, and bring snacks.', [
            StoryLine(
              _bertram,
              "A principled position. Snacks are the foundation of every great decision I have ever witnessed.",
            ),
          ]),
        ]),
        StoryLine(
          _chad,
          "...Fine. A day off. I will take it extremely seriously. I will be the best at it that anyone has ever been.",
        ),
        StoryLine(
          _maple,
          "Resting is not a contest, Chad.",
        ),
        StoryLine(
          _chad,
          "Everything is a contest if you are brave enough. Where do I begin? Is there a form?",
        ),
        StoryLine(
          _juno,
          "I think you just sit. And, maybe, see what happens.",
        ),
        StoryLine(
          _chad,
          "Sit. And see what happens. Right. That sounds terrifying. I will do it at once.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 7,
    number: 49,
    title: 'Strategic Pauses',
    unlockLevel: 144,
    afterChapter: 47,
    afterDays: 10,
    summary: 'Chad schedules his rest in fifteen-minute blocks, and Maple takes the schedule away.',
    scenes: [
      StoryScene(StoryBackdrop.hall, [_chad, _maple, _pip, _juno, _biscuit], [
        StoryLine(
          _n,
          "Chad arrives at breakfast with a roll of paper that unrolls across the whole table and a little way down the hall.",
        ),
        StoryLine(
          _chad,
          "The Schedule of Rest. It is a masterpiece. Six o'clock: Sit. A quarter past: Sit Differently. Half past: Look Out of a Window "
          "Thoughtfully. A quarter to seven: Lie Down (Briefly).",
        ),
        StoryLine(
          _pip,
          "There's a column for 'Rest Achieved', Chad. It's got a tick box.",
        ),
        StoryLine(
          _chad,
          "Rest is training. I have always said so. So it must be trained! With rigour! In fifteen-minute blocks!",
        ),
        StoryLine(
          _maple,
          "Rest that has a timetable is just work in slippers.",
        ),
        StoryLine(
          _juno,
          "What happens if you finish a block early? Do you, can you rest harder?",
        ),
        StoryLine(
          _chad,
          "Excellent question. There is a bonus section. It is called Extra Rest.",
        ),
        StoryLine(
          _n,
          "Biscuit, who has been lying beside the hearth for some hours with his chin on the floor and his eyes half shut, lets out "
          "a long sigh. It is, without question, the most competent rest anyone in the hall has done all week.",
        ),
        StoryLine(
          _maple,
          "Look at him. He does not have a schedule. He has not looked at a clock. He has simply stopped.",
        ),
        StoryLine(
          _chad,
          "He is a professional. He has been practising since a puppy.",
        ),
        StoryChoice('plan', 'What do you do with the Schedule of Rest?', [
          StoryOption('Fold it into a boat.', [
            StoryLine(
              _pip,
              "A boat! Brilliant. Now it's a thing you can float, and nobody has to tick anything.",
            ),
          ]),
          StoryOption('Cross out the first item.', [
            StoryLine(
              _maple,
              "Oh, that is a brave pen stroke. Cross out another and we shall have started something.",
            ),
          ]),
          StoryOption('Hand it to Maple.', [
            StoryLine(
              _maple,
              "Thank you. I shall file it under 'things Chad made when he was nervous', which is a large cabinet.",
            ),
          ]),
        ]),
        StoryLine(
          _chad,
          "Without the schedule I do not know what time it is. Or what I am supposed to feel. Or when it is allowed to stop.",
        ),
        StoryLine(
          _maple,
          "That is the point, Chad. You are not supposed to know. At your own pace. Whatever that turns out to be.",
        ),
        StoryLine(
          _juno,
          "You could start by sitting next to Biscuit. He's very good at it, and he doesn't mind teaching.",
        ),
        StoryLine(
          _n,
          "Chad lowers himself to the floor, with the care of a man entering a cold lake, and lies beside the dog. For almost "
          "nine seconds nothing happens. Then Biscuit moves his tail, once, in welcome.",
        ),
        StoryLine(
          _biscuit,
          "Woof.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 7,
    number: 50,
    title: 'The Hammock Problem',
    unlockLevel: 144,
    afterChapter: 47,
    afterDays: 20,
    summary: 'A hammock, a garden, a very upright man, and a goat with an appetite for plans.',
    scenes: [
      StoryScene(StoryBackdrop.garden, [_chad, _juno, _pip, _goat], [
        StoryLine(
          _n,
          "Behind the hall there is a garden that nobody has used for years, and in it, between two trees, somebody has hung a hammock. "
          "It is the colour of a tangerine. It is, Pip says, the most welcoming thing she has ever built.",
        ),
        StoryLine(
          _pip,
          "I made it on my day off. I'd never had one. It took me two hours and I didn't mind a minute of it.",
        ),
        StoryLine(
          _chad,
          "A hammock! Excellent. A well-designed rest device. I shall enter it in the correct manner.",
        ),
        StoryLine(
          _n,
          "He climbs in. He is, throughout, sitting perfectly upright, with his hands on his knees, like a man waiting to be interviewed "
          "by a hammock.",
        ),
        StoryLine(
          _juno,
          "Chad. You can lie back. It holds you. That's what it's for.",
        ),
        StoryLine(
          _chad,
          "I am lying back. This is how I lie back. Observe the angle.",
        ),
        StoryLine(
          _n,
          "A small sound comes from the hedge. A goat steps out, a cream-coloured one, with small horns and a calm eye, chewing on what "
          "turns out, on inspection, to be a corner of the Schedule of Rest.",
        ),
        StoryLine(
          _goat,
          "Meh.",
        ),
        StoryLine(
          _pip,
          "It's the goat from Brun's door! The one that was the first knock in eleven years. It must have walked all the way up the stair.",
        ),
        StoryLine(
          _goat,
          "Mm. The sun is warm. That is the whole plan.",
        ),
        StoryLine(
          _n,
          "The goat lies down on the warm grass, folds its legs under itself, and closes its eyes. It does this without effort, "
          "without a diagram, and without once checking whether it is doing it right.",
        ),
        StoryLine(
          _chad,
          "It has no schedule. It has eaten my schedule. I am not sure whether to be offended or inspired.",
        ),
        StoryChoice('hammock', 'How do you help Chad into the hammock?', [
          StoryOption('Hold it steady for him.', [
            StoryLine(
              _juno,
              "There. It's steady. It's not going anywhere. You can let go of the sides, and let it have you.",
            ),
          ]),
          StoryOption('Get in first, to show him.', [
            StoryLine(
              _pip,
              "Move over. Okay. See? You just let your head be heavy. That's, honestly, all it is.",
            ),
          ]),
          StoryOption('Tell him it is allowed.', [
            StoryLine(
              _juno,
              "It's allowed. Nobody needs you for a bit. That is the nicest sentence I know, so I thought I'd say it.",
            ),
          ]),
        ]),
        StoryLine(
          _n,
          "Slowly, one muscle at a time, as if somebody were turning down a very loud radio, Chad lies back. The hammock sways. "
          "He looks up through the leaves. His face does something nobody has seen it do before: nothing at all.",
        ),
        StoryLine(
          _chad,
          "Oh. It is quiet up here. Has it always been this quiet?",
        ),
        StoryLine(
          _goat,
          "Meh.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 7,
    number: 51,
    title: "Other People's Ways of Resting",
    unlockLevel: 144,
    afterChapter: 47,
    afterDays: 30,
    summary: 'Soup, landings and early nights: friends from all over come to show Chad how they do it.',
    scenes: [
      StoryScene(StoryBackdrop.garden, [_chad, _hush, _tamsin, _wren, _sedge], [
        StoryLine(
          _n,
          "Word has gone out along the roads that the guildmaster is learning to stop. By afternoon the garden has visitors, "
          "each with a small bag and the look of somebody asked to give a lesson in something they never thought of as a skill.",
        ),
        StoryLine(
          _hush,
          "I brought soup. I hold the bowl in both hands, and I do not do anything else until it is empty. That is the whole of "
          "my method. It is a very good method.",
        ),
        StoryLine(
          _tamsin,
          "I stop at every landing, even where there is no stair. A landing is just a place that says, you may stand here "
          "for a moment. They are everywhere, once you start to see them.",
        ),
        StoryLine(
          _wren,
          "I go to bed when the sun does, and I sleep eleven hours. It sounds like nothing. It is the bravest thing I have ever "
          "done. I was very frightened of it.",
        ),
        StoryLine(
          _sedge,
          "I do not rest. I go slowly. It is, I find, the same thing from the inside.",
        ),
        StoryLine(
          _chad,
          "Four ways! Four masters! I will master all of them by teatime.",
        ),
        StoryLine(
          _hush,
          "You will not. And that is the first lesson. You are not supposed to be good at it.",
        ),
        StoryChoice('way', 'Whose way of resting do you try first?', [
          StoryOption("Hush's soup.", [
            StoryLine(
              _hush,
              "Both hands. Warm bowl. Nothing else. There. Do you feel the little pause before the first spoonful? That is the rest.",
            ),
          ]),
          StoryOption("Tamsin's landings.", [
            StoryLine(
              _tamsin,
              "You have found one already. You are standing in it. Take a breath, and let your shoulders arrive.",
            ),
          ]),
          StoryOption("Wren's early night.", [
            StoryLine(
              _wren,
              "Lovely. Tonight, sundown. I will bring a lantern that does not quite go out, and I will sit beside you until you "
              "are asleep, if you like.",
            ),
          ]),
        ]),
        StoryLine(
          _chad,
          "This is difficult. Each of them is very good at it, and I seem to be very good at the wrong end of it.",
        ),
        StoryLine(
          _sedge,
          "Nobody is good at rest. We are only practised at letting it happen.",
        ),
        StoryLine(
          _tamsin,
          "And nothing here has a deadline. Not even this. You may start again as often as you need to, and begin where you are.",
        ),
        StoryLine(
          _n,
          "Chad sits down on the grass between a yeti with a bowl, a Weatherkeeper at an invisible landing, a lighthouse "
          "keeper on the verge of a nap, and a tortoise who has not moved in some time.",
        ),
        StoryLine(
          _n,
          "He does his best. It is a very small, very honest best. It is, everyone agrees, the best they have seen him do.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 7,
    number: 52,
    title: 'A Hall That Runs Itself',
    unlockLevel: 144,
    afterChapter: 47,
    afterDays: 40,
    summary: 'A small emergency in the hall, handled calmly without Chad, to his enormous relief and slight dismay.',
    scenes: [
      StoryScene(StoryBackdrop.hall, [_maple, _pip, _juno, _bertram, _chad], [
        StoryLine(
          _n,
          "On the fourth day of the day off, forty-one crates arrive at the hall's front step at once. They are Brun's. They are all "
          "hammers. They are accompanied by a goose, who has opinions, and a note saying 'Sorry, early. B.'",
        ),
        StoryLine(
          _maple,
          "Right. Forty-one crates. Pip, the east wall. Juno, the tally book. Bertram, the goose.",
        ),
        StoryLine(
          _bertram,
          "I shall engage the goose in conversation. It is, historically, the only thing that works.",
        ),
        StoryLine(
          _juno,
          "I've counted them. It's forty-one, I'm sure, and one of them is a hat.",
        ),
        StoryLine(
          _pip,
          "Stack them by size, hats at the front. And please, mind the Duck Mat.",
        ),
        StoryLine(
          _n,
          "At the upstairs window, in a hammock he has carried in under his arm, Chad is trying very hard to lie still. He fails. "
          "His whole body leans towards the stairs.",
        ),
        StoryLine(
          _chad,
          "I can see it from here. The crates are the wrong way round. The goose is winning. I am going down. I am only going to "
          "supervise from a little distance. From inside the crates.",
        ),
        StoryLine(
          _maple,
          "Chad. You have a day off.",
        ),
        StoryLine(
          _chad,
          "I know! I am having it! I am simply having it near the crates!",
        ),
        StoryLine(
          _n,
          "Below, without him, the guild does it. Not perfectly, and not quickly. A crate goes in the wrong place and is moved. "
          "Bertram negotiates a ceasefire with the goose. Juno finds the hat. Somebody laughs.",
        ),
        StoryLine(
          _n,
          "By the end of the afternoon the whole hall is orderly, in a gently lopsided way, and nobody has raised their voice.",
        ),
        StoryLine(
          _chad,
          "It is fine. It is all fine. They have done it perfectly well without me, and I am so relieved, and a very small "
          "part of me wants to lie down and cry.",
        ),
        StoryChoice('fix', 'What do you say to Chad at the window?', [
          StoryOption('They have got it.', [
            StoryLine(
              _chad,
              "They have. They have got it, and it is theirs. I think I have been holding it very tightly for a very long time.",
            ),
          ]),
          StoryOption('Come and watch with me.', [
            StoryLine(
              _chad,
              "Yes. Yes, I will. I will sit down at the window and watch my hall be a good hall without me. Move over.",
            ),
          ]),
          StoryOption('It looks like your hall.', [
            StoryLine(
              _maple,
              "It does. That is what a good hall looks like when the person who built it is not standing in the middle of it.",
            ),
          ]),
        ]),
        StoryLine(
          _maple,
          "A hall that runs without you is the best thing you ever built, Chad. Rest is training, and this is what it was for.",
        ),
        StoryLine(
          _chad,
          "...Maple. May I say I am proud of all of you? From a safe, seated distance?",
        ),
        StoryLine(_maple, "You may. It is allowed."),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 7,
    number: 53,
    title: 'Why Chad Does Not Stop',
    unlockLevel: 144,
    afterChapter: 47,
    afterDays: 50,
    summary: 'In the garden, after the others have gone in, Chad says the true thing.',
    scenes: [
      StoryScene(StoryBackdrop.garden, [_chad, _maple, _juno, _goat], [
        StoryLine(
          _n,
          "Evening. The others have gone in for supper and the garden has gone gold and quiet. Chad is in the hammock, not "
          "upright at all, with one arm hanging down and the goat asleep underneath.",
        ),
        StoryLine(
          _juno,
          "Can I sit with you? I won't say anything. I'm just bringing the cup.",
        ),
        StoryLine(
          _chad,
          "Please. And Maple, I can hear you pretending to look at a flowerpot. Come and sit.",
        ),
        StoryLine(
          _maple,
          "It was a very interesting flowerpot.",
        ),
        StoryLine(
          _chad,
          "I want to tell you why I do not stop. I have not told anyone. I started at Level 1, like everyone, and I was very small, "
          "and I thought: if I keep moving, nobody will notice I do not know what I am doing.",
        ),
        StoryLine(
          _chad,
          "And then I became the guildmaster, and everyone was looking at me, and I thought: I must not stop. If I stop, they will "
          "see that under the cape it is just me.",
        ),
        StoryLine(
          _juno,
          "I thought that too. When I first knocked. I thought, I need to be doing something, so they don't see I'm not sure I belong.",
        ),
        StoryLine(
          _maple,
          "Chad. I lit the first fire, you will remember. I have watched you for a great many years from beside it. It is just you "
          "under the cape. That is the part everybody came for.",
        ),
        StoryLine(
          _chad,
          "...It is?",
        ),
        StoryLine(
          _maple,
          "It always was. The cape is a very good cape. It is not the reason.",
        ),
        StoryChoice('truth', 'What do you tell Chad?', [
          StoryOption('You are enough when you are still.', [
            StoryLine(
              _chad,
              "When I am still. I did not know that was a thing a person could be told. Thank you. I think I will need to hear it again tomorrow.",
            ),
            StoryLine(
              _juno,
              "You can hear it every day. I'll say it. I'm quite good at remembering things.",
            ),
          ]),
          StoryOption('We like you with the cape off, too.', [
            StoryLine(
              _chad,
              "With it off. Even the cape. I shall consider it. Possibly I shall hang it on a hook, as an experiment.",
            ),
          ]),
          StoryOption('Rest is part of the story.', [
            StoryLine(
              _maple,
              "It is the longest part of any story that lasts. We just tend to skip it when we tell it.",
            ),
          ]),
        ]),
        StoryLine(
          _n,
          "The goat opens one eye, checks that everything is as it should be, and closes it again. The hammock sways. "
          "Somewhere in the hall a kettle begins to sing.",
        ),
        StoryLine(
          _chad,
          "I think I can hear the garden. It has been going on this whole time. I did not know it was so busy.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 7,
    number: 54,
    title: 'The Night Before the Nothing',
    unlockLevel: 144,
    afterChapter: 47,
    afterDays: 60,
    summary: 'The garden fills up with people with nothing planned, which takes a surprising amount of preparation.',
    scenes: [
      StoryScene(StoryBackdrop.garden, [_chad, _bertram, _pip, _juno, _goat], [
        StoryLine(
          _n,
          "It has been decided, by a vote nobody can quite remember holding, that the day off will end with a Great Do Nothing, "
          "to which everyone is invited, at which nothing at all will happen, and for which, it turns out, a great deal of "
          "preparation is required.",
        ),
        StoryLine(
          _bertram,
          "I have a list. It is, I think, my finest. 'Item one: nothing, planned in detail.' It has seventeen sub-items. "
          "Sub-item nine is 'a place to put the nothing'.",
        ),
        StoryLine(
          _pip,
          "I've done blankets. There are forty blankets. They don't match, and I think that's the best bit.",
        ),
        StoryLine(
          _juno,
          "And I've asked people to come with no plans. It's harder than it sounds. Everybody keeps asking what to bring.",
        ),
        StoryLine(
          _chad,
          "I have planned nothing so thoroughly that I am a little worried it will go wrong. I have a whole section on what to do "
          "if there is nothing happening and it becomes awkward.",
        ),
        StoryLine(
          _pip,
          "That is 'what to do if there is nothing happening'. It's just the Nothing. It's working.",
        ),
        StoryLine(
          _goat,
          "Meh.",
        ),
        StoryLine(
          _n,
          "The goat, who has no list and no blanket, is lying in the exact middle of the lawn. It is generally agreed that this is "
          "the best place for the Nothing to be, and that the goat found it first.",
        ),
        StoryChoice('bring', 'What do you bring to the Nothing?', [
          StoryOption('A blanket, and nothing else.', [
            StoryLine(
              _pip,
              "A blanket. That's the lot. It's perfect. It's the whole of what anyone needs.",
            ),
          ]),
          StoryOption('A book I do not plan to read.', [
            StoryLine(
              _bertram,
              "A book not to be read. A beautiful object. It is the finest kind of luggage, and it never weighs anything.",
            ),
          ]),
          StoryOption('A friend who is also busy.', [
            StoryLine(
              _juno,
              "That's the best thing you could bring. Busy people are the ones who need the Nothing most.",
            ),
          ]),
        ]),
        StoryLine(
          _bertram,
          "It is a curious thing. I have spent my life collecting items to do. I find that I am happier than I have ever been "
          "collecting an item to simply be.",
        ),
        StoryLine(
          _chad,
          "At your own pace, everyone. That is the only rule. I have written it on a stick. It is the only thing I have written "
          "in a month that I did not need to revise.",
        ),
        StoryLine(
          _n,
          "One by one the lanterns are hung, and the garden softens in the dusk. Forty blankets lie ready on the grass, like a very "
          "large, very untidy flag of a country where nobody has to be anywhere.",
        ),
      ]),
    ],
  ),

  // ---------------------------------------------------------------------------
  StoryChapter(
    season: 7,
    number: 55,
    title: 'The Great Do Nothing',
    unlockLevel: 144,
    afterChapter: 47,
    afterDays: 70,
    summary: 'The whole guild does nothing together, beautifully, and the hall is still standing at the end of it.',
    scenes: [
      StoryScene(StoryBackdrop.garden, [_chad, _maple, _hush, _sedge, _goat], [
        StoryLine(
          _n,
          "It begins, as these things do, with nobody saying that it has begun. People arrive. They find a blanket. They lie down on it. "
          "That is all that happens, and it takes about an hour, and nobody wants it to end.",
        ),
        StoryLine(
          _hush,
          "I have brought soup, and I have not served it. It is simply there. I find it is a great comfort to have soup near nothing.",
        ),
        StoryLine(
          _sedge,
          "It is the most punctual thing I have ever attended. It has begun exactly when it began.",
        ),
        StoryLine(
          _maple,
          "I have not checked the list once. I am a little frightened. It is wonderful.",
        ),
        StoryLine(
          _chad,
          "I had prepared a speech. It has a goose in it. I am not going to give it. I find I am, for the first time, completely "
          "content to be one person on a blanket among many.",
        ),
        StoryLine(
          _n,
          "The whole guild lies on its back in the long gold light. Somewhere a moth, which has followed the story all the way from "
          "the Isles, settles on a drum. The goat sighs. The hammock sways. Nobody says anything useful, and the silence is full of it.",
        ),
        StoryChoice('nothing', 'What do you do with your nothing?', [
          StoryOption('Watch the clouds go by.', [
            StoryLine(
              _sedge,
              "A cloud is a very good teacher. It goes where it goes, and it is never once in a hurry.",
            ),
          ]),
          StoryOption('Close my eyes.', [
            StoryLine(
              _hush,
              "Yes. Eyes closed. The best of all the ways. You may as well take the whole afternoon.",
            ),
          ]),
          StoryOption('Listen to everyone breathing.', [
            StoryLine(
              _maple,
              "Oh, that is the loveliest. All of us, in and out, a little out of step, and none of us minding.",
            ),
          ]),
        ]),
      ]),
      StoryScene(StoryBackdrop.hearth, [_chad, _maple, _pip, _bertram, _juno], [
        StoryLine(
          _n,
          "When the lanterns have burned low they carry the blankets in, and the hall is just as they left it: standing, warm, "
          "a little untidy, with the small red line in the hearth, exactly where it always is.",
        ),
        StoryLine(
          _maple,
          "The hall is still standing. It was standing the entire time. I want that written down in a very large hand.",
        ),
        StoryLine(
          _chad,
          "Everything held. The fire, the roof, the goose. It held without me, and it held with me lying down, and I could not "
          "be prouder of any of it.",
        ),
        StoryLine(
          _pip,
          "You said you didn't know what to do with a day off. What did you do?",
        ),
        StoryLine(
          _chad,
          "I think I let it do me. It turned out to be the one thing I had never tried.",
        ),
        StoryLine(
          _juno,
          "You told someone once to look up sometimes. I looked up the whole way here. It made all of it a bit softer.",
          only: StoryCondition('stars', 2),
        ),
        StoryLine(
          _juno,
          "You told someone once to go at their own pace. I've been doing it. I'm a lot slower than I thought, and a lot further on.",
          only: StoryCondition('stars', 1),
        ),
        StoryLine(
          _juno,
          "You told someone once that they don't have to be good at it yet. I'm not. I'm just here. It's wonderful.",
          only: StoryCondition('stars', 0),
        ),
        StoryLine(
          _bertram,
          "I have a new item. Item one hundred and thirteen. 'Do nothing, regularly, with friends.' I have not ticked it. I do not "
          "think it is the kind of item that has a tick.",
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Move however you like, rest when you need to, and when you need to, rest properly, on purpose. The hall is yours.",
          only: StoryCondition('motivation', 0),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Have fun with it, the way you said you would, and have a lie-down in the middle of it. The hall is yours.",
          only: StoryCondition('motivation', 1),
        ),
        StoryLine(
          _chad,
          "Come by when you like, {hero}. Stay curious, the way you did from the very first day, and be curious about stopping, too. The hall is yours.",
          only: StoryCondition('motivation', 2),
        ),
        StoryLine(
          _n,
          "Far away a bell rings, a lamp winks, a chime sings, a table is laid, a small fire is kept and a comet makes its slow way home.",
        ),
        StoryLine(
          _n,
          "And in a hall on a hill, nothing at all happens, at its own pace, with a goat on the rug and a guildmaster fast asleep "
          "in a chair he did not once check was the right one.",
        ),
      ]),
    ],
  ),
];
