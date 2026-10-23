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
**Trade-off:** Any streak can still feel like pressure to some people, so the wording is kept calm, the rest allowance is generous, and the reward sizes are small next to a real day's exercise. If it ever tests badly with beginners, the first lever is a larger rest allowance, and the second is removing the HUD flame. Rewards can be back-dated, which is accepted for a single-player game.
