# Roadmap

Status against the production milestones in the [GDD](I_Am_Chad_Fitness_RPG_GDD.pdf) (section 14). The GDD's week numbers were illustrative for a part-time solo developer, so they are not repeated as dates here.

Legend: **Done** means implemented and covered by automated tests. **Partial** means working but short of the exit criterion. **Not started**.

## Milestones

| # | Deliverable | Exit criterion | Status |
| --- | --- | --- | --- |
| 1 | Project skeleton, data models, wireframes | Launches on emulator; records persist locally | **Done**, apart from wireframes (none were produced). Launched and played end to end on an Android emulator (Pixel 10 Pro, Android 17): onboarding, logging, rewards, expeditions and loot, with the save surviving an emulator restart |
| 2 | Workout catalog and logging | Can log, edit, delete and review workouts | **Done.** 79 exercises in 6 categories (searchable, with equipment tags and an at-home filter), timer, units, history, an animated demonstration with form cues for every exercise, and a gentle [honesty check](REWARD_RULES.md#honesty-check) on implausible entries |
| 3 | Onboarding, quests, rewards | Personalised beginner goals and bounded XP work | **Done**, with tuning open. Reward rules are capped and versioned. Personal-baseline scaling is not implemented |
| 4 | Character, guild, Chad dialogue | Core screens connected with placeholder art | **Done, beyond placeholder.** The guild hall is an animated Flame scene; the hero (hair, outfit, skin tone, equipped gear) and Chad are drawn in code. The Chad tutorial is a welcome screen plus contextual lines, not an interactive intro activity |
| 5 | Combat and expeditions | One complete repeatable adventure loop | **Done.** Animated Flame battle scenes with effects, a camp event, a boss and a chest finale; synthesized sound and haptics |
| 6 | Polish, accessibility, testing | Stable playable prototype on Android and iOS test devices | **Not started.** Needs device testing |

## Next up

Roughly in priority order.

0. **Switch on the store.** The Patron's Hall, receipts, restore and cosmetics are built and tested against a pretend store, but nothing can be bought for real until the application id is replaced, the four products are created in Google Play Console and App Store Connect, and a build is tested with license testers (Play) and a sandbox account (Apple). Steps are in [Monetization](MONETIZATION.md#setting-it-up-in-the-stores). Real checkout has never been run, on any device.

1. **Run it on a physical phone, and on iOS.** The Android emulator pass found and fixed real problems (portrait framing, reward popups, overlapping text). A physical device will show frame rate, audio latency and haptics, which an emulator can't. iOS has not been built at all.
2. **Playtest the feel and the numbers.** Combat is probably too easy (a scripted player wins about 90% of level-1 expeditions and 98% or more later), and the animation timings were written blind to a real device. Get human feedback before changing anything.
3. **First-use guidance in the hall.** Built: until the first workout is logged, the training dummy glows softly (steady if motion is reduced) and Chad's welcome line is shown. It never blocks anything and disappears for good after the first workout. Still open: first-use tooltips on the Train and log screens, and the interactive intro (item 8).
4. **Try camera rep counting on real people.** The first version is built (push-ups and squats; see below) and runs on an emulator, but it has never counted a real rep. It needs testing on physical phones with different body types, clothing, light and angles, then the thresholds in `rep_counter.dart` tuned, an iOS build, and a decision on sit-ups and planks.
5. **More story.** Seasons One to Three are written and playable (Season Three is [The Weather Chime](STORY.md), set in the mountains and opening at level 45). Season Four, hand-made portraits and scene art would lift it a lot, and so would a read-aloud or audio option. Watch whether people read the chapters or skip them, and whether the choices are noticed. Stories are always free.
6. **More to look at.** Done: six regions with 21 regular enemies, 12 bosses, new enemy tactics and 28 pieces of gear (see [Combat and expeditions](COMBAT_AND_EXPEDITIONS.md)). Trophies on the Journal shelf are built (six, for the long-haul milestones). Still open: more hall decoration, and what to fight past level 36 once the Dunes are cleared. The first step is done: ten pennants on the hall's bunting appear as milestones are earned (see [Monetization](MONETIZATION.md#free-looks-sit-beside-the-paid-ones)). More earned decoration, such as trophies on the shelf, would fit. A hand-made art pass can replace procedural painters one at a time.
7. **Music.** Built: a calm loop for the hall and a livelier one for battles, synthesized in code, off by default, quiet, and mixed under other apps' audio (see [Game scenes](GAME_SCENES.md#sound-and-haptics)). Still open: hearing it on a real phone, and deciding whether synthesized tunes are good enough or a composer is wanted.
8. **Interactive Chad intro.** Built: the "brief optional introductory activity" from the GDD, as a one-minute guided warm-up with Chad (four standing moves with animated demonstrations, a countdown, pause and skip, no rewards, nothing saved), offered at the top of the Train screen. Still open: offering it automatically after onboarding, and first-use tooltips.
9. **Review the exercise demonstrations with a qualified professional.** The animated demos and cues are original and conservative, but they have not been reviewed by a trainer or physio, and the GDD asks for that where possible. Photo or video demos, if ever added, need documented licences.
10. **Accessibility pass.** Large text and small screens are now covered by automated layout tests (see [Development](DEVELOPMENT.md#random-play-tests)). Still open: TalkBack and VoiceOver, high contrast and reduced motion on real devices.
11. **Usability test with fitness beginners.** Check terminology ("effort minutes", "energy") and that no message reads as discouraging. A plain-words guide to every term, "How the Game Works", is now in Settings (see [Content guidelines](CONTENT_GUIDELINES.md)), so the test can also ask whether it answers their questions.

### Camera rep checking

**Built so far:** an optional "Count My Reps With the Camera" button on the push-up and squat log screens. It opens an illustrated set-up guide (the player is assumed to have a phone stand or tripod), asks for the camera, counts reps from on-device pose detection with a live skeleton overlay, a depth gauge and a set-up check, supports several sets, and fills the sets and reps into the log. Beginners get the most forgiving range of motion. Entries are marked "Camera Counted" in the journal (schema v4) and skip the honesty check; rewards are identical to typed entries. See [Decision 26](DECISIONS.md).

**Not done:** real-world testing, tuning, iOS verification, other exercises, and any form advice beyond generic cues.

The original thinking, still the guide for what comes next: use the phone camera as the eyes, confirm reps, back up the honesty check with something real. What it takes, and the cautions:

- **How:** on-device pose estimation (for example ML Kit pose detection, or MediaPipe via a plugin) gives body landmarks per frame; a small per-exercise state machine (elbow angle for push-ups, hip and knee angle for squats) counts reps. The demo figure already encodes each exercise's joint motion, so the same description can drive the counter.
- **Privacy:** frames must be processed live on the device and never saved or sent anywhere, which keeps the "no account, no network" promise. The permission prompt should say so plainly.
- **Optional, never required:** many people exercise somewhere without a spare place to prop a phone, or are not comfortable on camera. Manual logging must stay equal in rewards.
- **Count, don't grade:** counting reps is feasible; judging "proper form" reliably from one phone camera is not, and a wrong correction could cause harm or discourage. Start with counting and at most generic cues ("go a little lower"), and get professional input before saying anything stronger.
- **Scope:** only the bodyweight exercises with a clear side-on motion (push-ups, squats, sit-ups, plank hold time) are good candidates. Walking, running and weights are out.
- **Testing:** it cannot be properly verified on an emulator. It needs real phones, varied lighting, body types and camera angles, and a fallback when tracking is lost.

## Backlog

- Personal-baseline reward scaling, so consistency is recognised relative to the individual.
- Per-day limit on minimum-effort entries (see [Reward rules](REWARD_RULES.md), known gaps).
- Character skills and stat choices; more equipment.
- Reminder notifications that are opt-in, kind and never guilt-based.
- Recovery-friendly mini-games beyond the practice duel.
- Weightlifting progression beyond personal bests (which are built: see [Reward rules](REWARD_RULES.md#personal-bests)), such as charts over time.
- Release preparation: real application id, icons, store listings, privacy policy and disclosures (store purchases **and** the ad SDK, per [Monetization](MONETIZATION.md#privacy-and-the-players-data)), a real AdMob account with the test ids replaced and its blocking controls set (General audiences only, every sensitive category blocked, weight-loss ads included), and the stores' target audience and age rating set to teens and adults (13+).
- More cosmetics, free and earned first. Stories are never sold (see [Monetization](MONETIZATION.md#changing-this-later)). Ideas for Premium extras that are not gameplay.
- Asset licence register if any third-party asset is ever added.

## Later (post-MVP, per the GDD)

- Apple HealthKit and Android Health Connect, permission-based.
- Optional cloud accounts and sync (FastAPI and PostgreSQL), after designing conflict resolution.
- GPS routes and wearables.
- Social and guild features.
- Larger narrative content and procedural dungeon maps.

## Known issues and limitations

- Verified on an Android emulator and through analysis, unit tests, painter and demo invariant tests, repository and migration tests, and widget flow tests that play a full expedition. **Not yet run on a physical phone or on iOS.**
- Animation timing and feel were checked in screenshots on the emulator, not by hand on a phone, and **sound, music and vibration have not been heard or felt** (an emulator has no speaker or motor to judge). The music and the new sounds were synthesized and checked by numbers only.
- Camera rep counting has been run only on an emulator (preview, overlay, permission and set-up screens), and through unit tests with synthetic poses. **It has not counted a real person's reps yet**, so the thresholds and the ML Kit coordinate handling (especially the front-camera mirror and iOS) are unverified.
- An expedition is saved at the start of each step, so closing the app mid-fight replays that fight on resume (nothing is lost).
- Frame rate on low-end phones is unmeasured. Scenes draw everything with canvas calls each frame, which should be fine at this scale but has not been profiled.
- The weekly goal counts days with any logged movement. The player can now pick 1 to 7 days on the quest board; the default is still the suggestion for their experience.
- The Android and iOS application id (`com.iamchad.i_am_chad`) is a placeholder, and the store products do not exist yet, so **a real purchase has never been made**. The checkout code (`InAppPurchaseGateway`) is a thin layer over the `in_app_purchase` plugin and is untested against Google Play or StoreKit; everything around it (receipts, restore, confirm-after-save, cosmetics) is tested with a pretend store. On a device without the store set up, the Patron's Hall says the store cannot be reached and offers nothing to buy.

## Open design decisions

Carried over from GDD section 17, with the current stance:

| Question | Current stance |
| --- | --- |
| Exact reward formula and daily caps | Proposal in [Reward rules](REWARD_RULES.md); needs fairness testing across abilities |
| Combat class and skill design; do workouts influence specific stats | Single class, one skill; workouts do not influence stats |
| Age rating and minors | Decided: aimed at teens and adults (13 and over), not at younger children. Set the stores' target audience and age rating to match (see [Monetization](MONETIZATION.md#children-and-families)). Ads are G-rated and non-personalized, with no child signal. Onboarding collects no age |
| Weightlifting in early release | Included as basic logging (sets, reps, load); no progression tracking |
| Original art pipeline and licensing budget | Procedural art in code for now; a hand-made pass is a later decision |
| Final title and trademark clearance | Working title only |
