# Game scenes

The home screen and the battles are real game scenes built with [Flame](https://flame-engine.org/), not widget screens. This document explains how they work, how to preview them, and how to extend them. Rules still live in `lib/domain`; scenes only draw and animate.

## The loop as a player sees it

```
Exercise in real life → log it (Train) → XP + adventure energy
      → the gate in the guild hall unlocks → set out on an expedition
      → battles, a camp event, a boss, a chest → loot, coins, XP → hero grows
```

Real-world exercise is the only source of adventure energy. Battles themselves are play, not exercise. See [Reward rules](REWARD_RULES.md).

## Structure

```
lib/game/
  look.dart            HeroLook (hair, outfit colour, skin tone, equipped items), ActorState
  core.dart            GameScene base, tweens, floating text, particles, ActorComponent, WorldBar
  art/painters.dart    Every character and prop, drawn with canvas shapes
  hub_scene.dart       The guild hall
  battle_scene.dart    Battle stage: backdrops, choreography, chest finale
lib/app/feedback.dart  Sound and haptics, gated by settings
lib/features/home/     HubScreen (scene + HUD + menu), GamePage wrapper
lib/features/adventure/expedition_screen.dart   Drives BattleScene from BattleEngine
lib/dev/               Developer-only previews (see below)
```

### Base scene (`GameScene`)

- **Fixed design resolution.** The hall is 360 × 640, the battle stage 360 × 340. The camera zooms to fit the screen and backdrops draw well outside the design area, so there are no letterbox bars on any phone.
- **Tweens.** `tween(seconds, onTick)` returns a `Future`, so choreography reads top to bottom with `await`.
- **Reduced motion.** When `reducedMotion` is on, every tween completes on the next frame, particles and camera shake are skipped, and floating text stays put. Game state is identical either way.
- **Feedback hooks.** Scenes call `sfx(Sfx.hit)` and `haptic(Haptic.medium)`; the host decides what, if anything, happens.

### Characters are drawn, not loaded

All art is vector shapes drawn each frame, so the game ships with **no borrowed or licensed assets** and everything can animate (idle bob, blinking, walk cycle, weapon swing, guard shield, hit flash, fade).

| Piece | Notes |
| --- | --- |
| Hero | 6 hair styles (including a hood), 6 outfit colours, 6 skin tones. Equipped items are drawn on the body: weapons, a cap, a sweatband, a vest, a guild emblem and trinkets |
| Chad | Muscular guildmaster, flexing idle, headband, a "C" on the shirt |
| Enemies | Snooze Slime, Fog Imp, Rusty Gear Golem, Cobweb Wisp, Pebble Gremlin, Mist Wisp |
| Bosses | Grumbling Treant, Brad (Chad's old rival, a recoloured muscle character) |
| Props | Campfire, merchant cart, treasure chest, equipment icons |

`HeroAvatar` in the Flutter UI uses the same painter, so the HUD portrait always matches the character.

## Guild hall (`HubScene`)

The hall is the app's home. The HUD and menu are Flutter widgets (so they work with screen readers and large text) layered over the scene.

| Object | Opens | Reacts to |
| --- | --- | --- |
| Quest board | Quests (with a look back at last week) | An alert marker bounces while a suggestion is still undone |
| Bookshelf | Journal (history) | Nothing yet. Its top shelf holds the earned trophies, if any |
| Gate | Adventure | Glows teal when you have the 2 energy an expedition costs; shows a padlock otherwise |
| Training dummy | Train (log a workout, or take Chad's one-minute warm-up) | Wobbles when the hero hits it |
| Armour stand | Hero | Shows your outfit and equipped gear; sparkles once you own loot |
| Chad | Tap for another line | His speech bubble follows your day: first visit, after a workout, a rest day, idle |

- **Tap an object** and the hero walks to it, does a short interaction (hits the dummy, hops at the board, steps into the gate), then the screen opens. Tap the floor to just walk around.
- **Time of day.** The windows show daylight, dusk or night from the device clock, with a moon, stars and warmer torch glow after dark.
- **First-steps hint.** Until the first workout is logged, `HubState.highlight` makes the training dummy glow softly. It is a hint, not a gate: everything stays tappable, and it is gone for good after the first workout.
- **Decorations.** The hall starts bare. **Pennants** hang on bunting across the top of the wall as milestones are reached (first workout, first expedition, levels, streaks, the finished season); each has a fixed slot, filling outward from the banner, so earlier ones never move. They are earned, never sold, never removed. The top shelf of the Journal bookshelf holds up to six **trophies** for the bigger milestones (finishing Season Two and Three, levels 40 and 50, 25 expeditions won, a 90-day streak), drawn in place of that shelf's books once the first is earned (`HubState.trophies`). The optional Patron Pack adds string lights on the gate and quest board, a patron rosette on the banner and a potted lantern tree. All of it is passed in as plain data (`HubState.pennants`, `HubState.patronDecor`) and does nothing but draw.
- **Coming back from a screen** the hall plays what you earned: floating "+40 XP", "+2 energy" and coins with sparkles, and a confetti burst with "LEVEL UP!" when your level rose.

The same five destinations are also buttons in the bottom menu. They are the accessible route; the canvas is a bonus layer on top.

## Battle scene (`BattleScene`)

`BattleEngine` decides what happens and returns a list of structured `BattleEvent`s (`PlayerAttacked`, `EnemyAttacked`, `EnemyDefeated`, ...). `BattleScene.play(events, ...)` animates them in order and then snaps the bars to the engine's final numbers, so animation can never change an outcome.

| Event | What you see |
| --- | --- |
| Attack | Hero lunges, slash arc, hit sparks, white flash and knock-back, damage number, small shake |
| Power Strike | Charge-up with stars, a bigger lunge, golden slash and a harder shake |
| Guard | A shield swings up and stays until the enemy has attacked |
| Potion | Green sparkles, "+HP" number, a little hop |
| Enemy strike | Lunge; a guarded hit shows blue sparks and "Blocked"; a heavy blow shakes the screen harder |
| Heavy blow telegraph | Before it lands: a red pulsing aura, a lean back, and an orange alert badge over the enemy's head |
| Enemy defeated | Flash, fade out with a puff and stars, then a victory hop |
| Knocked out | The hero keels over; the result screen keeps all rewards earned so far |

**Biomes.** Meadow, forest dusk, boss arena (pillars and rising embers) and a night camp for events, chosen by position in the expedition. A path bar above the stage shows progress through the four steps.

**Events and finale.** Between battles the stage becomes a night camp with a campfire, merchant cart or treasure chest. On victory a chest pops in, opens with a glow and confetti, and the loot item rises out of it with its name.

The HP bars, names and focus pips are drawn in screen space, so they sit at the top edge on any phone.

## Sound and haptics

**Sound effects.** Fourteen short effects live in `assets/audio/`, **synthesized by `tool/gen_sfx.mjs`** so they are original and carry no licence obligations (`node tool/gen_sfx.mjs` regenerates them). Three belong to everyday moments rather than battle: `saved` (a two-note chime when a workout is saved), `fanfare` (a personal best or a streak reward) and `rep` (one rep counted by the camera).

**Haptics.** `Haptic` has five strengths: `light`, `medium`, `heavy`, a `select` tick for choosing a chip or goal, and `success`, two pulses (firm then soft) for "got it". Battles use the first three as before. Saving a workout gives `success`, the honesty question a `light` tap, and turning Vibration on in Settings lets you feel one.

**Music.** Two loops, **synthesized by `tool/gen_music.mjs`** (`node tool/gen_music.mjs`): `hall_loop.wav`, a calm 76 BPM tune (about 25 s), and `battle_loop.wav`, a livelier 138 BPM tune (about 28 s). Every note wraps around the end of the file, so the loop has no click, and a test checks the seam. `lib/app/music.dart` plays them:

- **Off by default** (`Music` in Settings, schema v10), because many people exercise with their own music or a podcast. It plays quietly (volume 0.3) with audio focus set to *mix with others*, so it never pauses someone else's audio.
- The hall plays the hall tune. A battle or practice duel asks for the battle tune while it is open (`WantsMusic`) and hands the hall tune back when it closes.
- Music stops when the app goes to the background and returns with it. A permission prompt or the notification shade (`inactive`) does not stop it.

**Settings are read live.** The hall and battle scenes used to keep the sound and vibration switches they were built with, so turning Sound on in Settings did nothing in the hall until the app was restarted. Scenes now ask `feedbackProvider` each time, and a test covers it.

`GameFeedback` plays effects with `flame_audio` and triggers vibration, each gated by the **Sound Effects** and **Vibration** switches. Failures are swallowed. Tests swap in recorders through `sfxPlayerProvider`, `hapticPlayerProvider` and `musicBackendProvider`.

**Not yet verified:** how any of this sounds and feels. The sounds and music are checked for validity, clipping and a clean loop point, and the wiring is tested with recorders, but nobody has heard it on a speaker or felt it on a motor. The mix-with-others audio setting is untested on real devices, on iOS especially.
## Accessibility

- Menu buttons, battle actions and the HUD stats have semantic labels; the battle log is a live region; the expedition path has a progress label.
- Enemy intent is shown with an icon and text as well as colour.
- **Reduce motion** (Settings) and the OS setting both switch scenes to instant transitions with no shake or particles.
- Touch targets are at least 48 px. Text size follows the system setting.

## Exercise demonstrations

Logging a workout opens with an animated "How to Do It" card (`lib/game/demo/exercise_demo.dart`, shown by `ExerciseDemoCard`). It is drawn in code like the rest of the art, in the player's own look, and it follows the version chosen below it, so picking Wall, Incline or Knee push-ups changes the demo.

- **A real skeleton.** Limb lengths are fixed and hands and feet stay planted using two-bone IK, so a push-up pivots on the toes and a wall push-up keeps its hands on the wall. Walking and running use a gait cycle whose hip height is solved each frame so the lowest foot is always on the ground.
- **Props.** Wall, bench, chair, mat, dumbbells and barbell where they belong.
- **Cues that follow the motion.** Each demo has three or so cues ("Hands under your shoulders", "Lower slowly", "Press back up, breathe out as you push") that change as the figure moves, plus a note pointing to easier versions.
- **Pause, or step through.** A play/pause button; with Reduce Motion on, the demo shows still key poses with a "Next Pose" button instead of looping.
- **Covers everything.** All 79 exercises and every variant listed in the catalog. A test fails if an exercise or variant is added without a demo.
- **A keyframe rig for the big catalog.** The first eleven are hand-built poses. The rest use `_rig` (`demo_rig.dart`): each keyframe gives a torso position and lean plus where the hands and feet should be, the targets are blended, and the same IK solves the limbs. Poses live in `demo_standing.dart`, `demo_floor.dart`, `demo_weights.dart` and `demo_gear.dart`, props in `demo_props.dart`, and the entry for each id (title, three cues, props) in `demo_catalog.dart`. Seen from the side, a few moves (jumping jacks, side lunges, lateral raises, side bends, butterfly stretch) are drawn face-on and say so in their note.
- **Look at them.** `test/tool/demo_sheet_test.dart` draws every demo at four moments of its loop into a contact sheet PNG, which is how the whole catalog was checked by eye. See [Exercise catalog](EXERCISE_CATALOG.md#adding-an-exercise).

`test/game/exercise_demo_test.dart` checks every demo: limb lengths never change, nothing leaves the frame or sinks below the floor, no joint jumps between frames (including across the loop point), and each exercise actually moves.

## Previewing in a browser

Scenes can be viewed without a phone. The web platform is enabled for development only (the shipped targets remain Android and iOS) and the database falls back to `sqlite3.wasm` plus `web/drift_worker.js`.

```bash
flutter run -d chrome --dart-define=PREVIEW=hub
```

| `PREVIEW=` | Shows |
| --- | --- |
| `cast` | Every character on one sheet |
| `hub` | The guild hall with a seeded hero |
| `patron` | The hall with the Patron Pack and several pennants earned: bunting, string lights on the gate and quest board, a patron rosette on the banner and a potted lantern tree |
| `wardrobe` | Every cape and hair dye on one sheet |
| `duel` / `expedition` | A practice duel / a full expedition |
| `boss`, `event`, `chest` | Still frames of those battle-scene states |
| `demos` | Every exercise demonstration at its key poses |

Preview modes skip animation and sound. A browser tab that is hidden or unfocused also throttles animation frames heavily, so check choreography on a device or in the widget tests, not in a background tab.

## Extending

- **New enemy:** add the template in `expedition.dart`, a painter in `painters.dart`, and a `_enemyArt` entry (scale and height) in `battle_scene.dart`. Add it to the cast sheet in `lib/dev/cast_scene.dart`.
- **New hair style or outfit:** extend `HeroLook` and `_paintHead`.
- **New hall object:** add a `_Hotspot` in `HubScene.onLoad` with a painter, a stand point and a `HubTarget`.
- **New effect:** add a `Burst` factory in `core.dart` or a component, and call it from the scene's choreography.
- Never put rules in a scene. If it affects the outcome, it belongs in `lib/domain` and must be tested there.
