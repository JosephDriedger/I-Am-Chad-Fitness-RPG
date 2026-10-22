# Roadmap

Status against the production milestones in the [GDD](I_Am_Chad_Fitness_RPG_GDD.pdf) (section 14). The GDD's week numbers were illustrative for a part-time solo developer, so they are not repeated as dates here.

Legend: **Done** means implemented and covered by automated tests. **Partial** means working but short of the exit criterion. **Not started**.

## Milestones

| # | Deliverable | Exit criterion | Status |
| --- | --- | --- | --- |
| 1 | Project skeleton, data models, wireframes | Launches on emulator; records persist locally | **Partial.** Skeleton, models and persistence done and tested; **not yet launched on an emulator or device** (the Android toolchain is not set up on the dev machine). No wireframes were produced. |
| 2 | Workout catalog and logging | Can log, edit, delete and review workouts | **Done.** 11 activities in 4 categories, timer, units, history. No exercise demonstrations yet. |
| 3 | Onboarding, quests, rewards | Personalised beginner goals and bounded XP work | **Done**, with tuning open. Reward rules are capped and versioned. Personal-baseline scaling is not implemented. |
| 4 | Character, guild, Chad dialogue | Core screens connected with placeholder art | **Done.** Placeholder avatar and icons. Chad tutorial is a welcome screen, not an interactive intro activity. |
| 5 | Combat and expeditions | One complete repeatable adventure loop | **Done.** Built with Flutter widgets rather than Flame. |
| 6 | Polish, accessibility, testing | Stable playable prototype on Android and iOS test devices | **Not started.** |

## Next up

Roughly in priority order.

1. **Run it on a real device or emulator.** Install Android command-line tools and licenses, run on a device, and fix whatever turns up (layout on small screens, keyboard behaviour, system back handling).
2. **Playtest the reward and combat numbers.** The scripted player wins about 90% of level-1 expeditions and 98% or more later, which is probably too easy. Gather human feedback before changing anything.
3. **Persist an in-progress expedition.** Today, killing the app mid-run loses the run (the 2 energy is already spent). Either save progress or refund energy on an interrupted run.
4. **Interactive Chad intro.** The "brief optional introductory activity" from the GDD (a one-minute guided stretch, say) and tutorial tooltips for first use.
5. **Exercise help content.** Short original form cues with easier alternatives per activity, and any demonstration media with documented licences.
6. **Accessibility pass.** Test with TalkBack and VoiceOver, large text, high contrast and reduced motion on real devices.
7. **Usability test with fitness beginners.** Check terminology ("effort minutes", "energy") and that no message reads as discouraging.

## Backlog

- Flame combat scenes (animations, effects) driven by the existing `BattleEngine`.
- Personal-baseline reward scaling, so consistency is recognised relative to the individual.
- Per-day limit on minimum-effort entries (see [Reward rules](REWARD_RULES.md), known gaps).
- More encounters, enemies, events and equipment; character skills and stat choices.
- Reminder notifications that are opt-in, kind and never guilt-based.
- Recovery-friendly mini-games beyond the practice duel.
- Weightlifting progression tracking and personal bests.
- Release preparation: real application id, icons, store listings, privacy disclosures, age rating.
- Original art and audio pipeline; asset licence register.

## Later (post-MVP, per the GDD)

- Apple HealthKit and Android Health Connect, permission-based.
- Optional cloud accounts and sync (FastAPI and PostgreSQL), after designing conflict resolution.
- Camera-based rep recognition, GPS routes and wearables.
- Social and guild features.
- Larger narrative content and procedural dungeon maps.

## Known issues and limitations

- Never run on a device or emulator; verified through analysis, unit tests, repository tests and widget flow tests only.
- Expedition progress is not saved if the app is closed mid-run.
- Placeholder visuals throughout: icons stand in for the hero, enemies and Chad.
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
| Original art pipeline and licensing budget | Undecided; placeholders for now |
| Final title and trademark clearance | Working title only |
