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

The dialogue test (`test/domain/quests_test.dart`) lints Chad's lines for a few shaming words. It is a safety net, not a substitute for judgement.

## Always include

- Easier options. Every exercise has a gentle starting point, and easier variants earn the same as harder ones.
- "Stop if anything hurts" wherever exercise is introduced or logged.
- A clear separation between game feedback and professional health advice. The game cannot verify workouts and must not imply it can.
- Rest as a valid, valued choice. Rest days never reduce progress.

## Enemies

Enemies are whimsical obstacles such as a sleepy slime or a gear golem. They must not personify the player's struggles with their body, weight, laziness or failure.

## Rewards and mechanics

- No streaks that reset, no daily login rewards, no countdowns.
- Rewards are capped per day so exercise is never pushed beyond what is healthy for the reward.
- Rewards never depend on weight lifted, pace, body measurements or "perceived effort".
- Loot is earned, never bought. No gacha or loot boxes, no paid XP or energy.
- Any number the player sees (XP, energy, damage) should be explainable.

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
- Any future health integration (HealthKit, Health Connect) requires an explicit permission screen explaining what data is read and why.

## Art, audio and licensing

- Use original assets or assets with documented commercial licences. Today everything is original: characters, props and backdrops are drawn in code (`lib/game/art`), and the sound effects are synthesized by `tool/gen_sfx.mjs`. If any third-party asset is added, record its source and licence in `docs/ASSET_LICENSES.md` first.
- Chad is an original character. Do not reproduce recognisable meme photography or third-party characters.
- Offer a range of appearances (hair styles, outfit colours and six skin tones) and never tie a body type or skin tone to any in-game value or role.
- Audio should reward effort without overwhelming the workout. It must be mutable and never required.
- Exercise demonstrations are original animations drawn in code (see [Game scenes](GAME_SCENES.md)). Each has simple form cues and points to easier versions, and cues must stay conservative: no "push through the pain", no promised results. Any new demo needs a professional's review before release where possible.

## Title

"I Am Chad" is a working title. Trademark clearance is pending (GDD section 16). Avoid building the name into assets that are hard to change.
