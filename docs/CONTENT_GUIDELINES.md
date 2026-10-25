# Content guidelines

Rules for anything a player reads, sees or is rewarded for. They come from the GDD's pillars (sections 2, 5.2, 7, 9 and 12) and apply to dialogue, quests, enemy design, UI copy and mechanics.

## Tone

- **Warm, theatrical, a little silly.** Chad is a self-proclaimed legend who is occasionally unreliable about his own exploits. The joke is always on Chad, never on the player.
- **Celebrate effort, not outcomes.** "That counts, and it counts well." never "You finally did something."
- **Skippable and short.** Dialogue should never block the player. Experienced users can enable "Quieter Chad".
- **Chad mentors; the player is the hero.** Chad does not take over the protagonist role or tell the player what they must do.

Sample voice: "Every legend started at Level 1. Except me. I started at Level 2. Long story."

## Capitalisation

Follow the usual game convention:

- **Title Case** for anything that is a name or a label: buttons, menu items, screen and dialog titles, section headings, setting names, stat names, exercise, quest, item, enemy and event names, and result banners ("Back to the Guild", "Power Strike", "Expedition Complete!", "Sound Effects", "Wall Push-Ups"). Keep short articles, conjunctions and prepositions ("a", "the", "and", "of", "to", "for", "with", "from") lowercase unless first or last.
- **Sentence case** for sentences: descriptions, hints, helper text, dialogue and log lines ("Move slowly and keep your neck relaxed.").
- Units and rewards read as a label: "+40 XP", "+2 Energy", "+8 Coins". "LEVEL UP!" is the one all-caps celebration.
- Screen-reader labels are plain sentences.

## Never write

- Guilt, shame or pressure: "You missed yesterday", "Don't break your streak", "Lazy", "Weak", "No excuses".
- Body talk: comments on weight, size, shape, "getting in shape", "burning off" food, before/after framing.
- Comparison with other people or with an ideal.
- Medical claims or promises of health outcomes.
- Urgency tricks, countdown timers, or fear of missing out.
- Technical words the player has no reason to know: JSON, database, API, checksum and the like. Say what it does ("Copy a Full Backup", "Restore From a Backup") and keep the technical names in code and docs. `test/plain_words_test.dart` scans the text on every screen, the guide, Chad's lines, reminders and ideas for them.

Reminder notifications follow the same rules, and more: they are off until the player turns them on, never mention streaks, missed days or anything not yet done, never count, compare or sell, and are only ever an invitation ("come by if you feel like it"). Their lines live in `ReminderCopy` and `test/domain/reminders_test.dart` lints them.

The dialogue tests (`test/domain/quests_test.dart`) lint every one of Chad's lines against the banned words above, and check that each is a short, finished sentence and that every region has setting-out tips. They are a safety net, not a substitute for judgement.

## Always include

- Easier options. Every exercise has a gentle starting point, and easier variants earn the same as harder ones.
- "Stop if anything hurts" wherever exercise is introduced or logged.
- A clear separation between game feedback and professional health advice. The game cannot verify workouts and must not imply it can.
- Rest as a valid, valued choice. Rest days never reduce progress.

## Story

The story ([STORY.md](STORY.md)) follows the same rules as everything else, and `test/domain/story_test.dart` lints it. In addition:

- It is warm and funny, and the joke is never on the player's body, effort or pace. Chad is the one who gets teased.
- Nothing in it is timed. No chapter is "limited", "missed" or "overdue", and a chapter that is not open yet says which level opens it, not how far behind anyone is.
- Choices have no wrong answers and change no rewards. Every option gets a kind reply.
- Rest, a slow pace and saying "not today" are shown as ordinary and sensible, including by the characters who were once sure otherwise.
- The player can always skip, leave, or read it again.

## Daily quests

The quest board suggests three quests a day, rotated from a pool for the player's experience level (`QuestBoard` in `lib/domain/quests.dart`, 17 to 18 each). They are suggestions, never obligations, and nothing is lost for ignoring them. When adding one, `test/domain/quests_test.dart` requires that:

- it asks only for what its activity measures (sets, reps or time), with a variant that exists;
- it needs nothing beyond what most homes have (a chair, a wall), or is flagged as needing dumbbells and skipped for players without them;
- the order keeps any three neighbours in different categories, so a day is never three of the same thing;
- beginner quests stay gentle (at most two sets, ten reps and ten minutes);
- the words are kind and each description is one finished sentence.

Beside the board, **Try Something Today** (`Recommendations` in `lib/domain/recommendations.dart`) offers three ideas: one that goes with a quest on today's board (from a different part of fitness, so a day is balanced), and exercises the player has not logged before, with an old favourite that has had a rest of two weeks or more when little is new. They are ideas, not tasks, and `test/domain/recommendations_test.dart` requires that:

- they only use what most homes have (dumbbells only for players who have them), and nothing too demanding for someone just starting;
- the same day always gives the same list, even after one of them is logged (what counts as new is judged from before today), and other days give other lists;
- none repeats a quest already on the board, and the new ones are spread across kinds of exercise, the player's preferred kinds first;
- each suggests a gentle amount (the easiest version unless the player is already active) and the words never mention what has not been done, only offer: "Goes well with ...", "Something new to try", "An old favourite, if you fancy it".

