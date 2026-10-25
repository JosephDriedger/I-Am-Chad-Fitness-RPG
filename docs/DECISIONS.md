# Decision log

Short records of choices that shaped the codebase, so the reasoning is not lost. Add a new entry when you make a decision that someone might later want to reverse. Newest entries go at the bottom.

## 1. Flutter, Riverpod and Drift

**Decision:** Flutter and Dart for the app, Riverpod for state, Drift on SQLite for storage.
**Why:** Taken from the GDD's technology direction. Flutter gives one codebase for Android and iOS; Drift gives typed, reactive, offline-first storage; Riverpod makes dependencies explicit and testable through provider overrides.
**Consequence:** Drift needs code generation (`build_runner`).

## 2. Game rules are pure Dart

**Decision:** Rewards, combat, expeditions, quests and dialogue live in `lib/domain` with no Flutter or database imports.
**Why:** The GDD asks for testable domain logic and deterministic seeds. It also means a future Flame scene or a backend can reuse the same rules.

## 3. Rewards are derived per day, not stored as a running total

**Decision:** The `workouts` table is the source of truth. Each local day's XP and energy is computed from that day's workouts and stored in `reward_grants` with the rules version.
**Why:** Editing or deleting a workout must keep the game consistent without hand-written reversals. Stamping the rules version, and recomputing only touched days, means rebalancing never rewrites untouched history (GDD section 10).
**Alternatives considered:** An append-only reward ledger (harder to keep correct on edit and delete), or recomputing everything on every read (silently rewrites history after a rebalance).
**Consequence:** Energy available is `earned − spent`, clamped at 0, so deleting a workout after spending its energy cannot go negative.

## 4. Daily cap with diminishing returns, no daily-login rewards

