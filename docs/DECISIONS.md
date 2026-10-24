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
**Trade-off:** Another place to keep in step with the rules, which the generated numbers and tests are there to make cheap. The warm-up is not offered automatically after onboarding, to avoid adding a step to the first launch.
**Consequence:** New terms and rules belong in `lib/domain/guide.dart` (see [Content guidelines](CONTENT_GUIDELINES.md)).

## 38. Reminders are opt-in, rare, and run out by themselves

**Decision:** The game can send gentle reminders, but only if the player turns them on in Settings. They choose the weekdays (Monday, Wednesday and Friday to begin with) and an hour between 8 AM and 9 PM. At most one a day; none on a day the player has already moved; none for the rest of a week whose goal is met; and never any wording about streaks, missed days or what has not been done. The game plans only a fortnight ahead each time it opens, so if someone stops opening it, the reminders stop on their own. Permission is asked only at the moment the switch is turned on, and a "no" is answered kindly and leaves it off.
**Why:** Notifications are the usual place where a friendly game turns into a nag, and the pillars rule that out (see [decision 28](#28-forgiving-streaks) and the [content guidelines](CONTENT_GUIDELINES.md)). Making the limits part of the rules, with tests, keeps them from loosening later. The fortnight horizon means the worst case for a player who drifts away is a few kind messages and then silence, and nothing escalates or "wins them back".
**Trade-off:** A fixed schedule is less clever than one that learns when someone usually moves, and a planned reminder can still arrive after they have moved if they log it from another day's plan; the game replans on every launch and every logged workout, which covers the common cases. Reminders cannot be sent by a phone with notifications switched off, and that is respected.
**Consequence:** The rules, wording and planner are pure Dart in `lib/domain/reminders.dart`. Delivery is behind `ReminderGateway` (`lib/app/reminders.dart`); the default sends nothing, and Settings does not show the switch where nothing can be sent, so the game never offers what it cannot do. The real notification plugin is not wired in yet (see [Roadmap](ROADMAP.md)). Schema v12 stores the three choices, included in Delete Everything. Anything that adds more frequent, unprompted or escalating messages needs a new decision first.
