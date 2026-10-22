# Roadmap

Status against the production milestones in the [GDD](I_Am_Chad_Fitness_RPG_GDD.pdf) (section 14). The GDD's week numbers were illustrative for a part-time solo developer, so they are not repeated as dates here.

Legend: **Done** means implemented and covered by automated tests. **Partial** means working but short of the exit criterion. **Not started**.

## Milestones

| # | Deliverable | Exit criterion | Status |
| --- | --- | --- | --- |
| 1 | Project skeleton, data models, wireframes | Launches on emulator; records persist locally | **Partial.** Skeleton, models, persistence and a tested v1 to v2 migration are done. The scenes were reviewed in a browser, but the app has **not been launched on an Android or iOS emulator or device** (the Android toolchain is not set up on the dev machine). No wireframes were produced |
| 2 | Workout catalog and logging | Can log, edit, delete and review workouts | **Done.** 11 activities in 4 categories, timer, units, history. No exercise demonstrations yet |
| 3 | Onboarding, quests, rewards | Personalised beginner goals and bounded XP work | **Done**, with tuning open. Reward rules are capped and versioned. Personal-baseline scaling is not implemented |
| 4 | Character, guild, Chad dialogue | Core screens connected with placeholder art | **Done, beyond placeholder.** The guild hall is an animated Flame scene; the hero (hair, outfit, skin tone, equipped gear) and Chad are drawn in code. The Chad tutorial is a welcome screen plus contextual lines, not an interactive intro activity |
| 5 | Combat and expeditions | One complete repeatable adventure loop | **Done.** Animated Flame battle scenes with effects, a camp event, a boss and a chest finale; synthesized sound and haptics |
| 6 | Polish, accessibility, testing | Stable playable prototype on Android and iOS test devices | **Not started.** Needs device testing |

## Next up

Roughly in priority order.

1. **Run it on a real device or emulator.** Install the Android command-line tools and licenses, run on a phone, and fix whatever turns up (frame rate, safe areas, keyboard behaviour, system back handling, audio latency). This is the biggest unknown.
2. **Playtest the feel and the numbers.** Combat is probably too easy (a scripted player wins about 90% of level-1 expeditions and 98% or more later), and the animation timings were written blind to a real device. Get human feedback before changing anything.
3. **Persist an in-progress expedition.** Today, closing the app mid-run loses the run (the 2 energy is already spent). Either save progress or refund energy on an interrupted run.
4. **More to look at.** More enemies, biomes and hall decoration that reacts to progress (trophies, banners for milestones). A hand-made art pass can replace procedural painters one at a time.
5. **Music.** A calm loop for the hall and a livelier one for battles, both mutable. Sound effects already exist.
6. **Interactive Chad intro.** The "brief optional introductory activity" from the GDD (a one-minute guided stretch, say) and first-use tooltips.
7. **Exercise help content.** Short original form cues with easier alternatives per activity, and any demonstration media with documented licences.
8. **Accessibility pass.** Test with TalkBack and VoiceOver, large text, high contrast and reduced motion on real devices.
9. **Usability test with fitness beginners.** Check terminology ("effort minutes", "energy") and that no message reads as discouraging.

## Backlog

- Personal-baseline reward scaling, so consistency is recognised relative to the individual.
- Per-day limit on minimum-effort entries (see [Reward rules](REWARD_RULES.md), known gaps).
- Character skills and stat choices; more equipment.
- Reminder notifications that are opt-in, kind and never guilt-based.
- Recovery-friendly mini-games beyond the practice duel.
- Weightlifting progression tracking and personal bests.
- Release preparation: real application id, icons, store listings, privacy disclosures, age rating.
- Asset licence register if any third-party asset is ever added.

## Later (post-MVP, per the GDD)

- Apple HealthKit and Android Health Connect, permission-based.
- Optional cloud accounts and sync (FastAPI and PostgreSQL), after designing conflict resolution.
- Camera-based rep recognition, GPS routes and wearables.
- Social and guild features.
- Larger narrative content and procedural dungeon maps.

## Known issues and limitations

- Never run on an Android or iOS device. Verified through analysis, unit tests, painter smoke tests, repository and migration tests, widget flow tests (which play a full expedition through the Flame scene), and still frames in a desktop browser.
- Animation **timing and feel** (lunges, shake, particles, sounds) are untested by eye or ear. The browser tab used for review throttles animation heavily, so only static frames were inspected.
- Expedition progress is not saved if the app is closed mid-run.
- Frame rate on low-end phones is unmeasured. Scenes draw everything with canvas calls each frame, which should be fine at this scale but has not been profiled.
- The weekly goal counts days with any logged movement and cannot yet be customised.
- The Android and iOS application id (`com.iamchad.i_am_chad`) is a placeholder.

## Open design decisions

Carried over from GDD section 17, with the current stance:

| Question | Current stance |
| --- | --- |
| Exact reward formula and daily caps | Proposal in [Reward rules](REWARD_RULES.md); needs fairness testing across abilities |
| Combat class and skill design; do workouts influence specific stats | Single class, one skill; workouts do not influence stats |
| Age rating and minors | Undecided; onboarding collects no age |
| Weightlifting in early release | Included as basic logging (sets, reps, load); no progression tracking |
| Original art pipeline and licensing budget | Procedural art in code for now; a hand-made pass is a later decision |
| Final title and trademark clearance | Working title only |