On the log screen a button, **Fill In Last Time's Numbers**, copies the sets, reps, weight, time, distance and version from the last entry so a repeated session is not retyped (notes, effort and the camera mark stay behind, and it is not offered while editing).

At the top of the Train screen, **Do It Again** lists the last four different exercises (`RecentExercises` in `lib/domain/records.dart`, `DoItAgainShelf`), each with its last numbers and date. Tapping one opens the log screen with the same sets, reps, weight, time, distance and version filled in, so a repeated session is one tap and a save; notes, effort and the camera mark are not carried over, and everything can still be changed. It appears only once something has been logged, never mentions what was not done, and never changes a reward.

For anything the player has done before, the suggestion and the log screen show **their own marks** (`ExerciseRecap`, `PastMarks`): the last time, on how many days, and their personal bests, each opening its progress line. They are only for looking back on and never change a reward.

Below the weekly goal, the board also looks back at **last week** (`WeeklyRecap` in `lib/domain/recap.dart`): active days against the player's own goal, effort minutes and what they logged most, with a line from Chad. It describes only the player's own week, never compares it with anyone or with an earlier week, counts only workouts logged on the day (as the goal does), calls a quiet week a rest week, and stays hidden until there is history from before this week. `test/domain/recap_test.dart` lints the words.

## Enemies

Enemies are whimsical obstacles such as a sleepy slime or a gear golem. They must not personify the player's struggles with their body, weight, laziness or failure.

## Rewards and mechanics

- Streaks are allowed only in the forgiving form in [Reward rules](REWARD_RULES.md#streaks): rest days are built in, rewards pay for showing up and never for doing more, nothing already earned is ever taken back, and the text never speaks of loss or pressure ("Don't break your streak" is still banned). No daily login rewards and no countdowns.
- Rewards are capped per day so exercise is never pushed beyond what is healthy for the reward.
- Rewards never depend on weight lifted, pace, body measurements or "perceived effort".
- Everything that affects play is paid for with coins earned through play, never with real money. No gacha, loot boxes or random purchases, no paid XP or energy, and nothing is sold that makes the game easier to win by spending rather than exercising (potions and gear are small, bounded and priced in coins).
- Real money buys only looks and thanks, and only in the Patron's Hall (see [Monetization](MONETIZATION.md)). The only ad is one at the start of a story chapter (Premium removes it), and story is never sold. No other ads, no analytics or tracking SDK, no subscriptions, no countdowns or limited-time offers, no "best value" or strike-through prices, no purchase prompts after a workout, win, loss or level-up, and no text that makes someone feel lesser for not buying. Cosmetics have no stat, bonus or reward fields, free and earned looks always sit beside paid ones, and the words in the Patron's Hall are linted like the rest of Chad's.
- Any number the player sees (XP, energy, damage) should be explainable, and any new term or rule belongs in the in-game guide (`lib/domain/guide.dart`, shown from Settings as "How the Game Works"). The guide reads its numbers from the rules, and its tests fail if a region or an enemy move is missing from it.

## Accessibility checklist for new UI

- [ ] Works with large system text without clipping; content scrolls.
- [ ] Contrast is sufficient in light and dark themes.
- [ ] Meaning is never carried by colour alone (add text or an icon).
- [ ] Interactive elements have at least 48 px touch targets and semantic labels.
- [ ] Animations respect `MediaQuery.disableAnimations` and are not required to understand state.
- [ ] Usable one-handed: primary actions are reachable near the bottom of the screen.
- [ ] Sessions are short; nothing requires sustained attention to avoid losing progress.

## Privacy

- Collect only what a feature needs. Onboarding asks experience level, preferred categories and whether the player has dumbbells, nothing about body measurements, age or health conditions.
- No public body measurements, leaderboards, or compulsory social features.
- Local export and deletion must always work.
- No analytics SDK, and no advertising anywhere except the single ad at the start of a story chapter ([Decision 33](DECISIONS.md#33-one-ad-at-the-start-of-a-story-chapter-and-premium-removes-it)), without a new decision first. The network is used by the platform store (when the Patron's Hall is open or a purchase is being delivered), by a one-time, player-chosen download of a later story season (a plain request for a static file, nothing about the player sent), and by that one ad, which is requested non-personalized and family-friendly after the player's choices where the law requires, and never for Premium owners.
- Any future health integration (HealthKit, Health Connect) requires an explicit permission screen explaining what data is read and why.

## Art, audio and licensing

- Use original assets or assets with documented commercial licences. Today everything is original: characters, props and backdrops are drawn in code (`lib/game/art`), and the sound effects are synthesized by `tool/gen_sfx.mjs`. If any third-party asset is added, record its source and licence in `docs/ASSET_LICENSES.md` first.
- Chad is an original character. Do not reproduce recognisable meme photography or third-party characters.
- Offer a range of appearances (hair styles, outfit colours and six skin tones) and never tie a body type or skin tone to any in-game value or role.
- Audio should reward effort without overwhelming the workout. It must be mutable and never required.
- Exercise demonstrations are original animations drawn in code (see [Game scenes](GAME_SCENES.md)). Each has simple form cues and points to easier versions, and cues must stay conservative: no "push through the pain", no promised results. Any new demo needs a professional's review before release where possible.

## Title

"I Am Chad" is a working title. Trademark clearance is pending (GDD section 16). Avoid building the name into assets that are hard to change.