**Decision:** Full value for the first 20 effort minutes of a day, half for the next 20, nothing after. No daily login rewards or countdowns. (This decision originally also ruled out streaks; see [decision 28](#28-forgiving-streaks).)
**Why:** The GDD forbids punishment and compulsion, and warns about overexercise for rewards. A cap bounds the incentive; the half-value band avoids a hard cliff.
**Consequence:** Maximum 120 XP and 6 energy per day. See [Reward rules](REWARD_RULES.md).

## 5. Variants, load and perceived effort never affect rewards

**Decision:** Easier variants earn exactly the same as harder ones, and weight lifted does not matter.
**Why:** "A player doing a smaller or modified workout should still receive meaningful progress" (GDD 5.3), and heavier loads should not be rewarded for their own sake.

## 6. A minimum of 3 effort minutes per entry

**Decision:** Any valid entry is worth at least 3 effort minutes.
**Why:** Two sets of wall push-ups would otherwise be worth almost nothing, which is discouraging for exactly the players the game is for.
**Trade-off:** It is slightly gameable by logging many tiny entries; the daily cap limits the effect. Noted as a known gap.

## 7. Hand-written PRNG

**Decision:** `GameRng` implements mulberry32 instead of using `dart:math` `Random`.
**Why:** The sequence for a seed is guaranteed identical across platforms and Dart versions, so saved seeds and test expectations stay valid.

## 8. Enemy intent is always visible

**Decision:** The UI shows whether the enemy will strike or wind up a heavy blow before the player acts.
**Why:** It makes short fights a readable tactics puzzle on a phone and supports "difficulty through tactics" (GDD 6.3). It also lets guarding feel meaningful.

## 9. Failure keeps rewards; practice is free

**Decision:** Losing or retreating from an expedition keeps XP and coins from battles already won. A free practice duel always exists.
**Why:** Progress without punishment, and something to play on a rest day.

## 10. Flame for the game scenes

**Decision:** The guild hall and the battles are Flame scenes. Menus, HUD, forms and the older list screens stay Flutter widgets.
**Why:** The first prototype was a widget app with a combat screen, which did not feel like a game. Scenes give characters that move, hit effects, camera shake and a world to walk around, while Flutter widgets keep text, forms and accessibility simple.
**Consequence:** Scenes take plain data and call back out. They never touch providers or the database, and `BattleEngine` stays the single source of truth for outcomes.

## 11. Generated code is not committed

**Decision:** `*.g.dart` is git-ignored; `dart run build_runner build` regenerates it.
**Why:** Avoids noisy diffs and merge conflicts in generated files.
**Trade-off:** A fresh clone needs one extra command (documented in the README).

## 12. Store metric, display in the player's units

**Decision:** Distance and weight are stored in metres and kilograms; the Settings unit switch only changes input and display.
**Why:** One canonical unit avoids conversion drift and makes data export unambiguous.

## 13. Android and iOS only

**Decision:** Only the Android and iOS platform folders were generated.
**Why:** The GDD targets those two platforms. Other platforms can be added with `flutter create --platforms=...` if needed.

## 14. All art is drawn in code and all sound is synthesized

**Decision:** Characters, props and backdrops are canvas shapes (`lib/game/art`). Sound effects are generated by `tool/gen_sfx.mjs`.
**Why:** No asset budget or licensing questions at this stage (the GDD flags both), everything can animate and be recoloured, and the repo stays small.
**Trade-off:** A hand-made art pass will eventually look better. Because scenes only use `ActorComponent` and a painter function, sprites can replace painters one at a time.

## 15. Battle events are structured, and scenes only play them back

**Decision:** `BattleEngine.act` returns typed `BattleEvent`s along with the text log. `BattleScene.play` animates them and then snaps the bars to the engine's final numbers.
**Why:** Animation can never change an outcome, tests can assert on events without a renderer, and the same events could drive replays.

## 16. Real exercise is the only source of adventure energy

**Decision:** Battles do not ask the player to move, and nothing in the scenes grants energy.
**Why:** It keeps the fitness promise honest and the reward rules in one place. See [Reward rules](REWARD_RULES.md).

## 17. Hero appearance includes skin tone, with a real migration

**Decision:** Schema version 2 adds `appearance_skin` (six tones) plus sound and vibration settings, with an `onUpgrade` step and a test that upgrades a real v1 save.
**Why:** Once the hero is drawn on screen, a single skin tone would exclude players. Adding it also set the precedent that upgrades must preserve workout history.

## 18. HUD in screen space, scene in design space

**Decision:** Battle bars and names are drawn in the camera's viewport layer; the stage itself uses a fixed design resolution that zooms to fit.
**Why:** On tall phones a world-space HUD floated in the middle of the sky. Screen-space bars hug the top edge on any device, and backdrops that overdraw the design area avoid letterbox bars.

## 19. Web is enabled for development previews only

**Decision:** The web platform and `sqlite3.wasm` were added so scenes can be reviewed in a browser. The shipped targets remain Android and iOS.
**Why:** The dev machine has no Android emulator, and visual work needs eyes on it. Preview modes (`--dart-define=PREVIEW=...`) jump to scenes with a seeded hero.

## 20. Exercise demonstrations are drawn with a jointed figure, not video

**Decision:** Each exercise has an animated figure with fixed limb lengths and IK-planted hands and feet, plus cues that follow the motion. It follows the chosen variant and wears the player's look.
**Why:** The GDD asks for original or licensed demonstrations with form cues and easier alternatives. Drawing them in code avoids licensing, keeps the app small, shows variants accurately, and lets tests prove the figure never breaks (limb lengths, floor contact, smooth motion).
**Trade-off:** A stylised figure shows movement, not fine technique. The cues carry the detail, and a professional review is on the roadmap.

## 21. Title Case for labels, sentence case for sentences

**Decision:** Buttons, menu items, screen and dialog titles, headings, setting and stat names, and exercise, quest, item, enemy and event names use Title Case. Descriptions, hints and dialogue stay in sentence case.
**Why:** It is the usual convention in games and reads as part of the game world. The rule and examples are in [Content guidelines](CONTENT_GUIDELINES.md).

## 22. Reward popups wait for the saved data

**Decision:** When you return to the guild hall, it polls briefly (up to 1.5 s) for the new XP, energy or coins before playing the celebration, and the popups draw above everything.
**Why:** The first version read the player's status the instant the page closed, before the database stream had delivered the new values, so the celebration never ran. A widget test now fails if no popup appears after logging a workout.

## 23. An in-progress expedition is saved at the start of every step

**Decision:** A single `active_expeditions` row (schema version 3) holds the seed, hero level, step, HP, potions, battles won, XP and coins. Starting an expedition spends the energy and writes the row in one transaction. The expedition itself is regenerated from the seed, and the run's random numbers are re-seeded from the seed and step, so a restored run matches an uninterrupted one. Finishing or abandoning clears the row. Leaving mid-run offers Keep Going, Leave and Come Back Later, or Retreat, and Adventure shows a Resume card.
**Why:** Closing the app used to lose the run after its 2 energy was spent, which punishes real life interrupting a workout day. Saving only at step boundaries keeps the data tiny and a mid-battle restart simply replays that fight, so nothing can be exploited by killing the app.

## 24. Every screen is a game screen

**Decision:** Non-scene screens use a shared kit in `lib/app/game_ui.dart` (parchment, wood and gold; panels, chips, buttons, dialogs and route transitions) and one bundled display font, Lilita One (SIL Open Font Licence, licence file in `assets/fonts`). The app has a single light "game" theme, ignores the system dark mode, and opens on a title screen that greets a returning hero.
**Why:** The request was for more of a game and less of an app. Stock Material lists and dialogs undermined the guild hall and battle scenes. A kit keeps the look consistent and cheap to change. `GamePanel` wraps its content in a transparent `Material` so list tiles inside it do not trip Flutter's ink assertions.

## 25. An honesty check, never a lock

**Decision:** Entries whose numbers look unlikely (an impossible pace, an impossible rep count, far less than the paid minimum, a pile of tiny entries) trigger a friendly warning, live and again at save. The player can fix the entry or confirm it, and rewards are never reduced. Details in [Reward rules](REWARD_RULES.md#honesty-check).
**Why:** The game cannot verify exercise, and a lock would punish typos and anyone doing something unusual. Reminding the player that only they know, and that the log is for them, fits the promise that the game never shames. Generous limits keep false alarms rare.

## 26. Camera rep counting is on-device, optional, forgiving and counts only

**Decision:** Push-ups and squats can be counted with the phone camera. Pose detection runs on the device (ML Kit), frames are dropped after use and nothing is stored or sent. Counting is a pure-Dart state machine over joint angles (elbow or knee) with hysteresis, smoothing and a minimum time between reps. How much range of motion counts depends on the hero's experience level (beginner, gentle, standard), and easier variants (wall and incline push-ups) need less. The camera only counts and gives generic cues such as "a little lower and it counts"; it never grades form. Camera-counted reps earn exactly what typed reps earn, are marked in the journal, and skip the honesty check. The player is assumed to own a phone stand, and the screen teaches the set-up.
**Why:** It makes the log more authentic without a lock, and the leniency keeps beginners from being told they did it wrong. Keeping it optional and equal in rewards protects people without a stand, a quiet space or comfort on camera. Judging form from one camera is unreliable and could discourage or mislead, so it is left out until a professional can advise.
**Trade-off:** The camera layer is thin and can only be verified on real phones, so tuning will need real-world testing. The geometry and counting are fully unit tested instead, using synthetic poses.

## 27. A large, searchable catalog with data-driven animation

**Decision:** The catalog grew from 11 to 79 exercises across six categories (Core and Sports & Play are new), each tagged with the equipment it needs. The Train screen gained search, category chips and an At Home Only switch. Every new exercise has an animated demo built from a small keyframe rig on top of the existing IK, rather than hand-coded poses, and a tool renders contact sheets so each one was checked by eye. Easier versions are described in text (and as variants where there is a distinct demo), and all earn exactly what harder ones do.
**Why:** People log very different things, and the original eleven left out most of what a beginner at home, a gym regular or a casual sports player actually does. The rig keeps limb lengths, floor contact and smooth loops true by construction, and the existing demo tests then cover the whole catalog. Search and filters keep a long list usable, and "At Home Only" respects people without equipment.
**Trade-off:** A side-on 2D figure cannot show every move honestly, so a handful are drawn face-on and say so. The demos and cues are original and conservative, but they still need review by a qualified trainer. Rewards use two simple numbers per exercise (seconds per rep, an effort multiplier) and tests keep them in a sane range, so no exercise is a shortcut to the daily cap.

## 28. Forgiving streaks

**Decision:** Streaks exist, in a deliberately gentle form. A streak is days active in a row with rest days built in (up to 2 or 3 quiet days by experience, always covering a weekend off). Rewards are one-time coin and XP milestones from 3 days to a year, paid once and never taken back. A lapse restarts the count, keeps the best run, and is met with kind words, with no countdown and no "don't break it" messages. The streak shows on the hall HUD, the quest board and the workout-saved dialog.
**Why:** Players asked for a reward for consistency, and consistency is something worth recognising. The original "no streaks" rule was about the harm that strict daily streaks do: pressure to train when tired, hurt or ill, and guilt after a missed day. Building rest days in, paying for showing up instead of doing more, and never removing anything keeps the benefit and removes those harms. This reverses part of decision 4; the daily cap, the no-login-rewards rule and the no-countdowns rule stand.
**Trade-off:** Any streak can still feel like pressure to some people, so the wording is kept calm, the rest allowance is generous, and the reward sizes are small next to a real day's exercise. If it ever tests badly with beginners, the first lever is a larger rest allowance, and the second is removing the HUD flame. Only workouts logged on the day they happened count toward a streak (see decision 29).

## 29. Back-dated workouts are for the journal only

**Decision:** A workout earns rewards (XP, energy, streaks, quests, the weekly goal) only if it is logged on the day it happened, with a 6-hour grace across midnight. Back-dated workouts are still saved to the journal but earn nothing, and the log screen says so. The time a workout was entered is recorded once and never changes, so editing a date cannot make an old workout count.
**Why:** Rewards are meant to follow real, recent effort. With free back-dating, a player could log a month of workouts in a sitting and claim every reward and streak milestone. Allowing the journal entry but not the reward keeps the record complete and honest, without punishing someone who forgot to log yesterday.
**Trade-off:** Someone who really did exercise yesterday and forgot to log it gets no reward for it. That is the point of the rule, and the message is kind. Changing the phone's clock still works, which cannot be stopped offline.

## 30. Coins buy gear and potions in a Guild Shop

**Decision:** Coins, which were collected with nothing to spend on, now buy gear (the existing eight items, cheaper starters and pricier upgrades) and healing potions in a Guild Shop reachable from the Hero and Adventure screens. Potions are kept in a pouch of up to 5, up to 3 come along on each expedition, and unused ones come home. Everything is priced in coins, nothing is random, and nothing is bought with real money.
**Why:** Coins had no use, which made expedition rewards and streak milestones feel hollow. Gear gives them a goal and potions a steady, repeatable sink that matters in battle. The prices follow what a player earns: starter gear in a few expeditions, upgrades as a longer goal, and a potion for about one expedition's coins.
**Trade-off:** This softens "loot is earned, never bought", so the guidelines now say coins are earned only through play and that purchases stay small, bounded and non-random. Combat is already easy, so the potion pouch and gear bonuses are kept small. Cosmetics and hall decorations are a natural next sink but need new art.

## 31. A story told in chapters that open with levels

**Decision:** Season One, "The Dawn Bell", is a prologue and seven comedic chapters (see [Story](STORY.md)). Chapters open at hero levels 1, 2, 3, 5, 7, 10, 13 and 16, are offered once per session in the hall, and can always be skipped, left or read again from a Chronicle on the Quests screen. A few choices are remembered and answered by later chapters. Progress and choices are two small tables (schema v7), included in the export and removed by Delete Everything.
**Why:** The game had a guildmaster and a world but no reason to care about either. A story gives levels a meaning that is not a number, and gives players who like it something to look forward to on a quiet day. Tying chapters to level rather than to days means nothing is timed, nothing can be missed, and a break from exercise costs nothing. Level only goes up, so what has opened never closes.
**Trade-off:** Story is a content treadmill: eight chapters last a few months of regular use, and then the season ends with "more is coming". Making more needs writing and a little art each time, and the script has to be kept kind, which is why tests lint every line. The scenes are drawn in code with the existing characters, so they are consistent but not as rich as hand-made art would be. Levels can also be reached quickly by someone who does a lot, so heavy users may finish early; that is fine, and the chapters can be read again.

## 32. Optional cosmetic patronage, and nothing else

**Decision (narrowed by [decision 33](#33-one-ad-at-the-start-of-a-story-chapter-and-premium-removes-it), which allows one ad at the start of a story chapter and a Premium that removes it):** The game earns money in exactly two optional ways, both through the platform store and both reached only from Settings > Patron's Hall: a one-time **Patron Pack** of cosmetics (three mantles, four hair dyes, guild-hall decorations) and three **tips** that are only a thank-you. The whole game stays free, with no ads, no analytics, no account, no subscriptions, no randomness, no timers and no purchase prompts anywhere else. Money never buys XP, energy, coins, potions, gear, story or any advantage. Prices come from the store, purchases are saved locally and restorable from the store account, and a purchase is confirmed to the store only after it is saved. The full list of promises, the products and the store set-up are in [Monetization](MONETIZATION.md).
**Why:** The project needs a way to pay for itself, and the pillars rule out the usual ones: ads sell the attention of someone trying to exercise and need tracking, energy or XP sales would break "real exercise is the only source of adventure energy" ([decision 16](#16-real-exercise-is-the-only-source-of-adventure-energy)), loot boxes and timers are exactly the compulsion the GDD forbids, and subscriptions charge people who may stop exercising for a while. Cosmetics and thanks are the model with the least conflict: a looks-only pack gives supporters something nice, a tip jar lets people give without receiving, and neither makes anyone who does not pay worse off. It also supports the privacy promise, because the only party that ever sees a payment is the store.
**Trade-off:** This earns less than an aggressive model would, by design. To keep paid looks from feeling like status, the game has free and earned looks beside them (the Dawn Mantle, two hair dyes and ten hall pennants can only be earned), and the pack is a single modest price. There is no server, so purchases are trusted as the store reports them; that is acceptable only because cosmetics have no effect on anyone else, and it would have to be revisited before anything social or competitive exists. This also loosens [decision 30](#30-coins-buy-gear-and-potions-in-a-guild-shop) slightly: "nothing is bought with real money" now means nothing that affects play is.
**Consequence:** Schema v8 adds `purchase_receipts` and the hero's chosen `cape` and `hair_dye`. The store SDK is behind `StoreGateway`, so tests and the browser preview use a pretend store, and the real checkout needs the placeholder application id replaced and products created in both consoles before anything can be bought. Changes that touch gameplay, add an ad or tracking SDK, add a subscription, random reward, bought currency or limited-time offer, or surface a purchase prompt outside the Patron's Hall need a new decision first.

## 33. One ad at the start of a story chapter, and Premium removes it

**Decision:** The game now has exactly one kind of advertising: a single full-screen ad (Google AdMob) at the very start of a story chapter, before its first line, the first time the player reads that chapter. It is never shown during or between workouts, rewards, battles, the shop, the hall or onboarding, never in the middle of a story, and not when a chapter is read again. If no ad can be shown for any reason, the story just begins. **Premium** (`premium_no_ads`, one-time, restorable) removes it for good. **Stories are never sold:** no chapter or season is behind a payment, and Premium gives nothing but the removal of that ad. Season Two, The Lantern Coast, is free like Season One, which replaces the earlier idea of selling it.
**Why:** The owner wants revenue without discouraging anyone from using the app and working out, and a paywall in front of the story would do exactly that. A single ad at a calm, optional-feeling moment (the start of reading, never during effort) is the least intrusive place for one, and a one-time Premium is the honest way to be rid of it. This narrows [decision 32](#32-optional-cosmetic-patronage-and-nothing-else), which said no ads at all.
**Trade-off:** This gives up the "no ads, no network" promise. The ad SDK collects device and advertising identifiers, so the privacy wording, store disclosures and a privacy policy must say so, and the ad is requested non-personalized and family-friendly (G) after the player's consent choices where the law requires them, with **Ad Privacy Choices** in Settings. Advertising to children is regulated, so the audience is fixed in [decision 34](#34-the-game-is-for-teens-and-adults-and-its-ads-are-family-safe) before any real ad is switched on. Ad income is also small next to the cost of making the stories.
**Consequence:** `AdGateway` (`lib/app/ads.dart`) keeps the SDK in one file; tests use `TestAdGateway`. `AdPolicy` never shows an ad before it knows whether the player has Premium, and never to Premium. `test/ads_promise_test.dart` fails if the SDK or `showChapterAd` appears anywhere but `ads.dart` and the story screen. The ad ids in the app are Google's public test ids until an AdMob account exists. Anything beyond this one ad needs a new decision.

## 34. The game is for teens and adults, and its ads are family-safe

**Decision:** The game is aimed at **teens and adults (13 and over)** and not at younger children. The stores' target audience and age rating are set to match (Google Play: 13 and over only, outside the Families programme; App Store: 12+ or 13+). Ads, which exist only as in [decision 33](#33-one-ad-at-the-start-of-a-story-chapter-and-premium-removes-it), must never be adult-themed: they are requested at the most restrictive content rating (G), non-personalized, with no child age-treatment signal, and the AdMob account blocks every sensitive category (dating, gambling, alcohol, politics, religion, sexual and reproductive health, get-rich-quick, drugs and supplements) and weight-loss and diet ads.
**Why:** The owner wants the audience to be teens and adults, which settles the question the ads raised (rules on advertising to children apply to apps aimed at younger children), and wants the game to stay a comfortable place for a 13-year-old and a 40-year-old alike. Weight-loss and diet ads are blocked in particular because the game never talks about bodies (see the [content guidelines](CONTENT_GUIDELINES.md)).
**Trade-off:** Declaring a 13+ audience and requesting only G-rated ads narrows the advertisers available, so income per ad is lower. The app does not ask for an age (the privacy pillar), so it cannot check; it relies on the stores' ratings and controls and on Google's consent handling for under-16s in the EEA. If a store or the law asks for an age check, add a neutral "13 or older?" question at onboarding, and show no ads to anyone who is not.
**Consequence:** `AdMobGateway` sets `MaxAdContentRating.g` and keeps non-personalized requests, and `test/ads_promise_test.dart` fails if either is removed or loosened, or if a child-directed tag is added. The blocking controls live in the AdMob console and cannot be tested from the code, so they are an explicit release step in [Monetization](MONETIZATION.md#setting-it-up-in-the-stores).

## 35. Six regions, enemy tactics and forks, tuned by a scripted player

**Decision:** Expeditions happen in one of seven regions (Meadowmere to the Starlit Isles), each opening at a hero level and staying open for good, with its own enemies, bosses, camps, scenery and gear. Difficulty rises through enemy **tactics** (heavy blows, flurries, bracing, mending, bosses that get fired up) that the game always announces a turn ahead, not through stat inflation, and the player can always drop back to an easier region. At a **fork in the road** the player picks one of two ways, each with an ordinary camp's effect. Practice duels pay nothing.
**Why:** The first prototype was too easy for a sensible player (about 98% wins at higher levels) and had nothing new to meet after the first few expeditions. Tactics give a puzzle rather than a bigger number, and keeping every region open means nobody is ever walled out of progress or punished for choosing an easier fight.
**Trade-off:** More content to keep consistent, and the numbers are tuned against a script, not people. Enemy attack is rounded to whole numbers, so some dials move win rates in big steps. Forks made sensible play about 10 points easier and forced a re-tune.
**Consequence:** `test/domain/balance_test.dart` plays 250 seeded expeditions per case in every region with a scripted sensible player and fails if the first region is not gentle, any region is a wall, a region is not harder than the one before, a step is a cliff, or a battle runs too long. It is a regression guard, not proof of fun: real playtesting is still the next tuning step (see [Roadmap](ROADMAP.md)). Chad teaches each region's enemy moves as a tip when setting out, and a test requires tips for every region.

## 36. Earned looks sit beside paid ones, and trophies are for the long haul

**Decision:** Every kind of look has free or earned choices beside the paid ones: a mantle for finishing each story season, hair dyes at levels 5 to 40, ten pennants on the bunting, and six trophies on the Journal bookshelf for the biggest milestones (the later season finales, levels 40 and 50, 25 expeditions, a 90-day streak).
**Why:** Decision 32 promised that paying never makes a hero look more accomplished. Earned looks are how that stays true as paid ones are added. Trophies and pennants are derived from progress the game already tracks, so they need no new saved data and can never be lost.
**Trade-off:** The bunting has ten slots and is full, so more bunting milestones would need more slots.
**Consequence:** `Cosmetics.trophies`, `earnedTrophies` and the tests in `test/domain/patronage_test.dart` keep these earned-only, never sold, and tied to the right chapters.

## 37. The game explains itself in plain words, and first-use help stays small

**Decision:** A permanent in-game guide, "How the Game Works", explains every term the game uses (effort minutes, energy, regions, enemy moves, and so on). Its numbers are read from the rules, so it cannot drift, and tests fail if a region or an enemy move is left out. First-time players get a one-line Chad welcome on Train and a compact "Your First Log" card, both gone for good after the first save. Chad also offers an optional one-minute warm-up that pays nothing and saves nothing.
**Why:** The roadmap flagged "effort minutes" and "energy" as terms beginners might not understand, and a few bullets shown once at onboarding cannot be reopened. Guidance has to help without getting in the way: a first, taller version of the log card pushed the effort fields below the fold, which showed up as 14 failing tests, so it was made compact.
**Trade-off:** Another place to keep in step with the rules, which the generated numbers and tests are there to make cheap. The warm-up was first left out of the first launch to avoid an extra step; [decision 42](#42-the-warm-up-is-offered-once-in-the-hall-until-the-first-workout) later added a single optional offer in the hall.
**Consequence:** New terms and rules belong in `lib/domain/guide.dart` (see [Content guidelines](CONTENT_GUIDELINES.md)).

## 38. Reminders are opt-in, rare, and run out by themselves

**Decision:** The game can send gentle reminders, but only if the player turns them on in Settings. They choose the weekdays (Monday, Wednesday and Friday to begin with) and an hour between 8 AM and 9 PM. At most one a day; none on a day the player has already moved; none for the rest of a week whose goal is met; and never any wording about streaks, missed days or what has not been done. The game plans only a fortnight ahead each time it opens, so if someone stops opening it, the reminders stop on their own. Permission is asked only at the moment the switch is turned on, and a "no" is answered kindly and leaves it off.
**Why:** Notifications are the usual place where a friendly game turns into a nag, and the pillars rule that out (see [decision 28](#28-forgiving-streaks) and the [content guidelines](CONTENT_GUIDELINES.md)). Making the limits part of the rules, with tests, keeps them from loosening later. The fortnight horizon means the worst case for a player who drifts away is a few kind messages and then silence, and nothing escalates or "wins them back".
**Trade-off:** A fixed schedule is less clever than one that learns when someone usually moves, and a planned reminder can still arrive after they have moved if they log it from another day's plan; the game replans on every launch and every logged workout, which covers the common cases. Reminders cannot be sent by a phone with notifications switched off, and that is respected.
**Consequence:** The rules, wording and planner are pure Dart in `lib/domain/reminders.dart`. Delivery is behind `ReminderGateway` (`lib/app/reminders.dart`); the default sends nothing, and Settings does not show the switch where nothing can be sent, so the game never offers what it cannot do. The real delivery (`LocalReminderGateway`) schedules inexactly, so no exact-alarm permission is needed and a reminder may arrive up to an hour late; it asks for permission only when the switch is turned on, and shows nothing while the game is open. Schema v12 stores the three choices, included in Delete Everything. Anything that adds more frequent, unprompted or escalating messages needs a new decision first.

## 39. Later story seasons are downloaded once, from static files

**Decision:** Season One is part of the app. Seasons Two and later are downloaded, one small file per season, the first time the player reads a chapter of them, in the way Shadow Fight 2 fetches new content: a card states the size, a button starts it, a bar shows progress, the chapter opens when it is done, and the file stays on the phone. The app carries each chapter's place, title, level and summary, so unlocks and the Chronicle never depend on a download, and only the scripts are downloaded. They come from a folder of static files (a manifest and one JSON file per season, published with GitHub Pages by default), checked by size and SHA-256 and validated before being kept. See [Content packs](CONTENT_PACKS.md).
**Why:** The owner wants a small first install so players always have storage for the game, and the same pattern for later content. Store-run asset packs and Flutter deferred components were considered: they need separate work for each store, or are Android-only and built for code. Static files are one implementation for both platforms with no server of ours.
**Trade-off:** The game now uses the network a third way, so the privacy wording, the guide and the store disclosures say so. It sends nothing about the player, but it is no longer true that only the store and the ad touch the network. New art (a character or a place) still needs an app update, because packs carry only words and choices. Someone offline when they first reach a new season cannot read it until they are online once, and a season that has not been published yet says so kindly. Today a season is about 30 KB, so the storage saving is small; the pattern is in place for when art and audio grow.
**Consequence:** `Story.chapters` is a catalog with no scripts for downloaded seasons; the scripts are in `tool/story_content` and are not compiled into the app. `docs/packs` is built by `dart run tool/build_packs.dart` and a test fails when it is out of date. Tests that read later seasons read them through `StoryContent`, and `bootApp` installs a pretend pack source. Anything that makes a download automatic, background, personalised or paid needs a new decision first (stories stay free, [decision 33](#33-one-ad-at-the-start-of-a-story-chapter-and-premium-removes-it)).

## 40. Daily ideas go beside the quests, and familiar exercises show the player's own marks

**Decision:** Below the quest board, "Try Something Today" offers three ideas: one that goes with a quest on today's board, and exercises the player has not logged before (an old favourite after two weeks of rest if little is new). They fit the player's equipment and level, are the same all day and change by day, and suggest a gentle starting amount. For anything the player has done before, the idea card and the log screen show their last time, on how many days, and their personal bests, each opening its progress line.
**Why:** The board gives three quests from a fixed pool, so someone could do the same few things for months and never meet most of the 79 exercises. Pairing one with a quest keeps a day balanced without a plan, and "new to you" widens what they try. Showing their own marks when they pick something familiar answers "where was I?" at the moment it helps, and rewards looking back rather than pushing.
**Trade-off:** More on the Quests screen and the log screen, though both parts appear only when there is something to show. "New" is judged from the journal, so a first-time player sees every idea as new, and an exercise logged on another phone before a restore is not known. The marks are never a target, a percentage or a comparison, and never change a reward, which keeps [decision 29](#29-back-dated-workouts-are-for-the-journal-only) and the reward rules intact.
**Consequence:** `Recommendations` and `ExerciseRecap` are pure Dart with tests, including a lint of the wording. Equipment that most players may not own, and exercises that are too demanding for beginners, are never suggested. Changes that add pressure, counts, streak talk or rewards to an idea need a new decision first.

## 41. A full backup the player can restore, kept by the player

**Decision:** Settings can copy a full backup of the game as JSON and restore from a pasted one. The backup holds everything about the player and leaves out the device's own preferences. Restoring shows what the backup holds, asks first, replaces the game in one transaction and rolls everything back if any part cannot be stored. A backup that is not this game's, is from a newer version, or holds anything unexpected is refused before anything changes.
**Why:** The game has no account, so the phone is the only copy: a lost or replaced phone meant losing the hero and all the history. The old "Copy My Data" export was a readable summary that could not be restored, which a player could easily mistake for a backup. A pasted JSON keeps the no-account, no-server promise: the player chooses where it lives (a note, an email to themselves).
**Trade-off:** Pasting a few hundred kilobytes of text is clumsier than a file or a cloud sync, and the backup is plain text, so anyone who sees it sees the player's workouts. The text says what it is for. Restore replaces rather than merges, because merging two games' rewards, streaks and gear would need rules that could surprise people. Purchases' receipts are in the backup but the store account remains the real record ([decision 32](#32-optional-cosmetic-patronage-and-nothing-else)).
**Consequence:** `Backup` (`lib/data/backup.dart`) and `GameRepository.backupJson`, `readBackup` and `restoreBackup`. A new table must be backed up or named a device table (a test enforces it). The share sheet and file chooser were added next, because pasting a long block of text is not something every player can do: "Save or Send a Backup" shares a plain text file and "Choose a Backup File" reads one, with copy and paste kept as the fallback. They use `share_plus` and `file_picker` behind `BackupFiles`, need no storage permission (the system's own share sheet and chooser do the work), and send nothing anywhere the player does not choose. Encrypted backup would be the next step and needs a new decision.

## 42. The warm-up is offered once, in the hall, until the first workout

**Decision:** When the hall appears for a player who has not saved a workout, Chad asks once per launch whether they want the one-minute warm-up. "Warm Up" opens it; "Not Now" closes the question and changes nothing, and the warm-up stays on the Train screen. The offer stops for good when the first workout is saved, and it never appears for anyone who has logged before (including after a restore).
**Why:** [Decision 37](#37-the-game-explains-itself-in-plain-words-and-first-use-help-stays-small) left the warm-up out of the first launch to avoid an extra step. A single, easily declined question in the hall is a lighter way to get it in front of beginners than an onboarding page, and it is the moment a first-timer is least sure what to do.
**Trade-off:** It is not remembered between launches, because remembering would need a new saved flag (a schema change and a backup field) for a one-line question. Someone who keeps declining and never logs a workout sees it again on each launch. If that ever reads as nagging, store the answer then.
**Consequence:** `HubScreen._maybeOfferWarmUp`, the words in `FirstSteps`, and `warmUpAutoOfferProvider` (off in tests unless `bootApp(warmUpOffers: true)`). Covered by `test/warmup_offer_flow_test.dart`.

## 43. The minimum-effort floor applies to three short entries a day

**Decision:** Reward rules move to version 2. Every entry is still worth at least 3 effort minutes, but only for the first 3 short entries of a local day (oldest first). A fourth or later entry under 3 minutes counts for its real length. Nothing else in the rules changes: the daily curve, caps, XP and energy are as before.
**Why:** Under version 1 about 14 two-rep entries filled the daily limit, which the honesty check could flag but not prevent. Three covers the honest cases (a few short mobility moves, a stretch, a quick set) and the cost to an honest player is nil, since a later short entry still counts for what it really was. The rule is never shown as a penalty: the explanation after saving simply says how short entries are counted.
**Trade-off:** It is a rule about quantity, so it can never be perfectly fair to someone who really does ten micro-sessions; those still earn their real minutes. The game still cannot verify a workout, and a clock change or a determined cheat can get around it. It is single-player and the daily cap bounds the effect.
**Consequence:** `RewardRules.v2` and `RewardRules.current` (new days use it; version 1 stays for tests and old days, which are only recomputed when touched, see Versioning in [Reward rules](REWARD_RULES.md)). Covered by `test/domain/floor_limit_test.dart`.

## 44. Each exercise has a page of its own, for looking back

**Decision:** The Journal has a "Your Exercises" list (most recent first, four shown until asked). Each opens a page with the days it was done and since when, how many days it was done in each of the last 8 weeks, the total weight lifted over those weeks when a weight was logged (weight × reps × sets), the player's marks (each opens its progress line), and the latest five entries, which open for editing.
**Why:** The roadmap kept "volume over time" open for weightlifting progression, and the Journal showed marks only as a flat list. A page per exercise answers "how am I doing at this?" without a dashboard.
**Trade-off:** Total lifted is the one number that could nudge someone to lift more, so it appears only when they have logged a weight, only as a plain total over the weeks shown, and always under the line that it sets no target and never changes a reward. A quiet week is drawn as a rest (a dash), never as a miss. Nothing compares the player with a target or with anyone else.
**Consequence:** `ExerciseHistory` (`lib/domain/exercise_history.dart`) is derived from the journal each time and stores nothing, so no schema change or backup field. The page reads the journal live, so editing or deleting from it updates it. Tests: `test/domain/exercise_history_test.dart` and `test/exercise_page_flow_test.dart` (which includes the smallest phone at the largest text).

## 45. The first fight explains its buttons, and the Journal shows notes and can be searched

**Decision:** Until an expedition has been won, the first fight of a run shows a one-line hint above the four battle buttons (Attack and Guard build focus, Power Strike spends 2, Potion heals). The Journal now shows the optional "How did it feel?" word and the note on each workout, and has a search box for exercise names, variants and notes; while searching, the overview panels step aside.
**Why:** The battle buttons were the one place a first-timer got no words, and the guide is a screen away from a fight. The feeling and note were saved and editable but never shown anywhere after saving, which made them feel pointless. Search is how a note becomes useful ("knee", "sunny").
**Trade-off:** The hint comes from state the game already has (`hero.victories`), so it needs no saved flag: it returns after a lost first expedition, which is when it is still needed. Notes are shown in full only on the edit screen; the Journal truncates at two lines. Feelings and notes still never change a reward.
**Consequence:** `FirstSteps.battleHint`, `WorkoutEntry.feel` and `WorkoutEntry.matches`. Tests: `test/battle_hint_flow_test.dart`, `test/journal_search_flow_test.dart`.

## 46. An eighth region after the Isles

**Decision:** The Ember Deeps opens at level 66: a warm, glowing underworld of forges and lava, with three new enemies (Cinder Sprite, Anvil Golem, Magma Slug), two bosses (Forgemaster Brun, Magmara the Slow Simmer), four camps and a fork of its own, a new lava-and-embers scene, and four pieces of gear sold for 4,600 to 5,200 coins. It uses the tactics already taught (flurries, bracing, mending, bosses that get fired up) and adds no new rules.
**Why:** Heroes cleared the Starlit Isles at level 50 with 49 more levels to go and nothing new to fight. Region 8 gives the last levels somewhere to go without inflating stats.
**Trade-off:** It is tuned to be about three points harder than the Isles for the scripted, no-gear player (48%, 56%, 54% at levels 66, 78 and 95), so the balance test's "toughest region is beatable most of the time" bar moved from 55% to 50%. Enemy attack is rounded to whole numbers, so the attack dial jumps in big steps; the HP dial did the fine tuning. Like every region it stays open for good, and a hero can drop back to an easier one.
**Consequence:** `Difficulty.maxTier` is 8, `Terrain.embers` and `Biome.embers` exist, and the saved game needs nothing new (a run remembers its region number, and the next number was always allowed). Tests: `test/domain/ember_deeps_test.dart`, and the balance table in `test/domain/balance_test.dart`.

## 47. The level cap moves to 120 for a fifth season

**Decision:** The level cap rises from 99 to 120 so that the story can continue. Season Five, "The Banked Fire" (levels 100 to 120), is written and delivered like Seasons Two to Four: its script is downloaded once, on demand, and everything is free. Nothing else about levels changes: the XP curve is the same formula, and stats still grow slowly past 99 (about +1 attack and +6 health between 99 and 120).
**Why:** The roadmap said a Season Five needed a reason to go on past the cap. The honest answer was to give the last levels somewhere to go, together with the eighth region ([decision 46](#46-an-eighth-region-after-the-isles)), rather than release eight chapters at once at level 99.
**Trade-off:** Level 120 takes about 34,000 more XP than level 99, which is months more play at the daily limit, and anyone who had already reached 99 has a progress bar again. That is the point, but it is worth saying: no one loses anything, and chapters still only ever open. Three-digit levels needed a small fix in the hall's heads-up display.
**Consequence:** `Progression.maxLevel` is 120. The hall's level label scales down to fit, tested at the smallest phone and largest text in `test/level_cap_layout_test.dart`. Season Five has two new speakers and four new backdrops in the app (new art always needs an app update, see [Content packs](CONTENT_PACKS.md)), and its script is in `docs/packs/season_5.json`.

## 48. The weekly goal follows the player's own usual week

**Decision:** The GDD's "rewards recognise consistency relative to personal baseline" is built as the weekly goal's default, not as a change to any reward. Until the player picks a goal, it is the middle number of their active days over the last four complete weeks (between 1 and 5), or the suggestion for their experience while there are fewer than three weeks of history. The player's own choice always wins, and the quest board says when the suggestion comes from their recent weeks.
**Why:** A single number for everyone is too high for someone who moves twice a week and too low for someone who moves five times, and a goal that is always out of reach reads as a verdict. Scaling XP or energy to the individual would have meant rewards that differ between people for the same workout, a quiet cap on the best performers, or a reason to sandbag one's own week. The pillars rule all of that out (see [Reward rules](REWARD_RULES.md#goals)), so the personalised thing is the goal, which costs nothing to miss.
**Trade-off:** The suggestion is only ever what the player already does, so it never asks for a bit more, and someone who wants to build up has to choose a higher number themselves. It also goes down after a quiet spell, which is kind but means the goal can slide without anyone choosing it; a chosen goal does not. Nothing is shown as a decline, and there is no comparison with anyone else.
**Consequence:** `PersonalBaseline` and `QuestBoard.goalTarget` (`lib/domain/quests.dart`) replace the direct use of `HeroProfile.weeklyGoalTarget` in the hall, the quest board and the reminders; `weeklyGoalTarget` stays as the experience-level fallback. Nothing is stored, so there is no schema change. Tests: `test/domain/baseline_test.dart` and `test/baseline_flow_test.dart`.

## 49. The newest content has earned looks, and the trophy shelf grows to two rows

**Decision:** Finishing Season Four and Season Five each earn a mantle (Table and Hearth), levels 50 and 66 earn the hair dyes Comet and Cinder, and three more trophies join the Journal shelf: The Long Table, Level 100 and The Banked Fire. The shelf now has two rows of six.
**Why:** [Decision 36](DECISIONS.md#36-earned-looks-sit-beside-paid-ones-and-trophies-are-for-the-long-haul) promised that every kind of look keeps an earned choice beside the paid ones, and the story, the level cap and the eighth region had all moved on since it was written.
**Trade-off:** The bunting still has ten slots and stays full. The shelf's open ledger moved down a shelf to keep the second row clear.
**Consequence:** All earned, none sold (`Cosmetics` in `lib/domain/cosmetics.dart`, drawn in `hub_scene.dart`). New cape and dye ids never reuse an old one. Tests are in `test/domain/patronage_test.dart`.

## 50. A calm minute sits beside the warm-up

**Decision:** The Train screen offers a second optional, reward-free practice beside the warm-up: "A Calm Minute With Chad", five slow breaths (in for 4, rest for 2, out for 6) with a circle that swells and settles, a cue for each breath, a pause button and a finish button. Like the warm-up it pays nothing, saves nothing, has no timer against the player and can be left at any moment.
**Why:** The roadmap asked for recovery-friendly mini-games beyond the practice duel, and the game's own line is that rest is training. Slow breathing is the smallest thing that fits: no equipment, no body talk, and nothing to get right.
**Trade-off:** The circle only sets a pace, so it never asks for a particular depth of breath, and the words say to go smaller or just breathe normally if dizzy. It is not medical advice and not a feature that measures anything. With Reduce Motion the circle changes size without animating, and the word on it still says what to do.
**Consequence:** `Calm` and `CalmPhase` (`lib/domain/calm.dart`), `CalmScreen` (`lib/features/workout/calm_screen.dart`), one shared "Warm Up or Wind Down" panel on the Train screen (so the exercise list does not move further down) and a guide entry. Tests: `test/domain/calm_test.dart` and `test/calm_flow_test.dart` (which includes the real animation at the smallest phone and largest text).

## 51. Workouts can be saved as a spreadsheet, and it is not a backup

**Decision:** Settings can save the workouts as a CSV file: one row a workout, oldest first, with units in the headings. It goes through the share sheet where the phone has one and to the clipboard otherwise. It holds only workouts, and the screen and the guide say it is for looking at and cannot be restored.
**Why:** People who lift or run want their numbers in a spreadsheet, or to send a coach the log, and the JSON summary is not something a spreadsheet opens. It keeps the game's promise that the data is the player's: nothing leaves the phone except where the player sends it.
**Trade-off:** It is a second export beside the full backup, so the wording keeps them apart: the backup restores, the spreadsheet does not. It is metric only, because a spreadsheet should not have to guess. The player's own notes could contain a formula, so any cell that starts like one gets a leading apostrophe.
**Consequence:** `WorkoutCsv` (`lib/data/workout_csv.dart`), `GameRepository.allWorkouts` and an optional `mimeType` on `BackupFiles.send`. Tests: `test/data/workout_csv_test.dart` and `test/workouts_csv_flow_test.dart`.

## 52. The hall floor gets a keepsake for each later season

**Decision:** Finishing Season Two, Three, Four and Five each sets a small keepsake on the hall floor by the left wall: a harbour lamp, a little chime, a laid table and a banked hearth. They are earned only by finishing the story, never sold, and never taken away.
**Why:** The pennants and trophies reward milestones and levels, but the finished stories had no mark of their own in the hall except a mantle and a trophy on a shelf you have to open. A keepsake is something you see every time you come back.
**Trade-off:** The floor has four places, one for each later season, so a sixth season would need a new place (the trophy shelf grew the same way). Chad's speech bubble covers them while he is talking.
**Consequence:** `Cosmetics.keepsakes` and `KeepsakeShape` (`lib/domain/cosmetics.dart`), drawn by `HallBackdrop` (`lib/game/hub_scene.dart`). Tests are in `test/domain/patronage_test.dart`.

## 53. Three fighting styles, and none of them is stronger

**Decision:** The Hero screen lets the player pick how their hero fights: Steady (the way the game has always played), Guardian (guarding builds 2 focus; Power Strike costs 3 and hits harder) or Striker (attacking builds 2 focus; guarding builds none; Power Strike hits a little lighter). It is free, saved with the hero (schema v13) and can be changed at any time.
**Why:** Character skills were on the backlog, and the only combat decision was when to guard and when to spend focus. A style gives a player who likes one way of fighting the chance to lean into it, without making anyone feel they chose wrong. It is not a stat choice, because workouts and levels deliberately do not shape stats ([decision on combat](DECISIONS.md)).
**Trade-off:** Balance has to hold for all three, so the numbers are tuned against a scripted player who knows each style, and a test fails if one drifts ahead: they sit within about two points of each other on average. Three is few enough to explain in a sentence each. A real player can still be better with one than a script is, which is fine.
**Consequence:** `FightingStyle` in `lib/domain/combat.dart`, `ExpeditionRun.style`, `HeroProfile.fightingStyle`, `GameRepository.setFightingStyle`, a panel on the Hero screen and a guide entry. Included in backups and the summary. Tests: `test/domain/styles_test.dart`, `test/fighting_style_flow_test.dart` and `test/data/migration_v13_test.dart`.

## 54. The level cap moves to 144 for a sixth season

**Decision:** The level cap rises again, from 120 to 144, so Season Six, "The Comet Road" (levels 123 to 144), has levels to open at. It is delivered like Seasons Two to Five, as a download, and is free. The chapters keep the Season Five spacing of three levels, which at the late curve is a month and a half or so of regular play each.
**Why:** The Starlit Isles and their Comet King had never appeared in the story, Bertram's list had an obvious open item, and the Season Five finale had left a newcomer at the door. Stats still grow slowly past 99, about +3 attack and +11 health between 99 and 144, so the extra levels are for the story and the trophy shelf, not for power.
**Trade-off:** It is a lot of extra levels, and a player who reaches 120 has a progress bar again. That is the intent, but it is the second time, so Season Seven should not simply move the cap again: it would need a reason that is not another level range (for example chapters that open on something other than level, or a different kind of ending).
**Consequence:** `Progression.maxLevel` is 144. Two new speakers (Juno, the Comet King) and two new backdrops (the Isles and the comet sky) are in the app, and the script is `docs/packs/season_6.json`. It also earns a mantle, a trophy and a keepsake (the Comet Mantle, The Comet Road trophy and the Comet Glass), all earned and none sold.
